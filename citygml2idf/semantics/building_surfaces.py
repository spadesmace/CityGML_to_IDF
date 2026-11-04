"""Read ONE building's envelope surfaces, in the building's ONE LoD (select_lod).

Where the surfaces come from (select_surface_path):
  * LoD2/3: each ThermalZone's nrg3:thermalBoundary surfaces, else the building's
            bldg:boundedBy shell (a coincidesWithLod2Hull / Lod3Hull zone);
  * LoD1:   the building's own bldg:lod1Solid / lod1MultiSurface, or each zone's own
            nrg3:lod1Solid (Table 2, case 1.2).

Returns ONE uniform list of Surface objects, so zones / constructions / writer never care
which LoD the file was (openings reads Building.lod). Surfaces and geometry may be inline or
xlinked. Points stay as written: the FILE's winding, not yet recentred (model/reader.py).

LIMITS: ONE bldg:Building = ONE IDF (bldg:BuildingPart is not read); coordinates are
assumed metric (no CRS check, no reprojection).
"""

from __future__ import annotations

from enum import Enum

from ..citygml import xml_io
from ..citygml.xml_io import GML_ID, local_name
from ..geometry import rings, classify
from ..citygml.citygml_read import child_bool
from ..model.model import Surface
from . import surface_types


def _lod_multisurface(doc, element, lod):
    """The `bldg:lod{lod}MultiSurface` geometry properties of one boundary surface.

    Parameters
    ----------
    doc : xml_io.CityGMLDoc
        The parsed CityGML file.
    element : lxml element
        A `bldg:` boundary surface, or one of the 4 Energy ADE surface classes.
    lod : int
        The LoD to read (2 or 3).

    Returns
    -------
    list
        The DIRECT-child property elements; [] when the surface has none in this LoD.

    Notes
    -----
    building.xsd `AbstractBoundarySurfaceType` carries the geometry as `bldg:lod2/3/4MultiSurface`.
    The Energy ADE classes (PartyWall-, IntermediateFloor-, AtticFloor-, BasementCeilingSurface)
    extend that type with an empty sequence, so their geometry is `bldg:` too. The ADE XSD has
    `lodNMultiSurface` only on `AbstractSolarCollector` (a device), never on a surface.
    """
    return doc.children(element, "bldg", f"lod{lod}MultiSurface")


# BoundarySurface -> lod{lod}MultiSurface -> gml:surfaceMember -> gml:Polygon -> posList
def _surface_rings(doc, surf, lod):
    """The exterior ring(s) of a boundary surface's own `bldg:lod{lod}MultiSurface`.

    Parameters
    ----------
    doc : xml_io.CityGMLDoc
        The parsed CityGML file.
    surf : lxml element
        A boundary surface (`bldg:WallSurface`, ... or one of the 4 Energy ADE surface classes).
    lod : int
        The building's ONE LoD (select_lod): 2 or 3.

    Returns
    -------
    list
        The readable rings, in file order; [] when the surface has none in this LoD.

    Warns
    -----
    When the surface has no geometry in this LoD, an empty property / dangling xlink, or no
    readable polygon. The surface is then skipped: a gap is never filled from another LoD.

    Notes
    -----
    THE GEOMETRY MAY BE SHARED BY REFERENCE. Energy ADE §4.1.2 Rule 2: XLinks may reuse a
    polygon "within the same city object (e.g. the same building) and within the same LoD",
    so a thermal boundary may POINT AT its thematic twin's geometry instead of repeating the
    coordinates. The xlink can sit at either level:

      1. PROPERTY level   <bldg:lod2MultiSurface xlink:href="#MS_of_thematic_surface"/>
                          the property tag is EMPTY; the gml:MultiSurface lives elsewhere.
      2. MEMBER level     <bldg:lod2MultiSurface><gml:MultiSurface>
                              <gml:surfaceMember xlink:href="#polygon_of_thematic_surface"/>
      3. INLINE           the gml:MultiSurface is nested in the property, as usual.

    So RESOLVE the property into its geometry object first (property_object handles inline AND
    xlink); xml_io.surface_polygons then follows the members (inline or xlink) to the polygons.
    """
    geometry_property = _lod_multisurface(doc, surf, lod)
    if not geometry_property:
        xml_io.warn(f"surface {surf.get(GML_ID)}: no lod{lod}MultiSurface; no surface emitted")
        return []
    geometry = doc.property_object(geometry_property[0])   # inline OR xlink -> the geometry
    if geometry is None:                                   # never drop a face in silence
        xml_io.warn(f"surface {surf.get(GML_ID)}: lod{lod}MultiSurface carries no geometry "
                    f"(empty property or dangling xlink); no surface emitted")
        return []
    rings_out = [ring for _, ring in xml_io.surface_polygons(doc, geometry) if ring]
    if not rings_out:
        xml_io.warn(f"surface {surf.get(GML_ID)}: lod{lod}MultiSurface has no readable polygon; "
                    f"no surface emitted")
    return rings_out


