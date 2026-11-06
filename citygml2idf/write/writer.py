"""
write/writer.py — one EnergyPlus IDF per building, from the middle layer (eppy + the IDD in
templates/Energy+.idd).

build_idf writes, in this order: the run settings and outputs (new_empty_idf), materials,
constructions, zones + surfaces, infiltration, glazing, windows. It writes what the Model gives
and decides nothing; running EnergyPlus is a separate step.
"""

from __future__ import annotations

import os
from io import StringIO

from eppy.modeleditor import IDF

from ..semantics.surface_types import sun_wind_exposure

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG = os.path.dirname(_HERE)
_TEMPLATES = os.path.join(_PKG, "templates")
IDD_PATH = os.path.join(_TEMPLATES, "Energy+.idd")
EPLUS_VERSION = "26.2"   # must match templates/Energy+.idd and the EnergyPlus that runs the IDF


def ensure_idd(idd_path=IDD_PATH):
    """Point eppy at the IDD once (eppy keeps one IDD for the whole Python run)."""
    if IDF.getiddname() is None:
        IDF.setiddname(idd_path)


def new_empty_idf():
    """Create base IDF settings for a weather-file free-floating run."""
    idf = IDF(StringIO(""))
    idf.newidfobject("VERSION", Version_Identifier=EPLUS_VERSION)
    idf.newidfobject("TIMESTEP", Number_of_Timesteps_per_Hour=4)
    idf.newidfobject("BUILDING", Name="Building", North_Axis=0.0, Terrain="City",
                     # NOTE FullExterior: all beam solar entering a zone lands on the FLOOR.
                     # FullInteriorAndExterior would trace it onto each surface, but the E+
                     # manual (Building: Solar Distribution) says the zone must then be CONVEX
                     # when PolygonClipping is used (our default), and E+ runs a non-convex zone
                     # (L / T / U footprint, courtyard) without a warning.
                     Solar_Distribution="FullExterior",
                     # Warmup stops when the zone temperature changes by less than this between
                     # consecutive warmup days. In a FREE-FLOAT run that temperature IS the result,
                     # so the IDD default of 0.4 K would land straight in the answer.
                     Temperature_Convergence_Tolerance_Value=0.2,
                     # Heavier material layers can need more warmup days to converge.
                     Maximum_Number_of_Warmup_Days=50, Minimum_Number_of_Warmup_Days=6)
    # E+ defaults, written explicitly so the model stays pinned if a future version changes them.
    idf.newidfobject("HEATBALANCEALGORITHM", Algorithm="ConductionTransferFunction")
    idf.newidfobject("SURFACECONVECTIONALGORITHM:INSIDE", Algorithm="TARP")
    idf.newidfobject("SURFACECONVECTIONALGORITHM:OUTSIDE", Algorithm="DOE-2")
    idf.newidfobject("GLOBALGEOMETRYRULES", Starting_Vertex_Position="UpperLeftCorner",
                     Vertex_Entry_Direction="Counterclockwise", Coordinate_System="World")
    idf.newidfobject("SIMULATIONCONTROL",
                     Do_Zone_Sizing_Calculation="No", Do_System_Sizing_Calculation="No",
                     Do_Plant_Sizing_Calculation="No", Run_Simulation_for_Sizing_Periods="No",
                     Run_Simulation_for_Weather_File_Run_Periods="Yes")
    # Site:Location is intentionally omitted. For weather-file runs, EnergyPlus
    # uses the EPW LOCATION header, so this IDF stays independent of one weather file.

    # No SizingPeriod:DesignDay: SimulationControl runs sizing periods = No, so design days
    # never execute in a free-float weather run. The EPW RunPeriod below is the whole simulation.
    idf.newidfobject("RUNPERIOD", Name="FullYear",
                     Begin_Month=1, Begin_Day_of_Month=1, End_Month=12, End_Day_of_Month=31,
                     Day_of_Week_for_Start_Day="Monday",
                     Use_Weather_File_Holidays_and_Special_Days="Yes",
                     Use_Weather_File_Daylight_Saving_Period="Yes",
                     Apply_Weekend_Holiday_Rule="No",
                     Use_Weather_File_Rain_Indicators="Yes",
                     Use_Weather_File_Snow_Indicators="Yes")

    # Fixed ground temperatures for surfaces with the Ground boundary condition
    # (18 C = the IDD default of Site:GroundTemperature:BuildingSurface; our accepted value).
    gt = idf.newidfobject("SITE:GROUNDTEMPERATURE:BUILDINGSURFACE")
    for month in ("January", "February", "March", "April", "May", "June", "July",
                  "August", "September", "October", "November", "December"):
        setattr(gt, f"{month}_Ground_Temperature", 18.0)

    # ================= OUTPUTS ======= (uncomment what you want)
    # Geometry and result reports.
    #idf.newidfobject("OUTPUT:SURFACES:DRAWING", Report_Type="DXF",Report_Specifications_1="Triangulate3DFace")  #  →  eplusout.dxf     3D geometry picture

    #idf.newidfobject("OUTPUT:SURFACES:LIST", Report_Type="DetailsWithVertices") # per-surface area/azimuth/tilt/boundary (eplusout.eio: needs Output_EIO="Yes" below)
    idf.newidfobject("OUTPUT:DIAGNOSTICS", Key_1="DisplayExtraWarnings")     # The full warning/Severe/Fatal list  (eplusout.err)
    #idf.newidfobject("OUTPUTCONTROL:TABLE:STYLE", Column_Separator="HTML")

    # eplusout.sql — the hourly results in a queryable form (python stdlib `sqlite3`, no extra
    # dependency)
    idf.newidfobject("OUTPUT:SQLITE", Option_Type="SimpleAndTabular")
    #idf.newidfobject("OUTPUT:TABLE:SUMMARYREPORTS", Report_1_Name="AllSummary")# Envelope Summary, zone areas — the human-readable audit  (eplustbl.htm)

    #idf.newidfobject("OUTPUT:VARIABLEDICTIONARY", Key_Field="IDF")# every variable name available for this model  (eplusout.rdd / .mdd: needs Output_RDD / Output_MDD="Yes" below)

    # Which files EnergyPlus writes. A field left out means the IDD default, which is "Yes"
    # for almost every file, so every switch is written out: change "No" to "Yes" to get a file.
    # Always written, no switch: eplusout.err; with SQLite also its log sqlite.err.
    idf.newidfobject("OUTPUTCONTROL:FILES",
                     Output_CSV="Yes",           # eplusout.csv   the hourly Output:Variables, by E+ itself
                     Output_MTR="No",            # eplusout.mtr   meters
                     Output_ESO="No",            # eplusout.eso   raw text results (the CSV and SQL hold them)
                     Output_EIO="No",            # eplusout.eio   setup report (surfaces list, constructions)
                     Output_Tabular="No",        # eplustbl.*     summary tables
                     Output_SQLite="Yes",        # eplusout.sql   every result, for the report
                     Output_JSON="No",           # eplusout.json
                     Output_AUDIT="No",          # eplusout.audit input processing log
                     Output_Space_Sizing="No",   # sizing results (no HVAC in a free-float run)
                     Output_Zone_Sizing="No",
                     Output_System_Sizing="No",
                     Output_DXF="No",            # eplusout.dxf   3D drawing (also needs OUTPUT:SURFACES:DRAWING)
                     Output_BND="No",            # eplusout.bnd   HVAC node report
                     Output_RDD="No",            # eplusout.rdd   available variables (needs OUTPUT:VARIABLEDICTIONARY)
                     Output_MDD="No",            # eplusout.mdd   available meters (same)
                     Output_MTD="No",            # eplusout.mtd   meter details
                     Output_END="No",            # eplusout.end   one-line end status (the .err says it too)
                     Output_SHD="No",            # eplusout.shd   shading calculation report
                     Output_DFS="No",            # the rest: each needs its own object, none is written
                     Output_GLHE="No",
                     Output_DelightIn="No",
                     Output_DelightELdmp="No",
                     Output_DelightDFdmp="No",
                     Output_EDD="No",
                     Output_DBG="No",
                     Output_PerfLog="No",
                     Output_SLN="No",
                     Output_SCI="No",
                     Output_WRL="No",
                     Output_Screen="NO",        # console text (not a file); the runner captures it
                     Output_ExtShd="No",
                     Output_Tarcog="No",
                     Output_Plant_Component_Sizing="No")

    # the hourly results (Output:Variable) -> eplusout.csv and eplusout.sql
    idf.newidfobject("OUTPUT:VARIABLE", Key_Value="*",
                     Variable_Name="Zone Mean Air Temperature", Reporting_Frequency="Hourly")
    # Zone Operative Temperature = 0.5*air + 0.5*mean-radiant: the free-float comfort result.
    idf.newidfobject("OUTPUT:VARIABLE", Key_Value="*",
                     Variable_Name="Zone Operative Temperature", Reporting_Frequency="Hourly")
    # The other half of operative temperature — tells us whether a swing is air- or mass-driven.
    idf.newidfobject("OUTPUT:VARIABLE", Key_Value="*",
                     Variable_Name="Zone Mean Radiant Temperature", Reporting_Frequency="Hourly")
    idf.newidfobject("OUTPUT:VARIABLE", Key_Value="*",
                     Variable_Name="Site Outdoor Air Drybulb Temperature", Reporting_Frequency="Hourly")
    # Both read 0 when the feature is absent, and that zero IS the evidence: 0 W of transmitted
    # solar proves a window-less run really has no glazing.
    idf.newidfobject("OUTPUT:VARIABLE", Key_Value="*",
                     Variable_Name="Enclosure Windows Total Transmitted Solar Radiation Rate",
                     Reporting_Frequency="Hourly")
    idf.newidfobject("OUTPUT:VARIABLE", Key_Value="*",
                     Variable_Name="Zone Total Internal Total Heating Rate",
                     Reporting_Frequency="Hourly")
    idf.newidfobject("OUTPUT:VARIABLE", Key_Value="*",
                     Variable_Name="Surface Inside Face Temperature", Reporting_Frequency="Hourly")
    idf.newidfobject("OUTPUT:VARIABLE", Key_Value="*",
                     Variable_Name="Surface Outside Face Temperature", Reporting_Frequency="Hourly")
    # Average of the inside and outside face conduction [W] (E+ I/O Reference), positive toward
    # the zone. On a slab it mixes the heat crossing it with the heat its mass stores, so it is
    # not zero in fast mode.
    idf.newidfobject("OUTPUT:VARIABLE", Key_Value="*",
                     Variable_Name="Surface Average Face Conduction Heat Transfer Rate",
                     Reporting_Frequency="Hourly")

    return idf


