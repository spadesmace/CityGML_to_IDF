"""
model/zones.py — thermal zones (the G12 / G13 rules). PRESENCE-BASED (the ADE object
is primary): one E+ Zone per nrg3:ThermalZone; one implicit zone only when the file
declares no ThermalZone.

THE ENERGY ADE OBJECT IS PRIMARY (presence-driven, NOT LOD-driven): the zone list comes
from `nrg3:ThermalZone`, not from the geometric LOD. Each `ThermalZone` -> one EnergyPlus
`Zone`. The bldg geometry we already extracted is the SHAPE; a zone OWNS a surface when its
`nrg3:thermalBoundary` xlinks to that surface's `gml:id`. (In this encoding `thermalBoundary`
points straight at the bldg surface; a nested `nrg3:ThermalBoundary` object, if a file uses
one, is followed the same way as a best effort.)

A shared surface's boundary = WHO IS ON THE OTHER SIDE, by ZONE COUNT (G12), never the
type name:
  * referenced by TWO modelled zones -> interzone, written as an EXPLICIT reciprocal
       Surface PAIR: the face stays in zone A (Outside_Boundary_Condition = Surface), and a
       reversed twin is added to zone B (reversed winding, Floor<->Ceiling flipped, mirror
       construction) pointing back. Both zones end up fully enclosed with a real floor.
  * referenced by ONE zone           -> its normal exterior boundary (Outdoors / Ground / ...).
A zone with `nrg3:coincidesWithLodXHull = true` OWNS THE WHOLE BUILDING SHELL (G13): its
partial `thermalBoundary` list is ignored and it takes every bldg surface (B2's case).

No `ThermalZone` in the file -> ONE implicit zone = the whole
building (the LoD1 fallback). `nrg3:volume` -> the E+ Zone Volume when present,
otherwise EnergyPlus autocalculates it from the (now enclosing) surfaces.

Sources: RULES_code.md G12 (interzone by zone count; explicit Surface pair = the documented
upgrade over interim BC=Zone) + G13 (LoD ThermalZone modelling); Energy ADE 3.0 spec §4.3.1
(ThermalZone per LoD, coincidesWithLodXHull) + §4.3.2 (thermal boundaries); E+ IDD
BuildingSurface:Detailed A6/A7 (Outside Boundary Condition + Object), Zone (Volume).
"""

from __future__ import annotations

import sys

import numpy as np

from ..citygml import xml_io
from ..citygml.xml_io import GML_ID, warn
from ..geometry import rings
from .constructions import _child_text as child_text_value, _num as to_number


def thermal_zones(doc, building_element):
    # WHAT: every nrg3:ThermalZone under a building, by namespace URI (presence-driven;
    #       [] when the file has none -> caller falls back to one implicit zone).
    # REF : "ADE object PRIMARY" decision + RULES G13 / ADE spec §4.3.1 (ThermalZone).
    if building_element is None:
        return []
    return doc.descendants(building_element, "nrg", "ThermalZone")


def zone_volume_with_trace(doc, zone_element):
    # WHAT: nrg3:volume -> QualifiedVolume/value (m3); None -> E+ autocalculates.
    # REF : ADE QualifiedVolume; feeds E+ IDD Zone "Volume" field (else autocalculate).
    volume_property = doc.children(zone_element, "nrg", "volume")
    if not volume_property:
        return None, {"value": None, "unit": "m3", "source": "autocalculate",
                      "reason": "nrg3:volume not provided by CityGML"}
    value_elements = doc.descendants(volume_property[0], "nrg", "value")
    if not value_elements:
        return None, {"value": None, "unit": "m3", "source": "autocalculate",
                      "reason": "nrg3:volume has no nrg3:value"}
    value_element = value_elements[0]
    raw = to_number(value_element.text)
    uom = (value_element.get("uom") or "").strip()
    return raw, {"raw": raw, "raw_uom": uom or None,
                 "value": raw, "unit": "m3", "source": "citygml",
                 "field": "nrg3:volume/nrg3:QualifiedVolume/nrg3:value",
                 "conversion": "direct; expected m3"}


def zone_volume(doc, zone_element):
    return zone_volume_with_trace(doc, zone_element)[0]


def coincides_with_hull(doc, zone_element):
    # WHAT: True if the zone declares it fills the building's LoD2 or LoD3 hull, so it
    #       owns the WHOLE shell and its partial thermalBoundary list is ignored.
    # REF :   ADE spec §4.3.1 (nrg3:coincidesWithLodXHull).
    # XSD : Energy_ADE_3.0_beta7.xsd defines both booleans on ThermalZoneType.
    # SPEC: LoD2 special case 5.1 and LoD3 special case 6.1 reuse the normal
    #       CityGML thematic surfaces/openings instead of duplicate thermal ones.
    for flag in ("coincidesWithLod2Hull", "coincidesWithLod3Hull"):
        text = child_text_value(doc, zone_element, "nrg", flag)
        if text and text.strip().lower() == "true":
            return True
    return False


