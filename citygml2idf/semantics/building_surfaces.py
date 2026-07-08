"""
semantics/building_surfaces.py - read ONE building's envelope surfaces, whatever its LoD.

Schema relationships decide which objects we read:
  * Energy ADE ThermalZone -> explicit `thermalBoundary` surfaces when present;
                              these are the zone surfaces EnergyPlus needs.
  * Building shell         -> otherwise the building's labeled `bldg:boundedBy`
                              thematic surfaces.
  * Solid fallback         -> if no thematic surfaces exist, read raw solid faces.

LoD is only used inside those objects to choose a valid geometry representation.
CityGML BuildingParts are valid _AbstractBuilding objects, so we include them
recursively inside their parent Building and write one combined IDF building.

Either way we return ONE uniform list of surface dicts:
    {source_id, type_name, role, surface_type, boundary, points}
so zones / openings / constructions / writer never care what LoD the file was.

Kept deliberately small and reference-tolerant (surfaces may be inline OR an
`xlink`), so it works for any valid CityGML, not just this sample. Recentring to a
local origin happens later in model/reader.py, over the whole site; here the points
are raw (assumed metric — no CRS reprojection) but already wound OUTWARD.
"""

from __future__ import annotations

import sys
from enum import Enum

from ..citygml import xml_io
from ..citygml.xml_io import GML_ID, local_name
from ..geometry import rings, classify
from ..model.model import Surface
from . import surface_types

# LoD metadata is informational only. The parser still chooses geometry by schema
# path in surfaces_of_building(), but this detects the highest LoD present whether
# it is on Building/BuildingPart solids OR on bldg:boundedBy / thermalBoundary
# surfaces, both of which are valid in CityGML/Energy ADE.
def detect_lod(doc, building):
    """Highest LoD present on the building (3, 2, 1, 0) or None; recorded for info."""
    for n in (3, 2, 1):
        for holder in _building_and_parts(doc, building):
            if doc.children(holder, "bldg", f"lod{n}Solid") or doc.children(holder, "bldg", f"lod{n}MultiSurface"):
                return n
            if _holder_has_surface_lod(doc, holder, n):
                return n
    for holder in _building_and_parts(doc, building):
        if doc.children(holder, "bldg", "lod0FootPrint") or doc.children(holder, "bldg", "lod0RoofEdge"):
            return 0
    return None


def _holder_has_surface_lod(doc, holder, lod):
    """True when any shell/thermal boundary surface has lodNMultiSurface.

    CityGML's building.xsd allows LoD geometry on BoundarySurface objects under
    bldg:boundedBy. Energy ADE's ThermalZoneType also allows thermalBoundary
    surfaces with their own LoD geometry. This keeps building['lod'] meaningful
    for both the normal thermalBoundary path and coincidesWithLodXHull path.
    """
    for boundary_property in doc.children(holder, "bldg", "boundedBy"):
        surf = _first_element(boundary_property, doc)
        if surf is not None and doc.children(surf, "bldg", f"lod{lod}MultiSurface"):
            return True
    for zone_property in doc.children(holder, "nrg", "thermalZone"):
        zone = _first_element(zone_property, doc)
        if zone is None:
            continue
        for boundary_property in doc.children(zone, "nrg", "thermalBoundary"):
            surf = _first_element(boundary_property, doc)
            if surf is not None and doc.children(surf, "bldg", f"lod{lod}MultiSurface"):
                return True
    return False


def _first_element(parent, doc):
    """The first real child element, following an xlink:href if the child is a
    reference instead of inline. Returns None if neither is present."""
    return doc.property_object(parent)

# BoundarySurface -> lod3MultiSurface/lod2MultiSurface -> gml:surfaceMember -> gml:Polygon -> posList
# Checks immediate bldg:lod{2,3}MultiSurface children.
# (so it never grabs a window's ring by accident)
def _surface_rings(doc, surf):
    """All exterior rings of a boundary surface's own lodNMultiSurface.

    GML MultiSurface may contain multiple surfaceMember polygons. EnergyPlus
    BuildingSurface:Detailed represents one polygon, not a disconnected set, so
    the caller splits these rings into separate middle-layer surfaces.
    """
    
    # like: lod3MultiSurface -> MultiSurface -> surfaceMember -> Polygon -> posList
    for n in (3, 2):
        geom = doc.children(surf, "bldg", f"lod{n}MultiSurface")
        if not geom:
            continue
        rings_out = []
        for member in doc.descendants(geom[0], "gml", "surfaceMember"):
            poly = _first_element(member, doc)
            if poly is not None:
                ring = xml_io.read_pos_list(doc, poly)
                if ring:
                    rings_out.append(ring)
        if rings_out:
            return rings_out
        ring = xml_io.read_pos_list(doc, geom[0])
        return [ring] if ring else []
    return []


def _surface_ring(doc, surf):
    """A boundary surface's OWN ring (its lodNMultiSurface) — never an opening's
    ring (openings live under a separate `bldg:opening` child)."""
    # Schema already resolved this as a BoundarySurface. LoD only selects its
    # geometry child. Energy ADE thermal boundaries use LoD3 or LoD2, not LoD4.
    for n in (3, 2):
        geom = doc.children(surf, "bldg", f"lod{n}MultiSurface")
        if geom:
            return xml_io.read_pos_list(doc, geom[0])
    return []