def add_materials(idf, materials):
    """Emit one EnergyPlus material object per middle-layer material."""
    for material in materials.values():
        if material.eplus == "Material:AirGap":
            idf.newidfobject("MATERIAL:AIRGAP", Name=material.name,
                             Thermal_Resistance=material.thermal_resistance)
        elif material.eplus == "Material:NoMass":
            idf.newidfobject("MATERIAL:NOMASS", Name=material.name, Roughness=material.roughness,
                             Thermal_Resistance=material.thermal_resistance)
        else:
            # 0.9 / 0.7 / 0.7 are OUR values for every material (the ADE emissivity /
            # reflectance are not read yet); the inside-face fields stay blank, so E+ uses the
            # same value on both faces (IDD Material N8-N10).
            idf.newidfobject("MATERIAL", Name=material.name, Roughness=material.roughness,
                             Thickness=material.thickness, Conductivity=material.conductivity,
                             Density=material.density, Specific_Heat=material.specific_heat,
                             Thermal_Absorptance=0.9, Solar_Absorptance=0.7,
                             Visible_Absorptance=0.7)


def _energyplus_layers(construction):
    """The layers in EnergyPlus order, outside first (IDD Construction: "Start with outside
    layer"); the ADE lists them inside -> outside, so every construction is reversed."""
    return list(reversed(construction.layers))