def boundary_surface_ids(doc, zone_element):
    # WHAT: the bldg surface ids a zone owns = the targets of its nrg3:thermalBoundary
    #       xlinks (#id); falls back to a nested ThermalBoundary object's id if inlined.
    # REF : the zone<->surface link, ADE spec §4.3.2; golden rule (trust explicit xlinks).
    surface_ids = []
    for boundary_property in doc.children(zone_element, "nrg", "thermalBoundary"):
        boundary_surface = doc.property_object(boundary_property)
        if boundary_surface is not None and boundary_surface.get(GML_ID):
            surface_ids.append(boundary_surface.get(GML_ID))
    return surface_ids


def reversed_construction(construction_name, middle):
    # WHAT: name of a layer-REVERSED twin of a construction, so an interzone partner
    #       mirrors the original; single-layer constructions are symmetric -> reuse as-is.
    # REF : E+ wants interzone surfaces to carry mirror constructions (RULES C / G12 upgrade).
    layers = middle.get("constructions", {}).get(construction_name, {}).get("layers", [])
    if len(layers) <= 1:
        return construction_name
    reversed_name = construction_name + "_Rev"
    original = middle.get("constructions", {}).get(construction_name, {})
    middle["constructions"].setdefault(reversed_name,
                                       {"source": "reversed",
                                        "layers": list(reversed(layers)),
                                        "layer_order": original.get("layer_order", "inside_to_outside")})
    return reversed_name


def make_partner(surface, partner_zone_name, partner_name, middle):
    # WHAT: the reciprocal twin of an interzone surface for the OTHER zone — reversed
    #       winding (normal flips), Floor<->Ceiling flipped, mirror construction, and
    #       Outside_Boundary_Condition=Surface pointing back at the original.
    # REF : RULES G12 upgrade (explicit Surface pair); E+ IDD A6=Surface / A7=Object.
    flipped_type = {"Floor": "Ceiling", "Ceiling": "Floor"}.get(surface["surface_type"],
                                                                surface["surface_type"])
    return {
        "source_id": partner_name,
        "type_name": surface.get("type_name", "interzone"),
        "role": surface.get("role"),
        "surface_type": flipped_type,
        "boundary": "Surface",
        "boundary_object": surface["source_id"],
        "construction": reversed_construction(surface["construction"], middle),
        "zone": partner_zone_name,
        "points": [list(point) for point in reversed(surface["points"])],
        "area": surface.get("area"),
        "zone_trace": {"assigned_zone": partner_zone_name,
                       "boundary": "Surface",
                       "source": "generated_interzone_partner",
                       "paired_with": surface["source_id"]},
    }


def _single_zone(building):
    # WHAT: one implicit E+ Zone = the whole building; every surface keeps its own
    #       exterior boundary. Used when there is no ThermalZone in the file.
    # REF : RULES G13 (LoD1 fallback) + config flag (Stages 1-2, the current writer path).
    zone_name = f"{building['id']}_Zone"
    building["zones"] = [{"name": zone_name, "volume": None,
                          "trace": {"name": {"value": zone_name, "source": "implicit"},
                                    "volume": {"value": None, "unit": "m3",
                                               "source": "autocalculate",
                                               "reason": "no nrg3:ThermalZone in CityGML"}}}]
    for surface in building["surfaces"]:
        surface["zone"] = zone_name
        surface["boundary_object"] = ""
        surface["zone_trace"] = {"assigned_zone": zone_name,
                                 "source": "implicit_single_zone",
                                 "owner_count": 1}


