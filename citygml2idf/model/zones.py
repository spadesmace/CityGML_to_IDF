"""
model/zones.py — thermal zones, and each surface's EnergyPlus boundary.

One E+ Zone per nrg3:ThermalZone (spec Table 1: "Thermal zones must be modelled", in every
LoD). Nothing is invented: a building with no ThermalZone, or with a surface no zone owns, is
dropped whole (`_drop`) and gets no IDF.

OWNERSHIP (which surfaces a zone owns; first match wins):
  1. coincidesWithLod2Hull / Lod3Hull = true      -> the whole building shell (cases 5.1 / 6.1)
  2. LoD1: the sole zone, no thermalBoundary      -> the whole hull (case 1.1)
  3. LoD1: the zone's own nrg3:lod1Solid          -> that solid's polygons (case 1.2)
  4. nrg3:thermalBoundary                         -> exactly the surfaces it points at

BOUNDARY (per surface; first match wins). "Between zones?" is asked once per face
(`_between_zones`): LoD1 = the zone's own polygon, LoD2/3 = an interior type.
  1. between zones + FAST (default)               -> Adiabatic (--detailed-interior lets heat cross)
  2. nrg3:bdgBdrySurfIsAdiabatic = true           -> Adiabatic
  3. a partner in another zone of this IDF        -> Surface, each face naming the other
       partner = relatedTo adjacentTo, else (LoD2/3 only) the face with the same corner points
       points; each keeps its own construction (the file mirrors it with a
       ReverseLayeredConstruction, spec §3.8)
  4. between zones without a partner, or related
     to a surface of another building (another IDF) -> Adiabatic (LoD1 always: no relatedTo,
                                                     no construction for the slab)
  5. else                                         -> the surface type's default (Outdoors / Ground)
A LoD1 face between zones drawn as a Roof (the slab seen from below) is written as a Ceiling.

The file's winding is kept (building_surfaces.process_surfaces), so the same slab is a Ceiling
in the zone below and a Floor in the zone above. Zone volume is left to E+ (autocalculate):
nrg3:volume is a stated, ambiguous value. A zone's own values (infiltration) are read in
model/zone_physics.py.

Sources: Energy ADE 3.0 spec §4.3.1 (ThermalZone, hull flags, Tables 1-2), §4.3.2 (thermal
boundary classes), §3.8 (layer order); E+ IDD BuildingSurface:Detailed A6 / A7.
"""

from __future__ import annotations

from ..citygml.xml_io import GML_ID
from ..geometry import rings
from ..semantics.building_surfaces import (SurfacePath, coincides_with_hull, lod1_block_ids,
                                           thermal_zones, zone_lod1_polygons)
from ..semantics.surface_types import is_interior
from .model import Zone


def owns_whole_lod1_hull(doc, building, zone_elements, zone_element):
    """True when this zone is the sole zone of a LoD1 building and has no thermalBoundary.

    Notes
    -----
    Energy ADE Table 2, case 1.1: LoD1 allows no thermal boundaries and the hull flags are a
    LoD2/3 concept, so the single zone IS the thermal hull. Guarded so we never guess: exactly
    one zone (several LoD1 zones own their own nrg3:lod1Solid instead), and surfaces from the
    LoD1 solid path (a LoD2/3 shell whose zone has no hull flag is a file error and keeps its
    warning).
    """
    if len(zone_elements) != 1:
        return False
    if building.surface_path != SurfacePath.RAW_SOLID_FALLBACK.value:
        return False
    return not doc.children(zone_element, "nrg", "thermalBoundary")