def add_constructions(idf, constructions):
    """Emit each construction used by the building."""
    for name, construction in constructions.items():
        if not construction.layers:
            continue
        layers = _energyplus_layers(construction)
        construction_object = idf.newidfobject("CONSTRUCTION", Name=name)
        construction_object.Outside_Layer = layers[0]
        for index, layer in enumerate(layers[1:], start=2):
            setattr(construction_object, f"Layer_{index}", layer)


def _vertex_fields(points):
    """Build vertex keyword arguments for eppy object creation."""
    fields = {}
    for index, (vertex_x, vertex_y, vertex_z) in enumerate(points, start=1):
        fields[f"Vertex_{index}_Xcoordinate"] = round(vertex_x, 6)
        fields[f"Vertex_{index}_Ycoordinate"] = round(vertex_y, 6)
        fields[f"Vertex_{index}_Zcoordinate"] = round(vertex_z, 6)
    return fields


def add_building(idf, building):
    """Emit one Zone per middle-layer zone, then one BuildingSurface:Detailed per surface.

    Parameters
    ----------
    idf : eppy.modeleditor.IDF
        The IDF being built, changed in place.
    building : Building
        A building that passed model/zones.py: it has at least one zone and every surface
        names its zone. The writer invents no zone (a building without one was dropped there).
    """
    for zone in building.zones:
        idf.newidfobject("ZONE", Name=zone.name, Multiplier=1, Ceiling_Height="autocalculate",
                         Volume="autocalculate")
    for surface in building.surfaces:
        boundary = surface.boundary
        sun, wind = sun_wind_exposure(boundary)
        idf.newidfobject(
            "BUILDINGSURFACE:DETAILED", Name=surface.source_id, Surface_Type=surface.surface_type,
            Construction_Name=surface.construction, Zone_Name=surface.zone,
            Outside_Boundary_Condition=boundary,
            Outside_Boundary_Condition_Object=surface.boundary_object,
            Sun_Exposure=sun, Wind_Exposure=wind, Number_of_Vertices=len(surface.points),
            **_vertex_fields(surface.points))


