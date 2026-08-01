"""
 read ONE building's envelope surfaces, whatever its LoD.

Schema relationships decide which objects we read:
  * Energy ADE ThermalZone -> explicit `thermalBoundary` surfaces when present;
                              these are the zone surfaces EnergyPlus needs.
  * Building shell         -> otherwise the building's labeled `bldg:boundedBy`
                              thematic surfaces.
  * Solid fallback         -> if no thematic surfaces exist, read raw solid faces.

LoD is only used inside those objects to choose a valid geometry representation.

SCOPE: ONE `bldg:Building` = ONE IDF. `bldg:BuildingPart` is not supported — we read the Building
itself and nothing below it.

Either way we return ONE uniform list of surface dicts:
    {source_id, type_name, role, surface_type, boundary, points}
so zones / openings / constructions / writer never care what LoD the file was.

Kept deliberately small and reference-tolerant (surfaces may be inline OR an
`xlink`) Recentring to a
local origin happens later in model/reader.py, over the whole site; here the points
are raw (assumed metric — no CRS reprojection  # TODO later we should add CRS check but already wound OUTWARD.
"""

from __future__ import annotations

import sys
from enum import Enum

from ..citygml import xml_io
from ..citygml.xml_io import GML_ID, local_name
from ..geometry import rings, classify
from ..model.citygml_read import _child_text
from ..model.model import Surface
from . import surface_types

# LoD metadata is informational only. The parser still chooses geometry by schema
# path in surfaces_of_building(), but this detects the highest LoD present whether
# it is on the Building's own solid OR on its bldg:boundedBy / thermalBoundary
# surfaces, both of which are valid in CityGML/Energy ADE.
def detect_lod(doc, building):
    """Highest LoD present on the building (3, 2, 1, 0) or None; recorded for info."""
    for n in (3, 2, 1):
        if doc.children(building, "bldg", f"lod{n}Solid") or doc.children(building, "bldg", f"lod{n}MultiSurface"):
            return n
        if _holder_has_surface_lod(doc, building, n):
            return n
    if doc.children(building, "bldg", "lod0FootPrint") or doc.children(building, "bldg", "lod0RoofEdge"):
        return 0
    return None


def _lod_multisurface(doc, element, lod):
    """A surface's lodN MultiSurface geometry property: `bldg:` first, then `nrg3:` as a
    FALLBACK. Surface geometry normally sits on a bldg:BoundarySurface (bldg: namespace);
    a full-ADE nrg3:ThermalBoundary would carry it in nrg3:. We look at DIRECT children"""
    
    return (doc.children(element, "bldg", f"lod{lod}MultiSurface")
            or doc.children(element, "nrg", f"lod{lod}MultiSurface"))


def _holder_has_surface_lod(doc, holder, lod):
    """True when any shell/thermal boundary surface has lodNMultiSurface (bldg: or nrg3:).

    CityGML's building.xsd allows LoD geometry on BoundarySurface objects under
    bldg:boundedBy. Energy ADE's ThermalZoneType also allows thermalBoundary
    surfaces with their own LoD geometry. This keeps building['lod'] meaningful
    for both the normal thermalBoundary path and coincidesWithLodXHull path.
    """
    for boundary_property in doc.children(holder, "bldg", "boundedBy"):
        surf = doc.property_object(boundary_property)
        if surf is not None and _lod_multisurface(doc, surf, lod):
            return True
    for zone_property in doc.children(holder, "nrg", "thermalZone"):
        zone = doc.property_object(zone_property)
        if zone is None:
            continue
        for boundary_property in doc.children(zone, "nrg", "thermalBoundary"):
            surf = doc.property_object(boundary_property)
            if surf is not None and _lod_multisurface(doc, surf, lod):
                return True
    return False


# EVERY CityGML/ADE relationship is a PROPERTY wrapper holding an OBJECT — either nested inline
#     <bldg:boundedBy><bldg:WallSurface .../></bldg:boundedBy>
# or pointed at by reference
#     <bldg:boundedBy xlink:href="#wall_12"/>
# `doc.property_object(prop)` (xml_io) opens either form and returns the object. It is the ONE
# resolver used everywhere; there are no local aliases for it.

