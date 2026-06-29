"""
model/reader.py — assemble the writer-neutral MIDDLE LAYER from the readers.

Pipeline (geometry slice):
    for each Building -> building_surfaces.surfaces_of_building (geometry + roles)
    -> reproject to metres IF the CRS is geographic                 [RULES G1-G2]
    -> recentre EACH building to its own origin (min-corner->0,0; floor z=0)
       because we write one IDF per building                        [RULES G3]
    -> write output/middle_layer.json (the bridge to inspect)

Constructions/zones get wired into this same dict next; the writer reads only it.
"""

from __future__ import annotations

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

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG = os.path.dirname(_HERE)                       # citygml2idf/
OUTPUT_DIR = os.path.join(_PKG, "output")


def build_middle_layer(doc):
    """Parse every building into the middle-layer dict (metres, recentred)."""
    # 1. geometry + roles per building (points still in the file's CRS)
    buildings = []
    for b in xml_io.buildings(doc):
        lod_n, surfaces = building_surfaces.surfaces_of_building(doc, b)
        buildings.append({"id": b.get(GML_ID), "lod": lod_n, "surfaces": surfaces})

    # 2. reproject to metres only if the CRS is geographic (no-op when already UTM)
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
            s["area"] = round(rings.polygon_area(s["points"]), 3)   # metric, final
        bld["origin_offset"] = [float(ox), float(oy), float(oz)]

    middle = {
        "crs": {
            "srsName": xml_io.srs_name(doc),
            "epsg": src_epsg,
            "reprojected": transformer is not None,
        },
        "buildings": buildings,
    }
    # resolve each surface's construction (Excel-first waterfall) + materials,
    # tagging every surface with its construction name -> the complete middle layer.
    constructions.resolve_all(doc, middle)
    openings.resolve_windows(doc, middle)   # windows on exterior walls (gated by config.ENABLE_WINDOWS)
    zones.assign_zones(doc, middle)         # one E+ Zone per nrg3:ThermalZone (gated by FORCE_SINGLE_ZONE)
    return middle


def write_middle_layer(doc, out_path=None):
    """Build the middle layer and dump it to output/middle_layer.json."""
    middle = build_middle_layer(doc)
    out_path = out_path or os.path.join(OUTPUT_DIR, "middle_layer.json")
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(middle, f, indent=2)
    return middle, out_path


def _demo(path=None):
    doc = xml_io.CityGMLDoc(path or xml_io.DEFAULT_INPUT)
    middle, out_path = write_middle_layer(doc)
    c = middle["crs"]
    print(f"CRS: {c['srsName']}  epsg={c['epsg']}  reprojected={c['reprojected']}")
    for bld in middle["buildings"]:
        n = len(bld["surfaces"])
        total = round(sum(s["area"] for s in bld["surfaces"]), 1)
        print(f"  {bld['id']:<12} LOD{bld['lod']}  {n:>2} surfaces  envelope={total} m^2"
              f"  site_origin={[round(v, 1) for v in bld.get('origin_offset', [])]}")
    # peek: first surface of the first building, to confirm recentring (small coords)
    s0 = middle["buildings"][0]["surfaces"][0]
    print(f"  e.g. {s0['source_id']}: {s0['surface_type']}/{s0['boundary']} "
          f"area={s0['area']} pts[0]={s0['points'][0]}")
    print(f"  -> {out_path}")


if __name__ == "__main__":
    _demo(sys.argv[1] if len(sys.argv) > 1 else None)