# LOD 1 Multizone logic
def solid_polygon_ids(doc, zone_element):
    """The gml:ids of the polygons in a zone's own `nrg3:lod1Solid`.

    Parameters
    ----------
    doc : xml_io.CityGMLDoc
        The parsed CityGML file.
    zone_element : lxml element
        An `nrg3:ThermalZone`.

    Returns
    -------
    list of str
        In file order; [] when the zone has no LoD1 solid of its own. A polygon reached by
        xlink keeps the id of the polygon it points at.

    Notes
    -----
    Energy ADE Table 2, case 1.2: "The thermal zones can optionally be modelled as LoD1 solid
    geometries"; ADE XSD AbstractBuildingPartitionType: `lod1Solid`. The LoD1 twin of
    `boundary_surface_ids`: both read from the zone's own XML which faces belong to it.
    """
    polygon_ids = []
    for polygon, _ in zone_lod1_polygons(doc, zone_element):
        polygon_ids.append(polygon.get(GML_ID))
    return polygon_ids


def boundary_surface_ids(doc, zone_element):
    """The gml:ids of the surfaces the zone's nrg3:thermalBoundary properties hold or XLink."""
    surface_ids = []
    for boundary_property in doc.children(zone_element, "nrg", "thermalBoundary"):
        boundary_surface = doc.property_object(boundary_property)   # <thermalBoundary> -> <WallSurface>...
        if boundary_surface is not None:
            surface_ids.append(boundary_surface.get(GML_ID))
    return surface_ids


def _drop(building, reason):
    """Take a building out of the IDF output and record why.

    Parameters
    ----------
    building : Building
        Changed in place: its surfaces are emptied, so every later step skips it.
    reason : str
        Stored in ``building.provenance["skipped"]``; model/reader.py warns it ONCE.

    Notes
    -----
    A building that is not modelled per the spec is dropped WHOLE: no zone is invented and no
    surface is placed in a zone the file did not name.
    """
    building.surfaces = []
    building.provenance["skipped"] = reason


# Multizone: one question for every LoD — is this face between zones, or on the outside?
def _between_zones(surface, lod, block_ids):
    """True when a surface lies between two zones of the building, not on its outside.

    Parameters
    ----------
    surface : Surface
        One face of the building.
    lod : int
        The building's one LoD (1, 2 or 3).
    block_ids : list of str
        LoD1 only: the gml:ids of the building's own lod1Solid polygons ([] otherwise).

    Returns
    -------
    bool
        LoD1: True when the face is NOT one of the building's polygons (the zone wrote a
        polygon of its own). LoD2/3: True when the surface has an interior type
        (PartyWall, IntermediateFloor, InteriorWall, Floor, Ceiling, AtticFloor,
        BasementCeiling).

    Notes
    -----
    Energy ADE Table 2, case 1.2: a zone's outside faces XLink the building's LoD1 polygons.
    Spec §4.3.2: PartyWallSurface for walls between two zones, IntermediateFloorSurface for
    the slab subdividing two zones. AtticFloor and BasementCeiling face a space that is not a
    zone; they count here too (inside the building, never outside).
    """
    if lod == 1:
        return surface.source_id not in block_ids
    return is_interior(surface.type_name)


# Multizone: who is on the other side of a face between zones? The file's word first, then
# the geometry.
def _find_partner(surface, candidates, use_corners):
    """The face on the other side of this one, and how it was found.

    Parameters
    ----------
    surface : Surface
        A face of one zone.
    candidates : list of Surface
        The faces it may pair with: faces of OTHER zones of the same building that are not
        adiabatic and not paired yet.
    use_corners : bool
        True for a LoD2/3 face between zones: when the file names no partner, look for a face
        with the same corner points.

    Returns
    -------
    (Surface or None, str)
        The partner and how it was found ("relatedTo adjacentTo" or "same corner points"),
        or (None, "") when there is none.

    Notes
    -----
    1. nrg3:relatedTo with relationType adjacentTo is the file's own statement, so it wins.
    2. relatedTo is optional; without it, each zone's face of a shared wall or slab has the
       same corners as its twin. Not used in LoD1: LoD1 gives one construction per zone, not
       one for the slab (spec Table 2, case 1.2), so the two halves of a slab would disagree.
    """
    for other in candidates:                                  # 1. the file names the twin
        if other.source_id in surface.adjacent_ids:
            return other, "relatedTo adjacentTo"
    if use_corners:
        for other in candidates:                              # 2. the twin by its corners
            if rings.same_corners(surface.points, other.points):
                return other, "same corner points"
    return None, ""