# BoundarySurface -> lod3MultiSurface/lod2MultiSurface -> gml:surfaceMember -> gml:Polygon -> posList
# Checks immediate lod{3,2}MultiSurface children (bldg: first, nrg3: fallback via
# _lod_multisurface) so it never grabs a window's ring or a device's nrg3 geometry.
def _surface_rings(doc, surf):
    """The exterior ring(s) of a boundary surface's own lodNMultiSurface (LoD3 then LoD2;
    bldg: namespace preferred, nrg3: as a fallback).

    THE GEOMETRY MAY BE SHARED BY REFERENCE at EITHER of two levels. Energy ADE §4.3.2 lets a
    thermal boundary that coincides with its thematic twin POINT AT that geometry instead of
    duplicating the coordinates — and the xlink can sit on either element:

      1. PROPERTY level   <bldg:lod2MultiSurface xlink:href="#MS_of_thematic_surface"/>
                          the property tag is EMPTY; the gml:MultiSurface lives elsewhere.
      2. MEMBER level     <bldg:lod2MultiSurface><gml:MultiSurface>
                              <gml:surfaceMember xlink:href="#polygon_of_thematic_surface"/>
      3. INLINE           the gml:MultiSurface is nested in the property, as usual.

    So RESOLVE the property into its geometry object first (property_object handles inline AND
    xlink.
    """
    # like: lod3MultiSurface -> MultiSurface -> surfaceMember -> Polygon -> posList
    for n in (3, 2):
        geometry_property = _lod_multisurface(doc, surf, n)
        if not geometry_property:
            continue
        geometry = doc.property_object(geometry_property[0])   # inline OR xlink -> the geometry
        if geometry is None:                                   # never drop a face in silence
            xml_io.warn(f"surface {surf.get(GML_ID)}: lod{n}MultiSurface carries no geometry "
                        f"(empty property or dangling xlink); no surface emitted")
            return []
        rings_out = []
        for member in doc.descendants(geometry, "gml", "surfaceMember"):
            poly = doc.property_object(member)                 # the member may itself be an xlink
            if poly is not None:
                ring = xml_io.read_pos_list(doc, poly)
                if ring:
                    rings_out.append(ring)
        if rings_out:
            return rings_out
        ring = xml_io.read_pos_list(doc, geometry)             # e.g. an xlink straight to a Polygon
        if ring:
            return [ring]
        xml_io.warn(f"surface {surf.get(GML_ID)}: lod{n}MultiSurface has no readable polygon; "
                    f"no surface emitted")
        return []
    return []


def _unique_ids(*ids):
    out = []
    for value in ids:
        if value and value not in out:
            out.append(value)
    return out



def _surface_records(type_name, sid, rings_list, contexts):
    """One parsed record per surface.
    # TODO (KNOWN LIMITATION )
    we assume ONE polygon per BoundarySurface.
    A gml:MultiSurface may legally hold SEVERAL surfaceMember polygons (e.g. a gabled roof
    modelled as ONE RoofSurface with two sloped planes). `[:1]` keeps only the FIRST and
    DROPS the rest
    """
    for ring in rings_list[:1]:                  # [:1] -> first polygon only; see limitation above
        yield (type_name, sid, ring, _unique_ids(sid, *contexts), sid)


def _thermal_zone_ids(doc, building):
    ids = []
    for zone_property in doc.children(building, "nrg", "thermalZone"):
        zone = doc.property_object(zone_property)
        if zone is not None:
            ids.append(zone.get(GML_ID))
    return [value for value in ids if value]


# The construction owner cascade (constructions.py) walks OUTWARD from a surface:
#       surface -> ThermalZone -> Building
# This supplies the outer rungs. It matters in LoD1: a raw gml:Polygon is not a CityObject and
# cannot own a construction, so the file puts it on the ZONE (ADE Table 2, case 1.1). The zone
# rung is used only when the building has exactly ONE zone, so we never guess.
def _fallback_context_ids(doc, building):
    """Construction fallback owners, nearest first, for a surface with no construction of its own."""
    zone_ids = _thermal_zone_ids(doc, building)
    zone_id = zone_ids[0] if len(zone_ids) == 1 else None
    return _unique_ids(zone_id, building.get(GML_ID))


# if ThermalZone.coincidesWithLod2Hull or coincidesWithLod3Hull is true, the
# thermal zone is exactly the normal CityGML building hull. In that case the GML
# must not duplicate thermalBoundary objects; we read bldg:boundedBy surfaces.

#Building -> bldg:boundedBy -> WallSurface/RoofSurface/GroundSurface
def _labeled_surfaces(doc, building):
    """Building shell path: each bldg:boundedBy BoundarySurface."""
    out = []
    contexts = _fallback_context_ids(doc, building)
    for bb in doc.children(building, "bldg", "boundedBy"):
        surf = doc.property_object(bb)
        if surf is None:
            continue
        sid = surf.get(GML_ID)
        out.extend(_surface_records(local_name(surf), sid, _surface_rings(doc, surf), contexts))
    return out


# _child_text lives in model/citygml_read.py — ONE implementation for the whole package
# (it guards against a missing parent and strips the text; this file used to carry a second,
# unguarded copy of the same function).


