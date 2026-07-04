"""
model/reader.py - assemble writer-neutral middle layers from the parsers.

The parser has one path and two views:

    trace/debug middle layer
        Full parser evidence: source ids, construction traces, raw values,
        converted values, fallback reasons. Use this for teaching, audits, and
        checking the parser against CityGML/Energy ADE.

    IDF middle layer
        Clean EnergyPlus-ready writer contract. writer.py reads only this view:
        buildings, zones, surfaces, constructions, materials, and windows.

Both views come from the same parsed data. There is no separate test parser.
"""

from __future__ import annotations

import copy
import json
import os
import sys

from ..citygml import xml_io
from ..citygml.xml_io import GML_ID
from ..geometry import crs, rings
from ..semantics import building_surfaces
from . import constructions
from . import openings
from . import zones
from .idf_model import (IdfBuilding, IdfConstruction, IdfMaterial, IdfModel,
                        IdfSurface, IdfWindow, IdfZone, WindowConstruction)

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG = os.path.dirname(_HERE)                       # citygml2idf/
OUTPUT_DIR = os.path.join(_PKG, "output")


def build_trace_middle_layer(doc):
    """Parse every building into the full trace/debug middle layer.

    This is the rich parser view. It intentionally keeps trace fields such as
    construction_trace, raw_citygml, converted values, source ids, and fallback
    reasons so we can audit parser behavior against the source GML.
    """
    # 1. geometry + roles per building (points still in the file's CRS)
    buildings = []
    for b in xml_io.buildings(doc):
        lod_n, surface_path, surfaces = building_surfaces.surfaces_of_building(doc, b)
        buildings.append({"id": b.get(GML_ID), "lod": lod_n,
                          "surface_path": surface_path.value, "surfaces": surfaces})

    # 2. reproject to metres only if the CRS is geographic (no-op when already projected)
    src_epsg = crs.parse_epsg(xml_io.srs_name(doc))
    sample_lonlat = None
    for bld in buildings:
        if bld["surfaces"]:
            p = bld["surfaces"][0]["points"][0]
            sample_lonlat = (p[0], p[1])
            break
    transformer = crs.build_transformer(src_epsg, sample_lonlat)
    for bld in buildings:
        for s in bld["surfaces"]:
            s["points"] = crs.reproject(s["points"], transformer)

    # 3. recentre EACH building to its own origin (one IDF per building) and
    #    record the shift so we still know the building's true site position.
    for bld in buildings:
        rings_m = [s["points"] for s in bld["surfaces"]]
        if not rings_m:
            continue
        ox, oy, oz = crs.min_corner(rings_m)
        for s in bld["surfaces"]:
            s["points"] = [[float(x - ox), float(y - oy), float(z - oz)]
                           for (x, y, z) in s["points"]]
            s["area"] = round(rings.polygon_area(s["points"]), 3)
        bld["origin_offset"] = [float(ox), float(oy), float(oz)]

    middle = {
        "view": "trace",
        "crs": {
            "srsName": xml_io.srs_name(doc),
            "epsg": src_epsg,
            "reprojected": transformer is not None,
        },
        "buildings": buildings,
    }

    # These modules enrich the same trace middle layer. They are still parser
    # concerns; writer.py should consume only to_idf_middle_layer(middle).
    constructions.resolve_all(doc, middle)
    openings.resolve_windows(doc, middle)
    zones.assign_zones(doc, middle)
    return middle


# Backward-compatible name: historically this returned the rich middle layer.
def build_middle_layer(doc):
    """Return the full trace/debug middle layer."""
    return build_trace_middle_layer(doc)


def _surface_for_idf(surface):
    """One typed IdfSurface: only the fields writer.py needs for IDF objects."""
    windows = [IdfWindow(source_id=window["source_id"], points=copy.deepcopy(window["points"]))
               for window in (surface.get("windows") or [])]
    return IdfSurface(
        source_id=surface["source_id"],
        surface_type=surface["surface_type"],
        boundary=surface["boundary"],
        construction=surface["construction"],
        zone=surface.get("zone", ""),
        boundary_object=surface.get("boundary_object", ""),
        points=copy.deepcopy(surface["points"]),
        windows=windows,
    )


def _building_for_idf(building):
    """One typed IdfBuilding: its zones + cleaned surfaces."""
    zones = [IdfZone(name=zone["name"], volume=zone.get("volume"))
             for zone in building.get("zones", [])]
    surfaces = [_surface_for_idf(surface) for surface in building.get("surfaces", [])]
    return IdfBuilding(id=building["id"], zones=zones, surfaces=surfaces)


def _construction_for_idf(construction):
    """One typed IdfConstruction: layer names and source layer order only."""
    return IdfConstruction(layers=list(construction.get("layers", [])),
                           layer_order=construction.get("layer_order"))


