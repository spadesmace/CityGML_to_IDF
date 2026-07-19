"""
Create EnergyPlus IDF files from the middle-layer Model.

The writer emits simulation settings, reports, materials, constructions, zones,
surfaces, and windows. It does not run EnergyPlus;
use EP-Launch or citygml2idf.run_energyplus for simulation.
"""

from __future__ import annotations

import os
import sys
from io import StringIO

from eppy.modeleditor import IDF

from ..citygml import xml_io
from ..semantics.surface_types import sun_wind_exposure
from ..model.model import Zone
from ..model.reader import build_middle_layer

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG = os.path.dirname(_HERE)
_TEMPLATES = os.path.join(_PKG, "templates")
IDD_PATH = os.path.join(_TEMPLATES, "Energy+.idd")
OUTPUT_IDF_DIR = os.path.join(_PKG, "output", "idf")


def ensure_idd(idd_path=IDD_PATH):
    if IDF.getiddname() is None:
        IDF.setiddname(idd_path)


def new_empty_idf():
    """Create base IDF settings for a weather-file free-floating run."""
    idf = IDF(StringIO(""))
    idf.newidfobject("VERSION", Version_Identifier="23.1")
    idf.newidfobject("TIMESTEP", Number_of_Timesteps_per_Hour=4)
    idf.newidfobject("BUILDING", Name="Building", North_Axis=0.0, Terrain="City",
                     Solar_Distribution="FullExterior",
                     # Heavier material layers can need more warmup days to converge.
                     Maximum_Number_of_Warmup_Days=50, Minimum_Number_of_Warmup_Days=6)
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

    # Fixed ground temperatures for surfaces with the Ground boundary condition.
    # EnergyPlus defaults these fields to 18 C; writing them explicitly suppresses warnings.
    gt = idf.newidfobject("SITE:GROUNDTEMPERATURE:BUILDINGSURFACE")
    for month in ("January", "February", "March", "April", "May", "June", "July",
                  "August", "September", "October", "November", "December"):
        setattr(gt, f"{month}_Ground_Temperature", 18.0)

    # Geometry and result reports.
    idf.newidfobject("OUTPUT:SURFACES:DRAWING", Report_Type="DXF",
                     Report_Specifications_1="Triangulate3DFace")
    idf.newidfobject("OUTPUT:SURFACES:LIST", Report_Type="DetailsWithVertices") # per-surface area/azimuth/tilt/boundary — confirms geometry & the Adiabatic/Surface decision (epluseout.eio)
    idf.newidfobject("OUTPUT:DIAGNOSTICS", Key_1="DisplayExtraWarnings")     # The full warning/Severe/Fatal list  (eplusout.err)
    idf.newidfobject("OUTPUTCONTROL:TABLE:STYLE", Column_Separator="HTML")
    idf.newidfobject("OUTPUT:TABLE:SUMMARYREPORTS", Report_1_Name="AllSummary")     # Envelope Summary, zone areas — the human-readable audit  (eplustbl.htm)
    idf.newidfobject("OUTPUT:VARIABLEDICTIONARY", Key_Field="IDF")              # every variable name available for this model  (eplusout.rdd)
    idf.newidfobject("OUTPUT:VARIABLE", Key_Value="*",
                     Variable_Name="Zone Mean Air Temperature", Reporting_Frequency="Hourly")
    # Zone Operative Temperature = 0.5*air + 0.5*mean-radiant: the free-float comfort result.
    idf.newidfobject("OUTPUT:VARIABLE", Key_Value="*",
                     Variable_Name="Zone Operative Temperature", Reporting_Frequency="Hourly")
    idf.newidfobject("OUTPUT:VARIABLE", Key_Value="*",
                     Variable_Name="Site Outdoor Air Drybulb Temperature", Reporting_Frequency="Hourly")
    idf.newidfobject("OUTPUT:VARIABLE", Key_Value="*",
                     Variable_Name="Surface Inside Face Temperature", Reporting_Frequency="Hourly")
    idf.newidfobject("OUTPUT:VARIABLE", Key_Value="*",
                     Variable_Name="Surface Outside Face Temperature", Reporting_Frequency="Hourly")
    # Net conduction through each surface [W]. On an interzone face this is the heat exchanged
    # between the two zones: ~0 in fast mode (Adiabatic), nonzero in detailed mode (Surface).
    idf.newidfobject("OUTPUT:VARIABLE", Key_Value="*",
                     Variable_Name="Surface Average Face Conduction Heat Transfer Rate",
                     Reporting_Frequency="Hourly")

    return idf