# Schema hook for the two ADE boolean flags on nrg3:ThermalZone. Either true
# means "do not read thermalBoundary for this zone; reuse the building hull".
def _coincides_with_hull(doc, zone):
    for flag in ("coincidesWithLod2Hull", "coincidesWithLod3Hull"):
        text = _child_text(doc, zone, "nrg", flag)
        if text and text.strip().lower() == "true":
            return True
    return False


# Normal LoD2/LoD3 ADE path: Building -> ThermalZone -> thermalBoundary -> BoundarySurface
# This is used only when the zone does NOT declare coincidesWithLodXHull=true.
# When the flag is true, _labeled_surfaces() reads the normal building shell.
def _thermal_boundary_surfaces(doc, building):
    """Energy ADE path: explicit zone boundary surfaces under ThermalZone.

    thermalBoundary has the same CityGML property pattern as boundedBy: the
    BoundarySurface may be inline or referenced by xlink. Zones that declare
    coincidesWithLodXHull use the building shell instead, so we skip them here.
    """
    out = []
    seen = set()
    for zone_property in doc.children(building, "nrg", "thermalZone"):
        zone = doc.property_object(zone_property)
        if zone is None:
            continue
        if _coincides_with_hull(doc, zone):
            continue
        contexts = _unique_ids(zone.get(GML_ID), building.get(GML_ID))
        for boundary_property in doc.children(zone, "nrg", "thermalBoundary"):
            surf = doc.property_object(boundary_property)
            if surf is None:
                continue
            sid = surf.get(GML_ID)
            key = sid or id(surf)
            # prevent from duplication
            if key in seen:
                continue
            seen.add(key)
            out.extend(_surface_records(local_name(surf), sid, _surface_rings(doc, surf), contexts))
    return out


def _geometry_property_objects(doc, building, lod):
    for local in (f"lod{lod}Solid", f"lod{lod}MultiSurface"):
        for prop in doc.children(building, "bldg", local):
            geom = doc.property_object(prop)
            if geom is not None:
                yield geom

# Building -> lod1Solid/lod2Solid/lodXMultiSurface -> surfaceMember -> Polygon -> posList
# Raw-solid fallback, mainly LoD1: classify selected solid faces by geometry
# normal and attach ThermalZone/Building context ids for construction fallback.
def _solid_faces(doc, building, lod):
    """Raw selected-LoD geometry fallback.

    Reads only the chosen bldg:lod{n}Solid / lod{n}MultiSurface containers ON THE BUILDING.
    Deliberately NOT any descendant geometry — that would sweep in lod0FootPrint, a ThermalZone's
    own solid, a UsageZone solid, etc.
    """
    out = []
    if lod is None:
        return out
    contexts = _fallback_context_ids(doc, building)
    for geom in _geometry_property_objects(doc, building, lod):
        for sm in doc.descendants(geom, "gml", "surfaceMember"):
            poly = doc.property_object(sm)
            if poly is not None:
                sid = poly.get(GML_ID)
                out.append((None, sid, xml_io.read_pos_list(doc, poly), contexts, sid))
    return out


class SurfacePath(Enum):
    """WHICH source a building's surfaces came from (recorded in the trace).

    Priority = most-detailed first. NOTE: "coincides-with-hull" is NOT a separate
    path — a hull-coincident zone exposes no thermalBoundary, so it simply falls
    through to CITYGML_BUILDING_SHELL.
    """
    ENERGY_ADE_BOUNDARIES = "energy_ade_boundaries"    # nrg3:ThermalZone -> thermalBoundary (RICH)
    CITYGML_BUILDING_SHELL = "citygml_building_shell"  # bldg:boundedBy thematic surfaces (RICH)
    RAW_SOLID_FALLBACK = "raw_solid_fallback"          # classify lodNSolid faces by normal (POOR)
    NONE = "none"                                      # no usable envelope (e.g. LoD0 footprint only)


# Geometry selection cascade — pick ONE source, most-detailed first:
#   1. explicit ADE thermalBoundary surfaces (coincident-hull zones expose none);
#   2. CityGML bldg:boundedBy shell surfaces (also the coincident-hull case);
#   3. raw selected-LoD solid faces, mainly the LoD1 fallback;
#   otherwise NONE — nothing usable (e.g. a LoD0 footprint-only building).
def select_surface_path(doc, building, lod):
    """Return (SurfacePath, raw_records) for one building. NONE + [] when no source
    yields surfaces, so the caller can still trace the building yet emit no IDF."""
    thermal = _thermal_boundary_surfaces(doc, building) #  can be used: LOD2 - LOD3
    if thermal:
        return SurfacePath.ENERGY_ADE_BOUNDARIES, thermal
    shell = _labeled_surfaces(doc, building) # LOD2 - LOD3
    if shell:
        return SurfacePath.CITYGML_BUILDING_SHELL, shell
    solid = _solid_faces(doc, building, lod) #LOD1
    if solid:
        return SurfacePath.RAW_SOLID_FALLBACK, solid
    return SurfacePath.NONE, []


