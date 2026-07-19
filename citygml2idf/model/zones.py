"""
model/zones.py — thermal zones, and each surface's EnergyPlus boundary.

PRESENCE-BASED (never LoD-driven): one E+ Zone per `nrg3:ThermalZone`; one implicit zone when
the file declares none.

OWNERSHIP WATERFALL (which surfaces a zone owns — most explicit first):
  1. `nrg3:coincidesWithLodXHull = true` -> the zone ignores its partial thermalBoundary list
     and owns the WHOLE building shell (ADE cases 5.1 / 6.1).
  2. the SOLE zone of a building whose surfaces came from the RAW LoD1 SOLID, declaring NO
     thermalBoundary -> owns the whole hull (ADE case 1.1). In LoD1 thermal boundaries are
     FORBIDDEN and coincidesWithLodXHull is a LoD2/3 concept, so the file has no other way to
     say it. Guarded to ONE zone and the raw-solid path so we never guess (see
     `owns_whole_lod1_hull`); LoD1 MULTIZONE (case 1.2) needs each zone's own solid and is
     not implemented — it still warns.
  3. `nrg3:thermalBoundary` xlinks -> the zone owns exactly the surfaces it points at.

BOUNDARY WATERFALL (most explicit first) — nothing is ever invented:
  0. FAST workflow (default, detailed_interior=False): every INTERIOR zone-to-zone face
     (is_interior) -> Adiabatic, skipping pairing, to keep the E+ model cheap. Exterior faces
     untouched. --detailed-interior turns this off so interior heat transfer is modelled.
  1. `nrg3:bdgBdrySurfIsAdiabatic = true` -> Adiabatic. Beats any adjacency
     (id_building_11's intermediate floor is exactly this case).
  2. ONE surface owned by TWO zones -> warn + Adiabatic. Energy ADE models an interzone boundary
     as TWO real surfaces linked by `nrg3:relatedTo`, and E+ A7 must name a surface present in
     this IDF, so we never synthesize a twin.
  3. `relatedTo` (relationType="adjacent") targeting a surface EMITTED IN THIS IDF owned by a
     DIFFERENT zone -> Outside_Boundary_Condition = Surface, each face naming the other. Both
     faces already exist (id_building_9-10's party walls) and each keeps its OWN construction —
     the file supplies the mirror via `nrg3:ReverseLayeredConstruction` (spec §3.8).
  4. any other adjacency (other building / not a surface) -> Adiabatic.
  5. nothing stated -> the surface type's default (Outdoors / Ground / Adiabatic).

ORIENTATION: a face's outward normal points AWAY FROM THE ZONE THAT OWNS IT, so the same slab is
a Ceiling to the zone below and a Floor to the zone above (`floor_or_ceiling`).

ZONE VOLUME is left to EnergyPlus (`autocalculate`): `nrg3:volume` is a stated, ambiguous
attribute (grossVolume / netVolume / energyReferenceVolume) and our geometry is authoritative.

Refs: Energy ADE 3.0 spec §4.3.1 (ThermalZone, coincidesWithLodXHull), §4.3.2 (thermal
boundaries), §3.8 (layer order, ReverseLayeredConstruction); E+ IDD BuildingSurface:Detailed
A6/A7 (Outside Boundary Condition + Object).
"""

from __future__ import annotations

import sys

import numpy as np

from ..citygml import xml_io
from ..citygml.xml_io import GML_ID, warn
from ..geometry import rings
from ..semantics.building_surfaces import SurfacePath
from ..semantics.surface_types import floor_or_ceiling, is_interior
from .constructions import _child_text as child_text_value
from .model import Zone

# Find ThermalZones
def thermal_zones(doc, building_element):
    # The building's own nrg3:ThermalZone objects ([] when the file has none -> the caller falls
    # back to one implicit zone). DIRECT children: nrg3:thermalZone is a property of
    # _AbstractBuilding, so that is where a zone sits.
    # REF: ADE spec §4.3.1 (ThermalZone)
    if building_element is None:
        return []
    zone_properties = doc.children(building_element, "nrg", "thermalZone")
    zones = [doc.property_object(prop) for prop in zone_properties]
    return [zone for zone in zones if zone is not None]


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


