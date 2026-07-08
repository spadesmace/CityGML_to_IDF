"""
write/writer.py â€” MIDDLE LAYER â†’ EnergyPlus 23.1 IDF, one IDF per building.

Builds each IDF from an EMPTY IDF, block by block (eppy newidfobject): settings â†’
Material/NoMass/AirGap â†’ Construction â†’ Zone â†’ BuildingSurface:Detailed. Every value
comes from the middle layer (geometry already metric, recentred, wound outward; each
surface tagged with Surface_Type / boundary / construction). No template, no extrusion.

ZONES: one EnergyPlus Zone per middle-layer zone. In normal mode zones.py creates
one zone per nrg3:ThermalZone; in single-zone test stages it creates one implicit
building zone.

Run (from the repo root):
    python -m citygml2idf.write.writer [path-to-citygml]
builds output/idf/<building>.idf and runs EnergyPlus, reporting Severe/Fatal counts.
"""

from __future__ import annotations

import os
import subprocess
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
EPLUS_EXE = os.path.join(_TEMPLATES, "EnergyPlus-23.1.0-87ed9199d4-Windows-x86_64", "energyplus.exe")

# --- Weather (modular toggle). None = run WITHOUT weather (design-day only, like before).
#     To run a full annual simulation, UNCOMMENT the second line (point it at any .epw). ---
WEATHER_EPW = None
# WEATHER_EPW = os.path.join(_TEMPLATES, "weather.epw") #change to any weather file 
OUTPUT_IDF_DIR = os.path.join(_PKG, "output", "idf")

# Munich-ish (the sample's location); geometry-first, exact climate isn't critical.
SITE = dict(name="Munich-DE", lat=48.14, lon=11.58, tz=1.0, elev=520.0)


def ensure_idd(idd_path=IDD_PATH):
    if IDF.getiddname() is None:
        IDF.setiddname(idd_path)


def weather_available():
    """True only if WEATHER_EPW is set AND the file exists. Drives BOTH what goes into
    the IDF (RunPeriod + result outputs) and how EnergyPlus is run."""
    return bool(WEATHER_EPW) and os.path.isfile(WEATHER_EPW)