def _pairs_between_zones(surfaces, lod, block_ids):
    """Every face EnergyPlus can pair with a face of another zone, both ways.

    Parameters
    ----------
    surfaces : list of Surface
        The building's faces, each with its zone already set.
    lod : int
        The building's one LoD (1, 2 or 3).
    block_ids : list of str
        LoD1 only: the gml:ids of the building's own lod1Solid polygons ([] otherwise).

    Returns
    -------
    dict
        surface id -> (partner id, how the partner was found). Both faces of a pair are keys,
        each naming the other.

    Notes
    -----
    E+ IDD BuildingSurface:Detailed A6 = Surface, A7 = the partner, which must be a surface in
    this IDF; for heat between zones "both surfaces must be represented" (E+ I/O Reference), so
    each names the other and a one-sided relatedTo still gives a two-sided pair. Both faces
    already exist in the file: nothing is synthesized. A face with isAdiabatic=true never
    pairs: it passes no heat to the other side.
    """
    pairs = {}
    for surface in surfaces:
        if surface.is_adiabatic or surface.source_id in pairs:
            continue
        candidates = []
        for other in surfaces:
            if other.zone == surface.zone:                   # same zone: not a face between zones
                continue
            if other.is_adiabatic or other.source_id in pairs:
                continue
            candidates.append(other)
        use_corners = lod != 1 and _between_zones(surface, lod, block_ids)
        partner, how = _find_partner(surface, candidates, use_corners)
        if partner is not None:
            pairs[surface.source_id] = (partner.source_id, how)
            pairs[partner.source_id] = (surface.source_id, how)
    return pairs