def _material_for_idf(material):
    """One typed IdfMaterial (only the fields its `eplus` object needs are set)."""
    return IdfMaterial(
        name=material["name"],
        eplus=material.get("eplus"),
        roughness=material.get("roughness"),
        thickness=material.get("thickness"),
        conductivity=material.get("conductivity"),
        density=material.get("density"),
        specific_heat=material.get("specific_heat"),
        thermal_resistance=material.get("thermal_resistance"),
    )


def _window_construction_for_idf(window_construction):
    if not window_construction:
        return None
    return WindowConstruction(name=window_construction["name"],
                              u_factor=window_construction["u_factor"],
                              shgc=window_construction["shgc"])


def to_idf_middle_layer(trace_middle):
    """Return the clean, TYPED EnergyPlus writer view (IdfModel) from the trace view.

    Buildings with no usable surfaces (e.g. LoD0, surface_path='none') are KEPT in the
    trace view but dropped here, so the writer never emits a zone-with-no-surfaces IDF.
    """
    buildings = []
    for building in trace_middle.get("buildings", []):
        if not building.get("surfaces"):
            xml_io.warn(f"building {building.get('id')}: no surfaces "
                        f"(surface_path={building.get('surface_path')}); skipped from IDF output")
            continue
        buildings.append(_building_for_idf(building))

    construction_names = {
        surface.construction
        for building in buildings
        for surface in building.surfaces
        if surface.construction
    }
    constructions_used = {
        name: _construction_for_idf(trace_middle["constructions"][name])
        for name in construction_names
        if name in trace_middle.get("constructions", {})
    }
    material_names = {
        material
        for construction in constructions_used.values()
        for material in construction.layers
    }
    materials_used = {
        name: _material_for_idf(trace_middle["materials"][name])
        for name in material_names
        if name in trace_middle.get("materials", {})
    }

    return IdfModel(
        view="idf",
        crs=copy.deepcopy(trace_middle.get("crs", {})),
        buildings=buildings,
        constructions=constructions_used,
        materials=materials_used,
        window_construction=_window_construction_for_idf(trace_middle.get("window_construction")),
    )


def build_both_middle_layers(doc):
    """Parse once, then return (trace_middle, idf_middle)."""
    trace_middle = build_trace_middle_layer(doc)
    return trace_middle, to_idf_middle_layer(trace_middle)


def build_idf_middle_layer(doc):
    """Parse once and return the clean writer contract."""
    return to_idf_middle_layer(build_trace_middle_layer(doc))


def write_middle_layer(doc, out_path=None, view="trace"):
    """Build and dump either the trace or IDF middle layer."""
    if view == "trace":
        middle = build_trace_middle_layer(doc)
    elif view == "idf":
        middle = build_idf_middle_layer(doc)
    else:
        raise ValueError("view must be 'trace' or 'idf'")
    out_path = out_path or os.path.join(OUTPUT_DIR, f"middle_layer_{view}.json")
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    payload = middle.to_jsonable() if isinstance(middle, IdfModel) else middle
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)
    return middle, out_path


def _demo(path=None):
    doc = xml_io.CityGMLDoc(path or xml_io.DEFAULT_INPUT)
    trace_middle, idf_middle = build_both_middle_layers(doc)
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    trace_path = os.path.join(OUTPUT_DIR, "middle_layer_trace.json")
    idf_path = os.path.join(OUTPUT_DIR, "middle_layer_idf.json")
    with open(trace_path, "w", encoding="utf-8") as f:
        json.dump(trace_middle, f, indent=2)
    with open(idf_path, "w", encoding="utf-8") as f:
        json.dump(idf_middle.to_jsonable(), f, indent=2)

    c = trace_middle["crs"]
    print(f"CRS: {c['srsName']}  epsg={c['epsg']}  reprojected={c['reprojected']}")
    for bld in trace_middle["buildings"]:
        n = len(bld["surfaces"])
        total = round(sum(s["area"] for s in bld["surfaces"]), 1)
        print(f"  {bld['id']:<12} LOD{bld['lod']}  {n:>2} surfaces  envelope={total} m^2"
              f"  site_origin={[round(v, 1) for v in bld.get('origin_offset', [])]}")
    if trace_middle["buildings"] and trace_middle["buildings"][0]["surfaces"]:
        s0 = trace_middle["buildings"][0]["surfaces"][0]
        print(f"  e.g. {s0['source_id']}: {s0['surface_type']}/{s0['boundary']} "
              f"area={s0['area']} pts[0]={s0['points'][0]}")
    print(f"  trace -> {trace_path}")
    print(f"  idf   -> {idf_path}")


if __name__ == "__main__":
    _demo(sys.argv[1] if len(sys.argv) > 1 else None)