def _unique_ids(*ids):
    """The non-empty ids, in order, each once."""
    out = []
    for value in ids:
        if value and value not in out:
            out.append(value)
    return out


def _surface_records(type_name, sid, rings_list, contexts):
    """The surface's record for its FIRST polygon; [] when it has none.

    Parameters
    ----------
    type_name : str
        The surface's local name (e.g. 'WallSurface').
    sid : str
        The surface's gml:id.
    rings_list : list
        The surface's readable polygon rings, in file order.
    contexts : list of str
        Construction fallback owner ids.

    Returns
    -------
    list of tuple
        [(type_name, sid, ring, construction_context_ids)] for the first polygon, or [].

    Warns
    -----
    When the surface has more than one polygon: only the first is read.

    Notes
    -----
    KNOWN LIMITATION, chosen to keep the reader simple: ONE polygon per surface. A
    gml:MultiSurface may legally hold several polygons (e.g. a gabled roof as ONE RoofSurface
    with two planes); the rest are not read, and the warning says so.
    """
    if not rings_list:
        return []
    if len(rings_list) > 1:
        xml_io.warn(f"surface {sid}: {len(rings_list)} polygons; only the first is read "
                    f"(one polygon per surface)")
    return [(type_name, sid, rings_list[0], _unique_ids(sid, *contexts))]


def thermal_zones(doc, building):
    """The building's nrg3:ThermalZone objects in file order; [] when it has none.

    Notes
    -----
    Direct children only: Energy ADE §4.2.2 Rule 4, "All ThermalZones ... are written as
    direct children of the containing element derived from ADE _AbstractBuilding".
    """
    if building is None:
        return []
    zones = []
    for prop in doc.children(building, "nrg", "thermalZone"):
        zone = doc.property_object(prop)
        if zone is not None:
            zones.append(zone)
    return zones


# The construction owner cascade (constructions.py) walks OUTWARD from a surface:
#       surface -> ThermalZone -> Building
# This supplies the outer rungs. It matters in LoD1: a raw gml:Polygon is not a CityObject and
# cannot own a construction, so the file puts it on the ZONE (ADE Table 2, case 1.1). The zone
# rung is used only when the building has exactly ONE zone, so we never guess.
def _fallback_context_ids(doc, building):
    """Construction fallback owners, nearest first, for a surface with no construction of its own."""
    zones = thermal_zones(doc, building)
    zone_id = zones[0].get(GML_ID) if len(zones) == 1 else None
    return _unique_ids(zone_id, building.get(GML_ID))


# if ThermalZone.coincidesWithLod2Hull or coincidesWithLod3Hull is true, the
# thermal zone is exactly the normal CityGML building hull. In that case the GML
# must not duplicate thermalBoundary objects; we read bldg:boundedBy surfaces.

#Building -> bldg:boundedBy -> WallSurface/RoofSurface/GroundSurface
def _labeled_surfaces(doc, building, lod):
    """Building shell path: each bldg:boundedBy BoundarySurface, read in the building's LoD."""
    out = []
    contexts = _fallback_context_ids(doc, building)
    for bb in doc.children(building, "bldg", "boundedBy"):
        surf = doc.property_object(bb)
        if surf is None:
            continue
        sid = surf.get(GML_ID)
        out.extend(_surface_records(local_name(surf), sid, _surface_rings(doc, surf, lod), contexts))
    return out


def coincides_with_hull(doc, zone):
    """True if the zone states it fills the building's LoD2 or LoD3 hull.

    Parameters
    ----------
    doc : xml_io.CityGMLDoc
        The parsed CityGML file.
    zone : lxml element
        An `nrg3:ThermalZone`.

    Returns
    -------
    bool
        True when `nrg3:coincidesWithLod2Hull` or `nrg3:coincidesWithLod3Hull` is `true`.
        Such a zone owns the WHOLE building shell (`bldg:boundedBy`) and has no
        thermalBoundary of its own to read.

    Notes
    -----
    Energy ADE spec §4.3.1 and Table 1 ("special cases": coincidesWithLoDxHull set to TRUE,
    thematic surfaces used directly); XSD `ThermalZoneType`. Used by this module (which
    surfaces to read) and by model/zones.py (which zone owns them).
    """
    for flag in ("coincidesWithLod2Hull", "coincidesWithLod3Hull"):
        if child_bool(doc, zone, "nrg", flag):
            return True
    return False