def process_surfaces(raw):
    """Turn raw (type_name, sid, ring, …) records into the uniform surface list:
    orient each face OUTWARD, give it a role, drop degenerate/unmapped faces (warned).
    PURE geometry/semantics — no XML, no doc."""
    # Interior reference point = centroid of ALL this building's vertices, used to
    # orient every face's normal OUTWARD (we never trust the file's winding).
    all_pts = [p for (_, _, ring, _, _) in raw for p in rings.drop_closing_point(ring)]
    interior = rings.centroid(all_pts) if all_pts else None   # AVERAGE of all the building's corners

    surfaces = []
    for type_name, sid, ring, construction_context_ids, source_gml_id in raw:
        if interior is None or len(rings.drop_closing_point(ring)) < 3:  # not a real polygon -> ignore
            xml_io.warn(f"surface {sid}: fewer than 3 points; skipped")
            continue
        oriented, normal = rings.orient_outward(ring, interior) #  # flip the ring if it points inward

        if type_name is None:                      # LOD1 -> role from geometry
            rule = surface_types.rule_for_role(classify.classify_by_normal(normal))
        else:                                      # LOD2/3 -> role from the labeled type
            rule = surface_types.rule_for_type(type_name)
            if rule is None:                       # labeled but UNMAPPED: never DROP the
                # geometry and never blind-guess "wall" — classify it by the outward
                # normal (like LoD1). zones.py still fixes interzone boundaries.
                rule = surface_types.rule_for_role(classify.classify_by_normal(normal))
                xml_io.warn(f"surface {sid}: type '{type_name}' not mapped; "
                            f"classified by geometry as '{rule.role if rule else 'unknown'}'")
        if rule is None:                           # truly unresolvable -> skip (never crash)
            xml_io.warn(f"surface {sid}: could not resolve type '{type_name}'; skipped")
            continue

        # FloorOrCeiling is resolved to a concrete E+ keyword by the normal's z
        surface_type = surface_types.resolve_floor_ceiling(rule.surface_type, normal[2])
        rule_source = ("CityGML/ADE surface type" if type_name
                       else "geometry normal classification")
        surfaces.append(Surface(
            source_id=sid,
            source_gml_id=source_gml_id,
            type_name=type_name or "classified",
            role=rule.role,
            surface_type=surface_type,
            boundary=rule.boundary,
            points=[list(p) for p in oriented],
            construction_context_ids=construction_context_ids,
            provenance={
                "role": f"{rule.role} ({rule_source}"
                        + (f" '{type_name}'" if type_name else "") + ")",
                "surface_type": f"{surface_type} (outward normal z={normal[2]:.3f})",
                "boundary": rule.boundary,
            },
        ))
    return surfaces


def surfaces_of_building(doc, building):
    """Return (lod, path, surfaces) for one building as the uniform surface list.

    `path` (SurfacePath) records WHICH source was used — kept on the Building for audit.
    A NONE path (no usable envelope, e.g. LoD0) yields an empty surface list: the
    building stays in the Model but the writer skips it, so it never emits a
    zone-with-no-surfaces IDF.
    """
    lod = detect_lod(doc, building)
    path, raw = select_surface_path(doc, building, lod)
    if path is SurfacePath.NONE:
        xml_io.warn(f"building {building.get(GML_ID)}: no usable envelope surfaces "
                    f"(LoD0 footprint only / no thermalBoundary / boundedBy / solid); "
                    f"kept in model, no IDF written")
    return lod, path, process_surfaces(raw)

# local test
def _demo(path=None):
    doc = xml_io.CityGMLDoc(path)
    for b in xml_io.buildings(doc):
        lod, path_used, surfs = surfaces_of_building(doc, b)
        print(f"{b.get(GML_ID)}  LOD{lod}  [{path_used.value}]  {len(surfs)} surfaces")
        for s in surfs:
            area = rings.polygon_area(s.points)
            print(f"   {s.source_id:<18} {s.type_name:<24} {s.role:<18}"
                  f" {s.surface_type:<8} {s.boundary:<10} {len(s.points)}pts  area={area:6.1f}")


if __name__ == "__main__":
    _demo(sys.argv[1] if len(sys.argv) > 1 else None)
