"""
Build the typed middle layer Model from CityGML parser output.

The reader assembles buildings, zones, surfaces, windows, constructions, and
materials into one Model. Objects also carry provenance for audit/teaching;
IDF generation reads only the fields it needs.
"""

from __future__ import annotations

import json
import os
import re
import sys

from ..citygml import xml_io
from ..citygml.xml_io import GML_ID
from ..geometry import rings
from ..semantics import building_surfaces
from . import adjacency
from . import constructions
from . import openings
from . import zones
from .model import Building, Model, to_jsonable

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG = os.path.dirname(_HERE)                       # citygml2idf/
OUTPUT_DIR = os.path.join(_PKG, "output")


def _parse_epsg(srs_name):
    """Extract a trailing EPSG code from srsName for audit only."""
    if not srs_name:
        return None
    match = re.search(r"(\d+)\s*$", srs_name.strip())
    return int(match.group(1)) if match else None

# One global store, parsed once
def build_middle_layer(doc, detailed_interior=False):
    """Parse every building into the ONE typed middle layer (model.Model).

    Parameters
    ----------
    doc : xml_io.CityGMLDoc
        The parsed CityGML file.
    detailed_interior : bool, optional
        False (default) = FAST indoor model (interior faces Adiabatic); True = model
        interior heat transfer (model/zones.py, boundary rung 0).

    Returns
    -------
    Model
        Every building, each object with its data plus a flat `provenance` map.

    Warns
    -----
    ONCE per building that gets no IDF, with the reason: no readable surface, or dropped by
    model/zones.py (``building.provenance["skipped"]``). Such a building stays in the Model
    for the audit trail; the writer skips it because it has no surfaces.
    """
    # 1. geometry + roles per building (points still in the file's CRS)
    buildings = []
    for b in xml_io.buildings(doc):
        lod_n, surface_path, surfaces = building_surfaces.surfaces_of_building(doc, b)
        buildings.append(Building(id=b.get(GML_ID), lod=lod_n,
                                  surface_path=surface_path.value, surfaces=surfaces))

    # 2. Assume input coordinates are already metric; record srsName/EPSG for audit.
    src_epsg = _parse_epsg(xml_io.srs_name(doc))
    for bld in buildings:
        for s in bld.surfaces:
            s.points = [(float(x), float(y), float(z)) for (x, y, z) in s.points]

    # 3. recentre EACH building to its own origin (one IDF per building) and
    #    record the shift so we still know the building's true site position.
    for bld in buildings:
        rings_m = [s.points for s in bld.surfaces]
        if not rings_m:
            continue
        ox, oy, oz = rings.min_corner(rings_m)
        for s in bld.surfaces:
            s.points = [[float(x - ox), float(y - oy), float(z - oz)]
                        for (x, y, z) in s.points]
            s.area = round(rings.polygon_area(s.points), 3)  # computed from the polygon points
            s.provenance["points"] = ("gml:posList (assumed metric) -> file winding kept "
                                      "-> recentre to building origin "
                                      f"{[round(float(ox), 1), round(float(oy), 1), round(float(oz), 1)]}")
            s.provenance["area"] = f"{s.area} m2 (derived from recentred points)"
        bld.origin_offset = [float(ox), float(oy), float(oz)]

    model = Model(crs={"srsName": xml_io.srs_name(doc), "epsg": src_epsg,
                       "units": "assumed_metric"},
                  buildings=buildings)

    # These modules enrich the same Model in place (parser concerns). adjacency reads the
    # schema-native FACTS (isAdiabatic / relatedTo-adjacentTo) onto each Surface; zones then
    # turns zone ownership + those facts into the EnergyPlus boundary. 
    # NOTE interzone windows (not modelled): openings runs BEFORE zones, so a window is attached
    constructions.resolve_all(doc, model)
    openings.resolve_windows(doc, model)
    adjacency.attach_facts(doc, model)
    zones.assign_zones(doc, model, detailed_interior=detailed_interior)

    for bld in model.buildings:                       # the ONE warning per building without IDF
        if not bld.surfaces:
            reason = bld.provenance.setdefault(
                "skipped", f"no readable surface (surface_path={bld.surface_path})")
            xml_io.warn(f"building {bld.id}: no IDF written; {reason}")
    return model


def _demo(path=None):
    doc = xml_io.CityGMLDoc(path)
    model = build_middle_layer(doc)
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    out_path = os.path.join(OUTPUT_DIR, "middle_layer.json")
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(model, f, indent=2, default=to_jsonable)

    c = model.crs
    print(f"CRS: {c['srsName']}  epsg={c['epsg']}  units={c['units']}")
    for bld in model.buildings:
        n = len(bld.surfaces)
        total = round(sum(s.area for s in bld.surfaces), 1)
        print(f"  {bld.id:<12} LOD{bld.lod}  {n:>2} surfaces  envelope={total} m^2"
              f"  site_origin={[round(v, 1) for v in (bld.origin_offset or [])]}")
    if model.buildings and model.buildings[0].surfaces:
        s0 = model.buildings[0].surfaces[0]
        print(f"  e.g. {s0.source_id}: {s0.surface_type}/{s0.boundary} "
              f"area={s0.area} pts[0]={s0.points[0]}")
    print(f"  model -> {out_path}")


if __name__ == "__main__":
    _demo(sys.argv[1] if len(sys.argv) > 1 else None)