def assign_zones(doc, middle, detailed_interior=False):
    """Give each building its zones, and each surface its zone and boundary.

    Parameters
    ----------
    doc : xml_io.CityGMLDoc
        The parsed CityGML file.
    middle : Model
        The middle layer, changed in place.
    detailed_interior : bool, optional
        False (default) = FAST: interior zone-to-zone faces are Adiabatic.
        True = interior faces may become EnergyPlus Surface pairs.

    Notes
    -----
    pass 1  each ThermalZone's owned surface ids (OWNERSHIP, module docstring)
    pass 2  assign each face its zone
    pass 3  the pairs between zones (`_pairs_between_zones`: relatedTo, else same corners)
    pass 4  the boundary waterfall (BOUNDARY, module docstring)
    Before pass 1, a building with no ThermalZone is dropped (`_drop`); after it, so is a
    building with a surface no zone owns.
    """
    for building in middle.buildings:
        surfaces = building.surfaces
        if not surfaces:
            continue          # no envelope -> nothing to own (model/reader.py warns once)
        building_surface_ids = {surface.source_id for surface in surfaces}

        zone_elements = thermal_zones(doc, doc.get_by_id(building.id))   # find the ThermalZones
        if not zone_elements:
            _drop(building, "declares no nrg3:ThermalZone (Energy ADE Table 1: thermal zones "
                            "must be modelled)")
            continue

        # pass 1: each zone's owned surface ids (OWNERSHIP, module docstring)
        zones = []
        for zone_element in zone_elements:
            name = zone_element.get(GML_ID)
            coincides = coincides_with_hull(doc, zone_element)
            solid_ids = []
            if building.lod == 1:                      # only LoD1 reads a zone's own solid
                solid_ids = solid_polygon_ids(doc, zone_element)
            if coincides:
                owned_ids = set(building_surface_ids)  # the zone OWNS THE WHOLE SHELL
                ownership_source = "coincidesWithLodXHull"
            elif owns_whole_lod1_hull(doc, building, zone_elements, zone_element):
                owned_ids = set(building_surface_ids)  # the sole LoD1 zone IS the thermal hull
                ownership_source = ("LoD1 whole-hull assignment (sole ThermalZone, no "
                                    "thermalBoundary, raw LoD1 solid faces)")
            elif solid_ids:                            # LoD1 multizone: its own solid's faces
                owned_ids = set()
                for sid in solid_ids:
                    if sid in building_surface_ids:
                        owned_ids.add(sid)
                ownership_source = "the zone's own nrg3:lod1Solid"
            else:
                owned_ids = set()
                # read the zone's owned surfaces from nrg3:thermalBoundary
                referenced_ids = boundary_surface_ids(doc, zone_element)
                for sid in referenced_ids:
                    if sid in building_surface_ids:
                        owned_ids.add(sid)
                ownership_source = "nrg3:thermalBoundary"
            zones.append({"name": name, "ids": owned_ids,
                          "provenance": {"name": f"{name} (from ThermalZone gml:id)",
                                         "ownership": f"{ownership_source}: owns "
                                                      f"{len(owned_ids)} surface(s)"}})
        all_owned_ids = set()
        for zone in zones:
            all_owned_ids.update(zone["ids"])
        unowned_ids = [surface.source_id for surface in surfaces
                       if surface.source_id not in all_owned_ids]
        if unowned_ids:
            _drop(building, f"{len(unowned_ids)} surface(s) owned by no ThermalZone: {unowned_ids}")
            continue
        building.zones = [Zone(name=zone["name"], provenance=zone["provenance"])
                          for zone in zones]

        # ---- pass 2: assign each face its zone -------------------------------------------
        # Every surface has at least one owner here: an unowned one dropped the building above.
        for surface in surfaces:                       # count how many zones own each surface
            owners = [zone for zone in zones if surface.source_id in zone["ids"]]
            surface.zone = owners[0]["name"]
            surface.provenance["zone"] = (f"assigned to {owners[0]['name']} "
                                          f"({len(owners)} owning zone(s))")

        # ---- pass 3: which faces form a REAL EnergyPlus interzone pair? -------------------
        # Needs every surface's zone, so it runs AFTER pass 2.
        block_ids = []
        if building.lod == 1:
            block_ids = lod1_block_ids(doc, doc.get_by_id(building.id))
        zone_of = {surface.source_id: surface.zone for surface in surfaces}
        pairs = _pairs_between_zones(surfaces, building.lod, block_ids)

        # ---- pass 4: the boundary waterfall (most explicit first) -------------------------
        for surface in surfaces:
            between = _between_zones(surface, building.lod, block_ids)
            surface.boundary_object = ""

            if between and surface.surface_type == "Roof":       # the LoD1 slab seen from the zone below
                surface.surface_type = "Ceiling"
                surface.provenance["surface_type"] = "Ceiling (LoD1 slab seen from the zone below)"

            if between and not detailed_interior:                # 1. FAST: no heat between zones
                surface.boundary = "Adiabatic"
                note = "Adiabatic (fast workflow; pass --detailed-interior for heat transfer)"

            elif surface.is_adiabatic:                           # 2. the file says so -> wins
                surface.boundary = "Adiabatic"
                note = "Adiabatic (citygml nrg3:bdgBdrySurfIsAdiabatic=true)"

            elif surface.source_id in pairs:                     # 3. a pair EnergyPlus can use
                partner, how = pairs[surface.source_id]
                surface.boundary = "Surface"
                surface.boundary_object = partner
                note = (f"Surface -> {partner} ({how}; partner surface is in this IDF, "
                        f"zone {zone_of[partner]})")

            elif between or surface.adjacent_ids:                # 4. no partner in this IDF
                # between zones without a pair, or related to a surface of another building
                # (another IDF): E+ A7 can only name a surface in this file
                surface.boundary = "Adiabatic"
                note = "Adiabatic (no surface of another zone in this IDF to pair with)"

            else:                                                # 5. surface-type default
                note = f"{surface.boundary} (surface-type default)"

            surface.provenance["boundary"] = note