def assign_zones(doc, middle):
    # WHAT: tag every surface with its `zone` + boundary and add `building['zones']`.
    #       Pass 1: each zone's owned surface-id set (hull -> whole shell, G13).
    #       Pass 2: by HOW MANY zones own a surface -> exterior (1) or an explicit
    #       interzone Surface pair (2). The writer then emits one Zone per entry.
    # REF : RULES G12 (interzone by ZONE COUNT) + G13 (hull); E+ IDD A6/A7.
    for building in middle["buildings"]:
        surfaces = building["surfaces"]
        building_surface_ids = {surface["source_id"] for surface in surfaces}
        source_to_surface_ids = {}
        for surface in surfaces:
            source_to_surface_ids.setdefault(surface["source_id"], set()).add(surface["source_id"])
            source_to_surface_ids.setdefault(surface.get("source_gml_id") or surface["source_id"], set()).add(surface["source_id"])

        zone_elements = thermal_zones(doc, doc.get_by_id(building["id"]))
        if not zone_elements:
            _single_zone(building)
            continue

        # pass 1: resolve each ThermalZone's OWNED surface-id set (hull -> whole shell)
        zones = []
        for zone_element in zone_elements:
            name = zone_element.get(GML_ID) or f"{building['id']}_Zone{len(zones) + 1}"
            volume, volume_trace = zone_volume_with_trace(doc, zone_element)
            coincides = coincides_with_hull(doc, zone_element)
            referenced_ids = []
            if coincides:
                owned_ids = set(building_surface_ids)  # the zone OWNS THE WHOLE SHELL
                ownership_source = "coincidesWithLodXHull"
            else:
                owned_ids = set()
                referenced_ids = boundary_surface_ids(doc, zone_element)
                for sid in referenced_ids:
                    owned_ids.update(source_to_surface_ids.get(sid, set()))
                ownership_source = "nrg3:thermalBoundary"
            zones.append({"name": name, "volume": volume, "ids": owned_ids,
                          "trace": {"name": {"raw": zone_element.get(GML_ID),
                                             "value": name,
                                             "source": "ThermalZone gml:id"},
                                    "volume": volume_trace,
                                    "ownership": {"source": ownership_source,
                                                  "referenced_surface_ids": referenced_ids,
                                                  "owned_surface_ids": sorted(owned_ids)}}})
        building["zones"] = [{"name": zone["name"], "volume": zone["volume"],
                              "trace": zone["trace"]} for zone in zones]

        # zone centroid (orientation-independent) for re-orienting interzone faces
        surfaces_by_id = {surface["source_id"]: surface for surface in surfaces}

        def zone_centroid(zone):
            zone_points = [point for sid in zone["ids"] if sid in surfaces_by_id
                           for point in surfaces_by_id[sid]["points"]]
            return rings.centroid(zone_points) if zone_points else np.zeros(3)

        # pass 2: boundary of each surface by HOW MANY zones own it (G12)
        partner_surfaces = []
        for surface in surfaces:
            owners = [zone for zone in zones if surface["source_id"] in zone["ids"]]
            if len(owners) >= 2:                                 # interzone -> explicit Surface pair
                owner_zone, partner_zone = owners[0], owners[1]
                # re-orient the face outward from its OWNER zone so Floor/Ceiling is correct
                oriented, normal = rings.orient_outward(surface["points"], zone_centroid(owner_zone))
                surface["points"] = [list(point) for point in oriented]
                if surface["surface_type"] in ("Floor", "Ceiling"):
                    surface["surface_type"] = "Floor" if normal[2] < 0 else "Ceiling"
                surface["zone"] = owner_zone["name"]
                surface["boundary"] = "Surface"
                partner_name = surface["source_id"] + "_pair"
                surface["boundary_object"] = partner_name
                surface["zone_trace"] = {"assigned_zone": owner_zone["name"],
                                         "owner_count": len(owners),
                                         "boundary": "Surface",
                                         "paired_zone": partner_zone["name"],
                                         "paired_surface": partner_name,
                                         "source": "shared_by_multiple_zones"}
                partner_surfaces.append(make_partner(surface, partner_zone["name"], partner_name, middle))
                if len(owners) > 2:
                    warn(f"surface {surface['source_id']} shared by {len(owners)} zones; using first two")
            elif len(owners) == 1:                               # exterior -> keep type boundary
                surface["zone"] = owners[0]["name"]
                surface["boundary_object"] = ""
                surface["zone_trace"] = {"assigned_zone": owners[0]["name"],
                                         "owner_count": 1,
                                         "boundary": surface["boundary"],
                                         "source": "single ThermalZone owns surface"}
            else:                                                # orphan -> never drop geometry
                warn(f"surface {surface['source_id']} in no ThermalZone; placed in {zones[0]['name']}")
                surface["zone"] = zones[0]["name"]
                surface["boundary_object"] = ""
                surface["zone_trace"] = {"assigned_zone": zones[0]["name"],
                                         "owner_count": 0,
                                         "boundary": surface["boundary"],
                                         "source": "orphan_fallback"}
        surfaces.extend(partner_surfaces)                        # add the reciprocal twins
    return middle


def _demo(path=None):
    from .reader import build_middle_layer
    doc = xml_io.CityGMLDoc(path)
    middle = build_middle_layer(doc)            # build_middle_layer already calls assign_zones
    for building in middle["buildings"]:
        zone_names = [zone["name"] for zone in building.get("zones", [])]
        print(f"  {building['id']}: {len(zone_names)} zone(s) {zone_names}")
        for surface in building["surfaces"]:
            if surface.get("boundary") == "Surface":
                print(f"      interzone {surface['source_id']:<24} {surface['surface_type']:<8}"
                      f" zone={surface['zone']:<22} <-> {surface['boundary_object']}")


if __name__ == "__main__":
    _demo(sys.argv[1] if len(sys.argv) > 1 else None)