def owns_whole_lod1_hull(doc, building, zone_elements, zone_element):
    # WHAT: True when this zone is the SOLE zone of an LoD1 building and declares NO
    #       thermalBoundary -> it owns the whole hull, exactly like coincidesWithLodXHull
    #       but for a different reason (Energy ADE Table 2, case 1.1).
    # REF : ADE spec §4.3.1 / Table 1 — in LoD1 thermal boundaries are FORBIDDEN, and
    #       coincidesWithLodXHull is a LoD2/LoD3 concept, so an LoD1 zone can state its
    #       ownership by NEITHER mechanism. The single zone IS the thermal hull.
    # GUARDS (we never guess):
    #   * exactly ONE zone — with several zones and no boundaries, ownership must come
    #     from each zone's own nrg3:lodXSolid, which is not implemented (case 1.2);
    #   * the surfaces came from the RAW SOLID path — a labeled LoD2/LoD3 shell whose zone
    #     forgot coincidesWithLodXHull is a FILE error, and must keep warning, not be guessed.
    if len(zone_elements) != 1:
        return False
    if building.surface_path != SurfacePath.RAW_SOLID_FALLBACK.value:
        return False
    return not doc.children(zone_element, "nrg", "thermalBoundary")


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

""" TODO
no-ThermalZone buildings only apply isAdiabatic=true; they do not apply the relatedTo adjacent -> Adiabatic fallback.
So a no-zone building with a WallSurface adjacent to another building could stay Outdoors. That is not the waterfall we planned.
"""
def _single_zone(building):
    # No ThermalZone in the file -> ONE implicit E+ Zone = the whole building (the LoD1
    # fallback); every surface keeps its own exterior boundary.
    zone_name = f"{building.id}_Zone"
    building.zones = [Zone(name=zone_name,
                           provenance={"name": f"{zone_name} (implicit single zone)"})]
    for surface in building.surfaces:
        surface.zone = zone_name
        surface.boundary_object = ""
        surface.provenance["zone"] = f"assigned to {zone_name} (implicit single zone; owner_count=1)"
        # One zone can never have an interzone partner, but an EXPLICIT adiabatic flag still
        # beats the surface-type default (rule 1 of the waterfall in assign_zones).
        if surface.is_adiabatic:
            surface.boundary = "Adiabatic"
            surface.provenance["boundary"] = "Adiabatic (citygml nrg3:bdgBdrySurfIsAdiabatic=true)"
        else:
            surface.provenance["boundary"] = f"{surface.boundary} (surface-type default)"


def _interzone_pairs(surfaces, zone_of):
    # WHAT: surface_id -> partner surface_id, for the `relatedTo adjacent` relations EnergyPlus
    #       can actually honour. A target qualifies ONLY when it is
    #         (a) a surface EMITTED IN THIS IDF (E+ A7 must name a surface in the same file),
    #         (b) owned by a DIFFERENT zone (same zone = not an interzone face), and
    #         (c) not explicitly adiabatic on either side (an isAdiabatic=true face never
    #             conducts, so it can never be half of a Surface pair).
    #       Both faces ALREADY EXIST in the CityGML — nothing is synthesized. E+ requires the two
    #       surfaces to name EACH OTHER, so we make the pair reciprocal here; that also means a
    #       one-sided `relatedTo` still yields a valid pair.
    # REF : E+ IDD BuildingSurface:Detailed A6=Surface / A7=Outside Boundary Condition Object.
    adiabatic = {surface.source_id: bool(surface.is_adiabatic) for surface in surfaces}
    pairs = {}
    for surface in surfaces:
        if surface.is_adiabatic or surface.source_id in pairs:
            continue
        for target in surface.adjacent_ids:
            if target not in zone_of:                        # not a surface emitted in this IDF
                continue
            if zone_of[target] == surface.zone:              # same zone -> not an interzone face
                continue
            if adiabatic.get(target) or target in pairs:
                continue
            pairs[surface.source_id] = target
            pairs[target] = surface.source_id
            break
    return pairs


