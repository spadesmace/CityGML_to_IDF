"""
model/reader.py — builds the ONE middle layer (model.Model) from a parsed CityGML file.

build_middle_layer runs the steps in this order; each changes the same Model in place:
  1. building_surfaces.surfaces_of_building  each Building's ONE LoD and its Surface list
  2. lower to the ground                     each building lowered so its lowest point is z = 0
                                             (x, y kept; Building.ground_height keeps the drop)
  3. constructions.resolve_all               every surface's construction and materials
  4. adjacency.attach_facts                  isAdiabatic / relatedTo, read from the file
  5. zones.assign_zones                      zones, ownership, boundaries
  6. zone_physics.attach_zone_physics        a zone's own values (infiltration)
  7. openings.resolve_windows                windows LAST: only on a surface whose FINAL
                                             boundary is Outdoors
Every object keeps a flat `provenance` map (the audit trail); the writer reads only the data
fields. Coordinates are assumed metric; srsName / EPSG are kept for the record only.
"""

from __future__ import annotations

import re

from ..citygml import xml_io
from ..citygml.xml_io import GML_ID
from ..geometry import rings
from ..semantics import building_surfaces
from . import adjacency
from . import constructions
from . import openings
from . import zone_physics
from . import zones
from .model import Building, Model


def _parse_epsg(srs_name):
    """The trailing EPSG code of srsName, for the record only; None when there is none."""
    if not srs_name:
        return None
    match = re.search(r"(\d+)\s*$", srs_name.strip())
    if match is None:
        return None
    return int(match.group(1))


# the ONE middle layer: every building parsed once
def build_middle_layer(doc, detailed_interior=False):
    """Parse every building into the ONE typed middle layer (model.Model).

    Parameters
    ----------
    doc : xml_io.CityGMLDoc
        The parsed CityGML file.
    detailed_interior : bool, optional
        False (default) = FAST indoor model (interior faces Adiabatic); True = model
        interior heat transfer (model/zones.py, boundary rung 1).

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
    # 1. each building's ONE LoD and its surfaces (points still in the file's coordinates)
    buildings = []
    for building_element in xml_io.buildings(doc):
        lod_n, surface_path, surfaces = building_surfaces.surfaces_of_building(doc, building_element)
        buildings.append(Building(id=building_element.get(GML_ID), lod=lod_n,
                                  surface_path=surface_path.value, surfaces=surfaces))

    # 2. lower EACH building so its lowest point is at z = 0; x and y stay as in the file.
    #    NOTE why z: EnergyPlus reads z as the height above the ground. It computes the outdoor
    #    air temperature and the wind speed at the height of every surface (IDD
    #    Site:HeightVariation: when the object is absent, "the default model for temperature
    #    dependence on height is used" (Air Temperature Gradient Coefficient 0.0065 K/m) and the
    #    wind follows the Building Terrain; I/O Reference: "calculated at the height above ground
    #    of the surface centroid"). A file's z is usually the height above sea level, which would
    #    lift the building that high into the air. The drop is kept in Building.ground_height.
    for building in buildings:
        surface_rings = [surface.points for surface in building.surfaces]
        if not surface_rings:
            continue
        ground_height = rings.lowest_z(surface_rings)
        for surface in building.surfaces:
            surface.points = [[float(x), float(y), float(z - ground_height)]
                              for (x, y, z) in surface.points]
            surface.area = round(rings.polygon_area(surface.points), 3)  # from the polygon points
            surface.provenance["points"] = ("gml:posList (assumed metric) -> file winding kept "
                                            f"-> lowered by the ground height {round(ground_height, 3)} m")
            surface.provenance["area"] = f"{surface.area} m2 (derived from the points)"
        building.ground_height = ground_height

    srs_name = xml_io.srs_name(doc)              # coordinates assumed metric; kept for the record
    model = Model(crs={"srsName": srs_name, "epsg": _parse_epsg(srs_name),
                       "units": "assumed_metric"},
                  buildings=buildings)

    constructions.resolve_all(doc, model)                                  # 3.
    adjacency.attach_facts(doc, model)                                     # 4.
    zones.assign_zones(doc, model, detailed_interior=detailed_interior)    # 5.
    zone_physics.attach_zone_physics(doc, model)                           # 6.
    openings.resolve_windows(doc, model)                                   # 7. LAST: final boundaries

    for building in model.buildings:                  # the ONE warning per building without IDF
        if not building.surfaces:
            reason = building.provenance.setdefault(
                "skipped", f"no readable surface (surface_path={building.surface_path})")
            xml_io.warn(f"building {building.id}: no IDF written; {reason}")
    return model