def new_empty_idf(with_weather=False):
    """The 'empty' IDF â€” settings only, no building yet (RULES Â§D). GlobalGeometryRules
    matches how the reader wound vertices: World coords, Counterclockwise (outward).

    with_weather=False -> design-day-only IDF: NO RunPeriod and NO result/report outputs.
    with_weather=True  -> adds the annual RunPeriod + summary/variable outputs.
    (The design days and the geometry/DXF outputs are written either way.)"""
    idf = IDF(StringIO(""))
    idf.newidfobject("VERSION", Version_Identifier="23.1")
    idf.newidfobject("TIMESTEP", Number_of_Timesteps_per_Hour=4)
    idf.newidfobject("BUILDING", Name="Building", North_Axis=0.0, Terrain="City",
                     Solar_Distribution="FullExterior",
                     # real thermal mass (proper cp) converges slower -> allow more warmup days
                     Maximum_Number_of_Warmup_Days=50, Minimum_Number_of_Warmup_Days=6)
    idf.newidfobject("GLOBALGEOMETRYRULES", Starting_Vertex_Position="UpperLeftCorner",
                     Vertex_Entry_Direction="Counterclockwise", Coordinate_System="World")
    idf.newidfobject("SIMULATIONCONTROL",
                     Do_Zone_Sizing_Calculation="No", Do_System_Sizing_Calculation="No",
                     Do_Plant_Sizing_Calculation="No", Run_Simulation_for_Sizing_Periods="Yes",
                     Run_Simulation_for_Weather_File_Run_Periods=("Yes" if with_weather else "No"))
    idf.newidfobject("SITE:LOCATION", Name=SITE["name"], Latitude=SITE["lat"],
                     Longitude=SITE["lon"], Time_Zone=SITE["tz"], Elevation=SITE["elev"])
    
    # Two design days so "Run for Sizing Periods" has something to compute (no weather file).
    idf.newidfobject("SIZINGPERIOD:DESIGNDAY", Name="WinterDesignDay", Month=1,
                     Day_of_Month=21, Day_Type="WinterDesignDay",
                     Maximum_DryBulb_Temperature=-12.0, Daily_DryBulb_Temperature_Range=0.0,
                     Humidity_Condition_Type="WetBulb", Wetbulb_or_DewPoint_at_Maximum_DryBulb=-12.0,
                     Barometric_Pressure=95000.0, Wind_Speed=4.0, Wind_Direction=270.0,
                     Solar_Model_Indicator="ASHRAEClearSky", Sky_Clearness=0.0)
    idf.newidfobject("SIZINGPERIOD:DESIGNDAY", Name="SummerDesignDay", Month=7,
                     Day_of_Month=21, Day_Type="SummerDesignDay",
                     Maximum_DryBulb_Temperature=30.0, Daily_DryBulb_Temperature_Range=10.0,
                     Humidity_Condition_Type="WetBulb", Wetbulb_or_DewPoint_at_Maximum_DryBulb=20.0,
                     Barometric_Pressure=95000.0, Wind_Speed=2.0, Wind_Direction=0.0,
                     Solar_Model_Indicator="ASHRAEClearSky", Sky_Clearness=1.0)
    
    

    # Annual run period (IDD: RunPeriod) â€” ONLY when we have weather; a design-day-only IDF omits it.
    if with_weather:
        idf.newidfobject("RUNPERIOD", Name="FullYear",
                         Begin_Month=1, Begin_Day_of_Month=1, End_Month=12, End_Day_of_Month=31,
                         Day_of_Week_for_Start_Day="Monday",
                         Use_Weather_File_Holidays_and_Special_Days="Yes",
                         Use_Weather_File_Daylight_Saving_Period="Yes",
                         Apply_Weekend_Holiday_Rule="No",
                         Use_Weather_File_Rain_Indicators="Yes",
                         Use_Weather_File_Snow_Indicators="Yes")

    # Ground temperatures for any surface with the `Ground` boundary condition.
    gt = idf.newidfobject("SITE:GROUNDTEMPERATURE:BUILDINGSURFACE")
    for month in ("January", "February", "March", "April", "May", "June", "July",
                  "August", "September", "October", "November", "December"):
        setattr(gt, f"{month}_Ground_Temperature", 16.0) # need improvement later 
    # Geometry visualisation: a DXF (upload eplusout.dxf to e.g. sharecad.org) + a
    # vertex list, so the building can be SEEN without running a full simulation.
    
    ############## OUtPUT ################
    idf.newidfobject("OUTPUT:SURFACES:DRAWING", Report_Type="DXF",
                     Report_Specifications_1="Triangulate3DFace")
    
    
    idf.newidfobject("OUTPUT:SURFACES:LIST", Report_Type="DetailsWithVertices")
    idf.newidfobject("OUTPUT:DIAGNOSTICS", Key_1="DisplayExtraWarnings")
    # Result tables/variables (field names verified vs the IDD) â€” ONLY for a full (weather)
    # run; a design-day-only IDF omits them (no annual results to report).
    if with_weather:
        idf.newidfobject("OUTPUTCONTROL:TABLE:STYLE", Column_Separator="HTML")
        idf.newidfobject("OUTPUT:TABLE:SUMMARYREPORTS", Report_1_Name="AllSummary")
        idf.newidfobject("OUTPUT:VARIABLEDICTIONARY", Key_Field="IDF")
        idf.newidfobject("OUTPUT:VARIABLE", Key_Value="*",
                         Variable_Name="Zone Mean Air Temperature", Reporting_Frequency="Monthly")
    
    
    return idf


def add_materials(idf, materials):
    """Emit one of the 3 E+ material objects per material, by its `eplus` type (M1)."""
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
                             Thermal_Absorptance=0.9, Solar_Absorptance=0.7, Visible_Absorptance=0.7) # IDD default