def add_materials(idf, materials):
    """Emit one EnergyPlus material object per middle-layer material."""
    for m in materials.values():
        if m.eplus == "Material:AirGap":
            idf.newidfobject("MATERIAL:AIRGAP", Name=m.name,
                             Thermal_Resistance=m.thermal_resistance)
        elif m.eplus == "Material:NoMass":
            idf.newidfobject("MATERIAL:NOMASS", Name=m.name, Roughness=m.roughness,
                             Thermal_Resistance=m.thermal_resistance)
        else:
            idf.newidfobject("MATERIAL", Name=m.name, Roughness=m.roughness,
                             Thickness=m.thickness, Conductivity=m.conductivity,
                             Density=m.density, Specific_Heat=m.specific_heat,
                             Thermal_Absorptance=0.9, Solar_Absorptance=0.7,
                             Visible_Absorptance=0.7)


def _energyplus_layers(construction):
    """Return construction layers in EnergyPlus outside-to-inside order."""
    layers = list(construction.layers)
    if construction.layer_order == "inside_to_outside":
        return list(reversed(layers))
    return layers


def add_constructions(idf, constructions):
    """Emit each construction used by the building."""
    for name, c in constructions.items():
        if not c.layers:
            continue
        layers = _energyplus_layers(c)
        obj = idf.newidfobject("CONSTRUCTION", Name=name)
        obj.Outside_Layer = layers[0]
        for i, mat in enumerate(layers[1:], start=2):
            setattr(obj, f"Layer_{i}", mat)


def _vertex_fields(points):
    """Build vertex keyword arguments for eppy object creation."""
    fields = {}
    for index, (vertex_x, vertex_y, vertex_z) in enumerate(points, start=1):
        fields[f"Vertex_{index}_Xcoordinate"] = round(vertex_x, 6)
        fields[f"Vertex_{index}_Ycoordinate"] = round(vertex_y, 6)
        fields[f"Vertex_{index}_Zcoordinate"] = round(vertex_z, 6)
    return fields


def add_building(idf, building):
    """Emit zones, then one BuildingSurface:Detailed per middle-layer surface."""
    zone_list = building.zones or [Zone(f"{building.id}_Zone")]
    for zone in zone_list:
        idf.newidfobject("ZONE", Name=zone.name, Multiplier=1, Ceiling_Height="autocalculate",
                         Volume="autocalculate")
    default_zone = zone_list[0].name
    for surface in building.surfaces:
        boundary = surface.boundary
        sun, wind = sun_wind_exposure(boundary)
        idf.newidfobject(
            "BUILDINGSURFACE:DETAILED", Name=surface.source_id, Surface_Type=surface.surface_type,
            Construction_Name=surface.construction, Zone_Name=surface.zone or default_zone,
            Outside_Boundary_Condition=boundary,
            Outside_Boundary_Condition_Object=surface.boundary_object,
            Sun_Exposure=sun, Wind_Exposure=wind, Number_of_Vertices=len(surface.points),
            **_vertex_fields(surface.points))


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


def build_idf(building, constructions, materials, window_constructions=None, out_dir=OUTPUT_IDF_DIR):
    """Write one building's IDF. The caller passes the building's OWN constructions/
    materials/glazings (Model.subset_for_building) — the writer emits what it is given."""
    ensure_idd()
    idf = new_empty_idf()
    idf.idfobjects["BUILDING"][0].Name = building.id
    add_materials(idf, materials) # → MATERIAL / :NOMASS / :AIRGAP
    add_constructions(idf, constructions) # → CONSTRUCTION
    add_building(idf, building) # → ZONE + BUILDINGSURFACE:DETAILED
    add_window_constructions(idf, window_constructions or {}) # → WINDOWMATERIAL:SIMPLEGLAZINGSYSTEM
    add_windows(idf, building, window_constructions or {}) # → FENESTRATIONSURFACE:DETAILED
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, f"{building.id}.idf")
    idf.saveas(out_path)
    return out_path


def main(path=None):
    doc = xml_io.CityGMLDoc(path)
    middle = build_middle_layer(doc)
    for b in middle.buildings:
        if not b.surfaces:
            continue
        subset = middle.subset_for_building(b.id)
        idf_path = build_idf(b, subset.constructions, subset.materials,
                             subset.window_constructions)
        print(f"{b.id:<12} {len(b.surfaces):>2} surf  IDF_CREATED  -> {idf_path}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else None)