def select_lod(doc, building):
    """The ONE LoD a building is read in.

    Parameters
    ----------
    doc : xml_io.CityGMLDoc
        The parsed CityGML file.
    building : lxml element
        A `bldg:Building`.

    Returns
    -------
    int or None
        3, 2 or 1. None when no LoD can be read; the building then gets no IDF.

    Notes
    -----
    A building may be written in several LoDs at once (CityGML 2.0 §6.2; building.xsd gives
    every boundary surface an optional lod2MultiSurface AND lod3MultiSurface). One IDF is one
    thermal model, so the whole building is read in ONE LoD, never one LoD per surface:

    1. a zone with coincidesWithLod3Hull = true -> 3; coincidesWithLod2Hull = true -> 2
       (Energy ADE §4.3.1: the zone is "the external hull resulting from the union of all
       LoD2 thematic surfaces"; the LoD3 case is "conceptually similar");
    2. else the zones' thermal boundaries -> the highest LoD that EVERY boundary has; None
       when they share no LoD (a gap is never filled from another LoD);
    3. else the building's own lod1Solid / lod1MultiSurface -> 1 (Energy ADE Table 1, LoD1:
       "No thermal boundaries").
    """
    zones = thermal_zones(doc, building)

    # 1. a hull flag names the LoD
    for lod in (3, 2):
        for zone in zones:
            if child_bool(doc, zone, "nrg", f"coincidesWithLod{lod}Hull"):
                return lod

    # 2. thermal boundaries: the highest LoD that every boundary has
    boundaries = []
    for zone in zones:
        for prop in doc.children(zone, "nrg", "thermalBoundary"):
            surface = doc.property_object(prop)
            if surface is not None:
                boundaries.append(surface)
    if boundaries:                       # checked first: all([]) would be True
        for lod in (3, 2):
            if all(_lod_multisurface(doc, surface, lod) for surface in boundaries):
                return lod
        return None

    # 3. LoD1: no boundaries, the building's own LoD1 geometry
    if (doc.children(building, "bldg", "lod1Solid")
            or doc.children(building, "bldg", "lod1MultiSurface")):
        return 1
    return None


# Normal LoD2/LoD3 ADE path: Building -> ThermalZone -> thermalBoundary -> BoundarySurface
# This is used only when the zone does NOT declare coincidesWithLodXHull=true.
# When the flag is true, _labeled_surfaces() reads the normal building shell.
def _thermal_boundary_surfaces(doc, building, lod):
    """Energy ADE path: explicit zone boundary surfaces under ThermalZone.

    thermalBoundary has the same CityGML property pattern as boundedBy: the
    BoundarySurface may be inline or referenced by xlink. Zones that declare
    coincidesWithLodXHull use the building shell instead, so we skip them here.
    """
    out = []
    seen = set()
    for zone in thermal_zones(doc, building):
        if coincides_with_hull(doc, zone):
            continue
        contexts = _unique_ids(zone.get(GML_ID), building.get(GML_ID))
        for boundary_property in doc.children(zone, "nrg", "thermalBoundary"):
            surf = doc.property_object(boundary_property)
            if surf is None:
                continue
            sid = surf.get(GML_ID)               # always set: xml_io generates missing ids
            if sid in seen:                      # the same surface reached twice (xlink)
                continue
            seen.add(sid)
            out.extend(_surface_records(local_name(surf), sid, _surface_rings(doc, surf, lod), contexts))
    return out


def _building_lod1_polygons(doc, building):
    """(polygon, ring) pairs of the BUILDING's own bldg:lod1Solid, else its bldg:lod1MultiSurface.

    Notes
    -----
    CityGML 2.0 §10.3.9, requirement 3: "For LOD1, either lod1Solid or lod1MultiSurface must
    be used, but not both." A file that still has both is read from its solid only, so no face
    is read twice. Only the Building's own property: never a zone's or a footprint's geometry.
    """
    for local in ("lod1Solid", "lod1MultiSurface"):
        geometries = []
        for prop in doc.children(building, "bldg", local):
            geometry = doc.property_object(prop)
            if geometry is not None:
                geometries.append(geometry)
        if geometries:                       # the solid, else the multi-surface; never both
            pairs = []
            for geometry in geometries:
                pairs.extend(xml_io.surface_polygons(doc, geometry))
            return pairs
    return []