def add_infiltration(idf, building):
    """One ZoneInfiltration:DesignFlowRate per zone that STATES an air change rate.

    Infiltration = outdoor air leaking in through the fabric. In a free-float run it is the
    direct air-to-air link to outdoors, so a zone without it floats like a thermos flask.

    PRESENCE-BASED: a zone whose file gave no nrg3:infiltrationRate gets no object
    (model/zone_physics.py already warned). The infiltration Output:Variables are requested
    only when at least one object exists — E+ warns about a variable it cannot produce, and
    that would pollute the clean-.err gate on every windowless/sealed run.

    IDD ZoneInfiltration:DesignFlowRate —
      A3 Schedule Name  left BLANK: "If blank, defaults to always 1.0", so a constant rate
                        needs no Schedule objects at all.
      A4 AirChanges/Hour is a key: E+ itself does ACH x zone volume -> m3/s, so we never
                        compute a flow rate.
      N5..N8 A/B/C/D = 1/0/0/0 (the IDD default) makes the modifier bracket
                        [A + B|dT| + C*wind + D*wind^2] exactly 1, so E+ applies the rate the
                        FILE stated.
      A5 Density Basis  Outdoor (the IDD default, written by eppy): the rate is applied at
                        the outdoor air density, so "Zone Infiltration Outdoor Density Air
                        Change Rate" reports exactly the file's rate.
    """
    zones_with_rate = [zone for zone in building.zones if zone.infiltration_ach is not None]
    for zone in zones_with_rate:
        idf.newidfobject("ZONEINFILTRATION:DESIGNFLOWRATE",
                         Name=f"{zone.name}_Infiltration",
                         Zone_or_ZoneList_or_Space_or_SpaceList_Name=zone.name,
                         Design_Flow_Rate_Calculation_Method="AirChanges/Hour",
                         Air_Changes_per_Hour=zone.infiltration_ach,
                         Constant_Term_Coefficient=1.0, Temperature_Term_Coefficient=0.0,
                         Velocity_Term_Coefficient=0.0, Velocity_Squared_Term_Coefficient=0.0)
    if zones_with_rate:
        for variable in ("Zone Infiltration Outdoor Density Air Change Rate",  # = the file's rate
                         "Zone Infiltration Sensible Heat Loss Energy",        # winter direction
                         "Zone Infiltration Sensible Heat Gain Energy"):       # summer direction
            idf.newidfobject("OUTPUT:VARIABLE", Key_Value="*", Variable_Name=variable,
                             Reporting_Frequency="Hourly")


def add_window_constructions(idf, window_constructions):
    """Emit glazing material + construction objects for window constructions."""
    for wc in window_constructions.values():
        glazing = idf.newidfobject("WINDOWMATERIAL:SIMPLEGLAZINGSYSTEM", Name=wc.name,
                                   UFactor=wc.u_factor, Solar_Heat_Gain_Coefficient=wc.shgc)
        if wc.visible_transmittance is not None:
            glazing.Visible_Transmittance = wc.visible_transmittance
        construction = idf.newidfobject("CONSTRUCTION", Name=wc.name)
        construction.Outside_Layer = wc.name


def add_windows(idf, building, window_constructions):
    """Emit one FenestrationSurface:Detailed object per middle-layer window."""
    if not window_constructions:
        return
    for surface in building.surfaces:
        for window in surface.windows:
            idf.newidfobject(
                "FENESTRATIONSURFACE:DETAILED", Name=window.source_id,
                Surface_Type="Window", Construction_Name=window.construction,
                Building_Surface_Name=surface.source_id,
                Number_of_Vertices=len(window.points),
                **_vertex_fields(window.points))


def build_idf(building, constructions, materials, window_constructions, out_dir):
    """Write one building's IDF and return its path.

    Parameters
    ----------
    building : Building
        A building with surfaces (one that got no IDF is never passed).
    constructions, materials, window_constructions : dict
        The building's OWN pools, from Model.subset_for_building (the same slice the JSON is
        written from, so the two cannot disagree).
    out_dir : str
        The folder the IDF is written to (created if needed).
    """
    ensure_idd()
    idf = new_empty_idf()
    idf.idfobjects["BUILDING"][0].Name = building.id
    add_materials(idf, materials) # → MATERIAL / :NOMASS / :AIRGAP
    add_constructions(idf, constructions) # → CONSTRUCTION
    add_building(idf, building) # → ZONE + BUILDINGSURFACE:DETAILED
    add_infiltration(idf, building) # → ZONEINFILTRATION:DESIGNFLOWRATE (only zones that state a rate)
    add_window_constructions(idf, window_constructions) # → WINDOWMATERIAL:SIMPLEGLAZINGSYSTEM
    add_windows(idf, building, window_constructions) # → FENESTRATIONSURFACE:DETAILED
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, f"{building.id}.idf")
    idf.saveas(out_path)
    return out_path