def _unique_ids(*ids):
    out = []
    for value in ids:
        if value and value not in out:
            out.append(value)
    return out



def _surface_records(type_name, sid, rings_list, contexts):
    """One parsed record per surface
    """
    for ring in rings_list[:1]:                  # [:1] -> the single polygon; never split
        yield (type_name, sid, ring, _unique_ids(sid, *contexts), sid)


def _thermal_zone_ids(doc, holder):
    ids = []
    for zone_property in doc.children(holder, "nrg", "thermalZone"):
        zone = _first_element(zone_property, doc)
        if zone is not None:
            ids.append(zone.get(GML_ID))
    return [value for value in ids if value]


# LoD1 single-zone construction hook: raw solid faces are gml:Polygon geometry,
# so construction must come from ThermalZone / Building context.
def _fallback_context_ids(doc, holder, root_building):
    """Construction fallback scopes after a surface has no own construction."""
    zone_ids = _thermal_zone_ids(doc, holder)
    zone_id = zone_ids[0] if len(zone_ids) == 1 else None
    return _unique_ids(zone_id, holder.get(GML_ID), root_building.get(GML_ID))


# Energy ADE spec special cases 5.1 / 6.1:
# if ThermalZone.coincidesWithLod2Hull or coincidesWithLod3Hull is true, the
# thermal zone is exactly the normal CityGML building hull. In that case the GML
# must not duplicate thermalBoundary objects; we read bldg:boundedBy surfaces.

#Building -> bldg:boundedBy -> WallSurface/RoofSurface/GroundSurface
def _labeled_surfaces(doc, building):
    """Building shell path: each bldg:boundedBy BoundarySurface."""
    out = []
    for holder in _building_and_parts(doc, building):
        contexts = _fallback_context_ids(doc, holder, building)
        for bb in doc.children(holder, "bldg", "boundedBy"):
            surf = _first_element(bb, doc)
            if surf is None:
                continue
            sid = surf.get(GML_ID)
            out.extend(_surface_records(local_name(surf), sid, _surface_rings(doc, surf), contexts))
    return out


def _child_text(doc, parent, prefix, local):
    found = doc.children(parent, prefix, local)
    return found[0].text if found else None


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
    for holder in _building_and_parts(doc, building):
        for zone_property in doc.children(holder, "nrg", "thermalZone"):
            zone = _first_element(zone_property, doc)
            if zone is None:
                continue
            if _coincides_with_hull(doc, zone):
                continue
            contexts = _unique_ids(zone.get(GML_ID), holder.get(GML_ID), building.get(GML_ID))
            for boundary_property in doc.children(zone, "nrg", "thermalBoundary"):
                surf = _first_element(boundary_property, doc)
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


def _building_and_parts(doc, building):
    """Parent Building plus nested BuildingParts as one IDF building.

    We intentionally do not return BuildingParts as separate output buildings.
    CityGML 2.0 lets each part carry its own geometry/zones, but physically they
    belong to the parent building model.
    """
    holders = []
    stack = [building]
    seen = set()
    while stack:
        holder = stack.pop()
        key = holder.get(GML_ID) or id(holder)
        if key in seen:
            continue
        seen.add(key)
        holders.append(holder)
        for part_property in doc.children(holder, "bldg", "consistsOfBuildingPart"):
            part = _first_element(part_property, doc)
            if part is not None:
                stack.append(part)
    return holders


def _geometry_property_objects(doc, holder, lod):
    for local in (f"lod{lod}Solid", f"lod{lod}MultiSurface"):
        for prop in doc.children(holder, "bldg", local):
            geom = _first_element(prop, doc)
            if geom is not None:
                yield geom

# Building -> lod1Solid/lod2Solid/lodXMultiSurface -> surfaceMember -> Polygon -> posList
# Raw-solid fallback, mainly LoD1: classify selected solid faces by geometry
# normal and attach ThermalZone/Building context ids for construction fallback.
def _solid_faces(doc, building, lod):
    """Raw selected-LoD geometry fallback.

    Reads only the chosen bldg:lod{n}Solid/lod{n}MultiSurface containers on the
    Building and its direct/nested BuildingParts. This avoids accidentally mixing
    lod0FootPrint, ThermalZone solids, UsageZone solids, or other descendant
    geometry.
    """
    out = []
    if lod is None:
        return out
    for holder in _building_and_parts(doc, building):
        contexts = _fallback_context_ids(doc, holder, building)
        for geom in _geometry_property_objects(doc, holder, lod):
            for sm in doc.descendants(geom, "gml", "surfaceMember"):
                poly = _first_element(sm, doc)
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
    thermal = _thermal_boundary_surfaces(doc, building)
    if thermal:
        return SurfacePath.ENERGY_ADE_BOUNDARIES, thermal
    shell = _labeled_surfaces(doc, building)
    if shell:
        return SurfacePath.CITYGML_BUILDING_SHELL, shell
    solid = _solid_faces(doc, building, lod)
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
        oriented, normal = rings.orient_outward(ring, interior)

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