def zone_lod1_polygons(doc, zone):
    """(polygon, ring) pairs of a ZONE's own nrg3:lod1Solid; [] when it has none.

    Notes
    -----
    Energy ADE Table 2, case 1.2: "The thermal zones can optionally be modelled as LoD1 solid
    geometries"; ADE XSD AbstractBuildingPartitionType: lod1Solid. An xlinked polygon keeps the
    gml:id of the building polygon it points at.
    """
    pairs = []
    for prop in doc.children(zone, "nrg", "lod1Solid"):
        solid = doc.property_object(prop)
        if solid is not None:
            pairs.extend(xml_io.surface_polygons(doc, solid))
    return pairs


# Building -> lod1Solid (else lod1MultiSurface) -> surfaceMember -> Polygon -> posList
# LoD1: the faces get their role later, from their direction (process_surfaces)
def _building_lod1_faces(doc, building):
    """LoD1 records of the BUILDING's own polygons (bldg:lod1Solid / lod1MultiSurface)."""
    out = []
    contexts = _fallback_context_ids(doc, building)
    for polygon, ring in _building_lod1_polygons(doc, building):
        sid = polygon.get(GML_ID)
        out.append((None, sid, ring, contexts))
    return out


# LOD1 Multizone logic
def lod1_block_ids(doc, building):
    """The gml:ids of the building's own LoD1 polygons (the block the zones xlink).

    Parameters
    ----------
    doc : xml_io.CityGMLDoc
        The parsed CityGML file.
    building : lxml element
        A `bldg:Building`.

    Returns
    -------
    list of str
        In file order; [] when the building has no readable LoD1 geometry.

    Notes
    -----
    Energy ADE Table 2, case 1.2: "XLinks can be used to reference the homologous polygons of
    the LoD1 solid". A zone face that is one of these polygons is exterior; a zone face with a
    polygon of its own lies between two zones.
    """
    ids = []
    for polygon, _ in _building_lod1_polygons(doc, building):
        ids.append(polygon.get(GML_ID))
    return ids


# LOD1 Logic
def _zone_lod1_faces(doc, building):
    """LoD1: the faces of each zone's own `nrg3:lod1Solid`, zone by zone.

    Parameters
    ----------
    doc : xml_io.CityGMLDoc
        The parsed CityGML file.
    building : lxml element
        A `bldg:Building`.

    Returns
    -------
    list of tuple
        (None, sid, ring, construction_context_ids) per face, in file order; the
        construction owners are the face's own zone, then the building. [] when no zone has
        a LoD1 solid of its own.

    Notes
    -----
    Energy ADE Table 2, case 1.2: "The thermal zones can optionally be modelled as LoD1 solid
    geometries. XLinks can be used to reference the homologous polygons of the LoD1 solid", and
    "A LayeredConstruction object is associated to each thermal zone". The ADE XSD gives every
    zone an optional `nrg3:lod1Solid` (AbstractBuildingPartitionType). An xlinked face IS the
    building's polygon (same gml:id); a polygon reached twice is read once.
    """
    out = []
    seen = set()
    for zone in thermal_zones(doc, building):
        contexts = _unique_ids(zone.get(GML_ID), building.get(GML_ID))
        for polygon, ring in zone_lod1_polygons(doc, zone):
            sid = polygon.get(GML_ID)
            if sid in seen:                      # the same polygon reached twice (xlink)
                continue
            seen.add(sid)
            out.append((None, sid, ring, contexts))
    return out


class SurfacePath(Enum):
    """WHERE in the file a building's surfaces came from (kept on the Building for audit).

    The label names the source only; it does not count zones. Who owns which surface is read
    from the XML in model/zones.py.

    Attributes
    ----------
    ENERGY_ADE_BOUNDARIES
        LoD2/3: each zone's `nrg3:thermalBoundary` surfaces; a zone owns the ones it lists.
    CITYGML_BUILDING_SHELL
        LoD2/3: the building's `bldg:boundedBy` surfaces; the zone with
        coincidesWithLod2Hull / coincidesWithLod3Hull = true owns them all.
    RAW_SOLID_FALLBACK
        LoD1: bare polygons, role from their direction. Each zone's own `nrg3:lod1Solid` when
        a zone has one (a zone owns its own solid's faces), else the building's
        `bldg:lod1Solid` (the only zone owns it all).
    NONE
        Nothing readable (e.g. a LoD0 footprint only); the building gets no IDF.
    """
    ENERGY_ADE_BOUNDARIES = "energy_ade_boundaries"
    CITYGML_BUILDING_SHELL = "citygml_building_shell"
    RAW_SOLID_FALLBACK = "raw_solid_fallback"
    NONE = "none"