def _energyplus_layers(construction):
    """Middle layer stores ADE order; EnergyPlus wants outside-to-inside."""
    layers = list(construction.layers)
    if construction.layer_order == "inside_to_outside":
        return list(reversed(layers))
    return layers


def add_constructions(idf, constructions):
    """Emit each Construction in EnergyPlus outside-to-inside layer order."""
    for name, c in constructions.items():
        if not c.layers:
            continue
        layers = _energyplus_layers(c)
        obj = idf.newidfobject("CONSTRUCTION", Name=name)
        obj.Outside_Layer = layers[0]
        for i, mat in enumerate(layers[1:], start=2):
            setattr(obj, f"Layer_{i}", mat)


def _vertex_fields(points): #  just gathers all the corners into one bundle and hands them to eppy all at once, when the wall is first created.
    r"""Vertex coordinates as newidfobject() kwargs: {Vertex_1_Xcoordinate: x, ...}.

    WHY we pass vertices at CREATION and not with setattr afterwards:
    EnergyPlus accepts a face with ANY number of vertices — BuildingSurface:Detailed
    But eppy only materialises a freshly-created object's vertex fields up to ~4
    """
    fields = {}
    for index, (vertex_x, vertex_y, vertex_z) in enumerate(points, start=1):
        fields[f"Vertex_{index}_Xcoordinate"] = round(vertex_x, 6)
        fields[f"Vertex_{index}_Ycoordinate"] = round(vertex_y, 6)
        fields[f"Vertex_{index}_Zcoordinate"] = round(vertex_z, 6)
    return fields


def add_building(idf, building):
    """One E+ Zone per building['zones'] (zones.py / G12-G13), then one
    BuildingSurface:Detailed per surface placed in its surface['zone'] with the boundary
    zones.py decided (interzone -> explicit reciprocal Surface pair with A6=Surface
    and A7 pointing to the partner surface).
    Falls back to a single implicit zone if 'zones' is absent."""
    zone_list = building.zones or [Zone(f"{building.id}_Zone", None)]
    for zone in zone_list:
        idf.newidfobject("ZONE", Name=zone.name, Multiplier=1, Ceiling_Height="autocalculate",
                         Volume=zone.volume if zone.volume else "autocalculate")
    default_zone = zone_list[0].name
    for surface in building.surfaces:
        boundary = surface.boundary
        sun, wind = sun_wind_exposure(boundary)
        # Vertices go in as creation kwargs (see _vertex_fields) so faces with more
        # than 4 vertices build instead of tripping eppy's setattr limit.
        idf.newidfobject(
            "BUILDINGSURFACE:DETAILED", Name=surface.source_id, Surface_Type=surface.surface_type,
            Construction_Name=surface.construction, Zone_Name=surface.zone or default_zone,
            Outside_Boundary_Condition=boundary,
            Outside_Boundary_Condition_Object=surface.boundary_object,
            Sun_Exposure=sun, Wind_Exposure=wind, Number_of_Vertices=len(surface.points),
            **_vertex_fields(surface.points))


def add_window_constructions(idf, window_constructions):
    """Emit each glazing once: WindowMaterial:SimpleGlazingSystem + a Construction (W3).
    Visible Transmittance (IDD N3, optional) is written ONLY when the CityGML gave it."""
    for wc in window_constructions.values():
        glazing_material = wc.name + "_GLZ"
        glazing = idf.newidfobject("WINDOWMATERIAL:SIMPLEGLAZINGSYSTEM", Name=glazing_material,
                                   UFactor=wc.u_factor, Solar_Heat_Gain_Coefficient=wc.shgc)
        if wc.visible_transmittance is not None:
            glazing.Visible_Transmittance = wc.visible_transmittance
        construction = idf.newidfobject("CONSTRUCTION", Name=wc.name)
        construction.Outside_Layer = glazing_material