# handles one zone and multiplezone
# detailed_interior: False (default) = FAST, interior zone-to-zone faces -> Adiabatic;
#                    True = model heat transfer (interior faces can become Surface pairs).
def assign_zones(doc, middle, detailed_interior=False):
    # Build `building.zones`, then give every surface its zone, orientation and boundary:
    #   pass 1  each ThermalZone's owned surface-id set (hull -> the whole shell)
    #   pass 2  orient each face against ITS OWN zone, and assign that zone
    #   pass 3  find the interzone pairs `relatedTo` lets EnergyPlus honour
    #   pass 4  the boundary waterfall (see the module docstring)
    for building in middle.buildings:
        surfaces = building.surfaces
        if not surfaces:
            continue          # no envelope -> no zone to own it (the writer skips this building)
        building_surface_ids = {surface.source_id for surface in surfaces}
        source_to_surface_ids = {}
        for surface in surfaces:
            source_to_surface_ids.setdefault(surface.source_id, set()).add(surface.source_id)
            source_to_surface_ids.setdefault(surface.source_gml_id or surface.source_id, set()).add(surface.source_id)

        zone_elements = thermal_zones(doc, doc.get_by_id(building.id)) #Find ThermalZones
        if not zone_elements:
            _single_zone(building)
            continue

        # pass 1: resolve each ThermalZone's OWNED surface-id set. THREE ownership sources,
        # most explicit first: coincidesWithLodXHull -> LoD1 sole zone -> nrg3:thermalBoundary.
        zones = []
        for zone_element in zone_elements:
            name = zone_element.get(GML_ID) or f"{building.id}_Zone{len(zones) + 1}"
            coincides = coincides_with_hull(doc, zone_element)
            referenced_ids = []
            if coincides:
                owned_ids = set(building_surface_ids)  # the zone OWNS THE WHOLE SHELL
                ownership_source = "coincidesWithLodXHull"
            elif owns_whole_lod1_hull(doc, building, zone_elements, zone_element):
                owned_ids = set(building_surface_ids)  # the sole LoD1 zone IS the thermal hull
                ownership_source = ("LoD1 whole-hull assignment (sole ThermalZone, no "
                                    "thermalBoundary, raw LoD1 solid faces)")
            else:
                owned_ids = set()
                referenced_ids = boundary_surface_ids(doc, zone_element) # Read each zone’s owned surfaces from nrg3:thermalBoundary
                for sid in referenced_ids:
                    owned_ids.update(source_to_surface_ids.get(sid, set()))
                ownership_source = "nrg3:thermalBoundary"
            zones.append({"name": name, "ids": owned_ids,
                          "provenance": {"name": f"{name} (from ThermalZone gml:id)",
                                         "ownership": f"{ownership_source}: owns "
                                                      f"{len(owned_ids)} surface(s)"}})
        building.zones = [Zone(name=zone["name"], provenance=zone["provenance"])
                          for zone in zones]

        # Zone centroid = the reference point a face is oriented AWAY from. Computed ONCE,
        # before any re-orientation (re-orienting only REVERSES a ring, never moves its
        # points, so the centroid is stable either way — precomputing makes that obvious).
        surfaces_by_id = {surface.source_id: surface for surface in surfaces}

        def zone_centroid(zone):
            zone_points = [point for sid in zone["ids"] if sid in surfaces_by_id
                           for point in surfaces_by_id[sid].points]
            return rings.centroid(zone_points) if zone_points else np.zeros(3)

        zone_centroids = {zone["name"]: zone_centroid(zone) for zone in zones}

        # ---- pass 2: orient each face against ITS OWN zone, and assign that zone ----------
        owners_by_surface = {}
        for surface in surfaces: # Count how many zones own each surface
            owners = [zone for zone in zones if surface.source_id in zone["ids"]]
            owners_by_surface[surface.source_id] = owners

            # ORIENTATION (E+ convention): a face's outward normal points AWAY FROM THE ZONE
            # THAT OWNS IT. building_surfaces.process_surfaces could only orient against the
            # BUILDING centroid, which is the wrong reference for an INTERIOR horizontal slab:
            # both of its faces then get the SAME normal, so a zone ends up with two Floors and
            # no Ceiling (wrong Zone Floor Area + "unenclosed zone" view-factor warnings).
            # Now that ownership is known, re-orient against the owning zone and re-resolve
            # Floor/Ceiling. Single-zone buildings are unaffected (zone centroid = building's).
            if owners:
                oriented, normal = rings.orient_outward(surface.points,
                                                        zone_centroids[owners[0]["name"]])
                surface.points = [list(point) for point in oriented]
                if surface.surface_type in ("Floor", "Ceiling"):
                    surface.surface_type = floor_or_ceiling(normal[2])
                surface.provenance["surface_type"] = (
                    f"{surface.surface_type} (outward normal from owning zone "
                    f"{owners[0]['name']}, z={normal[2]:.3f})")
                surface.zone = owners[0]["name"]
                surface.provenance["zone"] = (f"assigned to {owners[0]['name']} "
                                              f"({len(owners)} owning ThermalZone(s))")
            else:                                                # orphan -> never drop geometry
                warn(f"surface {surface.source_id} in no ThermalZone; placed in {zones[0]['name']}")
                surface.zone = zones[0]["name"]
                surface.provenance["zone"] = f"assigned to {zones[0]['name']} (orphan fallback)"

        # ---- pass 3: which faces form a REAL EnergyPlus interzone pair? -------------------
        # Needs every surface's zone, so it runs AFTER pass 2.
        zone_of = {surface.source_id: surface.zone for surface in surfaces}
        pairs = _interzone_pairs(surfaces, zone_of)

        # ---- pass 4: the boundary waterfall (most explicit first) -------------------------
        for surface in surfaces:
            owners = owners_by_surface[surface.source_id]
            surface.boundary_object = ""

            if not detailed_interior and is_interior(surface.type_name):  # 0. FAST workflow
                # Interior zone-to-zone faces are made Adiabatic and never paired, to keep the
                # E+ model cheap. --detailed-interior skips this so heat can cross (rung 3).
                surface.boundary = "Adiabatic"
                note = "Adiabatic (fast workflow; pass --detailed-interior for heat transfer)"

            elif surface.is_adiabatic:                           # 1. the file says so -> wins
                # Explicit isAdiabatic=true beats adjacency EVEN in detailed mode (trust the file).
                surface.boundary = "Adiabatic"
                note = "Adiabatic (citygml nrg3:bdgBdrySurfIsAdiabatic=true)"

            elif len(owners) >= 2:                               # 2. ONE surface owned by TWO zones
                # We NEVER synthesize a twin surface. Energy ADE models an interzone boundary as
                # TWO real surfaces (one per zone) linked by nrg3:relatedTo — see id_building_11
                # and id_building_9-10. E+ A7 must name a surface that exists in this IDF, so a
                # lone surface owned by two zones cannot form a pair: warn and keep it Adiabatic.
                warn(f"surface {surface.source_id} is owned by {len(owners)} ThermalZones; "
                     f"Energy ADE expects two surfaces linked by nrg3:relatedTo — using Adiabatic")
                surface.boundary = "Adiabatic"
                note = (f"Adiabatic (one surface owned by {len(owners)} zones; no relatedTo "
                        f"partner — EnergyPlus needs two real surfaces)")

            elif surface.source_id in pairs:                     # 3. schema-native interzone pair
                partner = pairs[surface.source_id]                #    (both faces already exist)
                surface.boundary = "Surface"        # OVERWRITES the "Adiabatic" default
                surface.boundary_object = partner
                note = (f"Surface -> {partner} (relatedTo adjacent; partner surface is in this "
                        f"IDF, zone {zone_of[partner]})")

            elif surface.adjacent_ids:                           # 4. adjacency E+ cannot honour
                # The target is not a usable partner, so Adiabatic. NORMALLY that is right: the
                # target lives in ANOTHER building -> another IDF (10x on Alderaan), and E+ cannot
                # reference a surface that is absent from this file.
                
                # TODO / KNOWN RISK (deliberately not handled — keeps adjacency.py simple):
                #   Alderaan models each party wall TWICE: a `bldg:boundedBy` "shell" copy and a
                #   `nrg3:thermalBoundary` "thermal" copy. select_surface_path emits only ONE of
                #   them. Both samples keep their links inside a single layer (measured:
                #   thermal->thermal 14, shell->shell 12, cross-layer 0; `coincidesWithLodXHull=true`
                #   merely flips BOTH sides to the shell layer), so the partner is always found.
                #   BUT a future file whose THERMAL surface points at the SHELL twin of a wall in
                #   THIS SAME building would land here and SILENTLY lose a real interzone pair.
                #   To fix: resolve the target element, compare its owning bldg:Building with this
                #   building, and either map the twin back to the emitted surface, or warn.
                surface.boundary = "Adiabatic"
                note = (f"Adiabatic (adjacent {surface.adjacent_ids[0]} is not a surface of a "
                        f"different zone in this IDF)")

            else:                                                # 5. surface-type default
                note = f"{surface.boundary} (surface-type default)"

            surface.provenance["boundary"] = note
    return middle


def _demo(path=None):
    from .reader import build_middle_layer
    doc = xml_io.CityGMLDoc(path)
    middle = build_middle_layer(doc)            # build_middle_layer already calls assign_zones
    for building in middle.buildings:
        zone_names = [zone.name for zone in building.zones]
        print(f"  {building.id}: {len(zone_names)} zone(s) {zone_names}")
        for surface in building.surfaces:
            if surface.boundary == "Surface":
                print(f"      interzone {surface.source_id:<24} {surface.surface_type:<8}"
                      f" zone={surface.zone:<22} <-> {surface.boundary_object}")


if __name__ == "__main__":
    _demo(sys.argv[1] if len(sys.argv) > 1 else None)