def select_surface_path(doc, building, lod):
    """Where one building's surfaces come from, read in its ONE LoD.

    Parameters
    ----------
    doc : xml_io.CityGMLDoc
        The parsed CityGML file.
    building : lxml element
        A `bldg:Building`.
    lod : int or None
        The building's ONE LoD (select_lod).

    Returns
    -------
    tuple
        (SurfacePath, raw records). NONE + [] when nothing is readable, so the caller can
        still trace the building yet emit no IDF.

    Notes
    -----
    A LoD2/3 building is never read from its raw solid: Energy ADE Table 1 says that in LoD2
    and LoD3 "Thermal boundaries must be modelled via thematic surfaces" (special cases:
    "directly use thematic surfaces"). LoD1 has "No thermal boundaries", so it is read from
    the building's own LoD1 geometry, or, when zones carry a LoD1 solid of their own
    (Table 2, case 1.2), from those zone solids. The building's own LoD1 solid must be
    readable either way: a zone face is exterior only when it is one of its polygons.
    """
    if lod == 1:
        block = _building_lod1_faces(doc, building)
        if not block:
            return SurfacePath.NONE, []
        zone_faces = _zone_lod1_faces(doc, building)
        if zone_faces:
            return SurfacePath.RAW_SOLID_FALLBACK, zone_faces
        return SurfacePath.RAW_SOLID_FALLBACK, block
    elif lod in (2, 3):
        thermal = _thermal_boundary_surfaces(doc, building, lod)
        if thermal:
            return SurfacePath.ENERGY_ADE_BOUNDARIES, thermal # Hull :False
        shell = _labeled_surfaces(doc, building, lod)
        if shell:
            return SurfacePath.CITYGML_BUILDING_SHELL, shell # Hull:True
    return SurfacePath.NONE, []


def process_surfaces(raw):
    """Turn raw records into the uniform Surface list, keeping the FILE's point order.

    Parameters
    ----------
    raw : list of tuple
        (type_name, sid, ring, construction_context_ids); type_name None = an
        unlabelled LoD1 face.

    Returns
    -------
    list of Surface
        One per readable face. A face with < 3 points, or a type that cannot be resolved, is
        warned and skipped.

    Notes
    -----
    ORIENTATION = THE FILE'S WINDING. GML3 / CityGML 2.0: the
    vertex order defines the normal, and "the surface normals of the outer shell of a GML solid
    must point outwards"; EnergyPlus GlobalGeometryRules uses the same rule (Counterclockwise,
    seen from outside). So the points pass through unchanged and the normal is read from them:
    it gives the LoD1 role (tilt, geometry/classify.py) and Floor vs Ceiling. No centre point
    is used, so any shape works (L, T, U, courtyard, stepped). The winding is trusted, not
    checked.
    """
    surfaces = []
    for type_name, sid, ring, construction_context_ids in raw:
        points = rings.drop_closing_point(ring)
        if len(points) < 3:                        # not a real polygon -> ignore
            xml_io.warn(f"surface {sid}: fewer than 3 points; skipped")
            continue
        normal = rings.unit_normal(points)         # the file's own direction

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
            type_name=type_name or "classified",
            role=rule.role,
            surface_type=surface_type,
            boundary=rule.boundary,
            points=[list(p) for p in points],
            construction_context_ids=construction_context_ids,
            provenance={
                "role": f"{rule.role} ({rule_source}"
                        + (f" '{type_name}'" if type_name else "") + ")",
                "surface_type": f"{surface_type} (file winding, normal z={normal[2]:.3f})",
                "boundary": rule.boundary,
            },
        ))
    return surfaces


def surfaces_of_building(doc, building):
    """Read one building's envelope as the uniform surface list.

    Parameters
    ----------
    doc : xml_io.CityGMLDoc
        The parsed CityGML file.
    building : lxml element
        A `bldg:Building`.

    Returns
    -------
    lod : int or None
        The ONE LoD the building is read in (select_lod); None when no LoD is readable.
    path : SurfacePath
        WHICH source the surfaces came from; kept on the Building for audit.
    surfaces : list of Surface
        [] when no source yields a readable surface (e.g. LoD0 only). The building stays
        in the Model, gets no IDF, and model/reader.py warns ONCE about it.
    """
    lod = select_lod(doc, building)
    path, raw = select_surface_path(doc, building, lod)
    return lod, path, process_surfaces(raw)