def add_windows(idf, building, window_constructions):
    """Emit one FenestrationSurface:Detailed per window on each wall, each referencing its
    OWN glazing construction (W1/W2)."""
    if not window_constructions:
        return
    for surface in building.surfaces:
        for window in surface.windows:
            # Same all-at-creation vertex passing as walls (see _vertex_fields).
            # EnergyPlus caps WINDOWS at 4 vertices; openings.py already reduced any
            # >4-vertex window to its in-plane bounding quad, so this is safe.
            idf.newidfobject(
                "FENESTRATIONSURFACE:DETAILED", Name=window.source_id,
                Surface_Type="Window", Construction_Name=window.construction,
                Building_Surface_Name=surface.source_id,
                Number_of_Vertices=len(window.points),
                **_vertex_fields(window.points))


def _used_subset(building, constructions, materials):
    """Only the constructions/materials THIS building uses (avoids unused-object warnings)."""
    cnames = {s.construction for s in building.surfaces}
    used_c = {n: constructions[n] for n in cnames if n in constructions}
    mnames = {m for c in used_c.values() for m in c.layers}
    used_m = {n: materials[n] for n in mnames if n in materials}
    return used_c, used_m


def build_idf(building, constructions, materials, window_constructions=None, out_dir=OUTPUT_IDF_DIR):
    ensure_idd()
    idf = new_empty_idf(weather_available())   # weather present -> RunPeriod + result outputs; else not
    idf.idfobjects["BUILDING"][0].Name = building.id
    window_constructions = window_constructions or {}
    used_c, used_m = _used_subset(building, constructions, materials)
    add_materials(idf, used_m)
    add_constructions(idf, used_c)
    add_building(idf, building)
    add_window_constructions(idf, window_constructions)   # W3 glazings (if any)
    add_windows(idf, building, window_constructions)       # W1/W2 fenestration (if any)
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, f"{building.id}.idf")
    idf.saveas(out_path)
    return out_path


def run_energyplus(idf_path, weather=WEATHER_EPW, out_dir=None):
    """Run EnergyPlus and return (rc, .err text). MODULAR: if a weather file is given
    and exists -> run WITH it (design days + the annual RunPeriod); otherwise fall back
    to design-day-only (the --design-day flag makes E+ skip the RunPeriod -> no weather
    needed). Same IDF works both ways. `out_dir` = where E+ writes ALL its output
    (eplusout.*); defaults to a run_<name>/ folder beside the IDF."""
    if out_dir is None:
        out_dir = os.path.join(os.path.dirname(idf_path), "run_" + os.path.basename(idf_path)[:-4])
    os.makedirs(out_dir, exist_ok=True)
    if weather and os.path.isfile(weather):
        cmd = [EPLUS_EXE, "--weather", weather, "--output-directory", out_dir, idf_path]
    else:
        cmd = [EPLUS_EXE, "--design-day", "--output-directory", out_dir, idf_path]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    err_file = os.path.join(out_dir, "eplusout.err")
    err_txt = open(err_file, encoding="utf-8").read() if os.path.exists(err_file) else "(no .err)"
    return proc.returncode, err_txt


def main(path=None):
    doc = xml_io.CityGMLDoc(path)
    middle = build_middle_layer(doc)
    cons, mats = middle.constructions, middle.materials
    for b in middle.buildings:
        if not b.surfaces:                       # LoD0 / no envelope -> not buildable
            continue
        idf_path = build_idf(b, cons, mats, middle.window_constructions)
        rc, err = run_energyplus(idf_path)
        sev = [ln for ln in err.splitlines() if "** Severe" in ln or "** Fatal" in ln]
        warns = sum(1 for ln in err.splitlines() if "** Warning" in ln)
        status = "OK" if not sev else f"{len(sev)} SEVERE/FATAL"
        print(f"{b.id:<12} {len(b.surfaces):>2} surf  exit={rc}  warnings={warns}  -> {status}")
        for ln in sev[:8]:
            print("    ", ln.strip())


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else None)

