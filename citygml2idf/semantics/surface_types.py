"""CityGML / Energy ADE surface type -> role, E+ Surface_Type and DEFAULT boundary.

Sources: CityGML 2.0 building module (the bldg: boundary surfaces), Energy ADE §4.3.2 (the
four nrg3: surfaces), IDD BuildingSurface:Detailed A2 Surface Type / A6 Outside Boundary
Condition. model/zones.py decides the final boundary (faces between zones).
"""

from __future__ import annotations

from collections import namedtuple

# role         = our writer-neutral label, kept in the middle layer
# surface_type = E+ Surface_Type: "Wall" | "Roof" | "Floor" | "Ceiling", or "FloorOrCeiling"
#                for a slab: its type name cannot say which, its own normal does
#                (resolve_floor_ceiling)
# boundary     = the DEFAULT Outside_Boundary_Condition: "Outdoors" | "Ground" | "Adiabatic";
#                model/zones.py decides the final one (e.g. "Surface" for a pair between zones)
SurfaceRule = namedtuple("SurfaceRule", ["role", "surface_type", "boundary"])


SURFACE_TYPES = {
    # ---- CityGML 2.0 (bldg:) exterior envelope — role given by the file
    "WallSurface":   SurfaceRule("wall",   "Wall",  "Outdoors"),
    "RoofSurface":   SurfaceRule("roof",   "Roof",  "Outdoors"),
    "GroundSurface": SurfaceRule("ground", "Floor", "Ground"),

    # OuterFloor / OuterCeiling — horizontal OUTER-SHELL surfaces exposed to open air
    # Source: CityGML 2.0 (OGC 12-019) OuterFloorSurface / OuterCeilingSurface definitions.
    "OuterFloorSurface":   SurfaceRule("outer_floor",   "Roof",  "Outdoors"),
    "OuterCeilingSurface": SurfaceRule("outer_ceiling", "Floor", "Outdoors"),

    # ---- Energy ADE 3.0 (nrg3:) interior interfaces, §4.3.2
    "PartyWallSurface":         SurfaceRule("party_wall",        "Wall",          "Adiabatic"),
    "IntermediateFloorSurface": SurfaceRule("intermediate_floor","FloorOrCeiling","Adiabatic"),
    "AtticFloorSurface":        SurfaceRule("attic_floor",       "FloorOrCeiling","Adiabatic"),
    "BasementCeilingSurface":   SurfaceRule("basement_ceiling",  "FloorOrCeiling","Adiabatic"),

    # ---- CityGML 2.0 (bldg:) interior types: LoD4 only in CityGML 2.0 (OGC 12-019), kept
    "FloorSurface":        SurfaceRule("interior_floor",   "FloorOrCeiling", "Adiabatic"),  # interior floor between storeys
    "CeilingSurface":      SurfaceRule("interior_ceiling", "FloorOrCeiling", "Adiabatic"),  # interior ceiling between storeys
    "InteriorWallSurface": SurfaceRule("interior_wall",    "Wall",           "Adiabatic"),  # interior partition wall

    # ClosureSurface is not mapped: building_surfaces classifies it by its normal + a warning
}


# A face classified by its direction (geometry/classify.py: a LoD1 face, or a type that is not
# mapped) takes the rule of its named CityGML counterpart.
ROLE_RULES = {
    "wall":   SURFACE_TYPES["WallSurface"],
    "roof":   SURFACE_TYPES["RoofSurface"],
    "ground": SURFACE_TYPES["GroundSurface"],
}

# Interior zone-to-zone interfaces INSIDE one building: the LoD2/3 faces between zones
# (model/zones.py `_between_zones`; LoD1 faces have no type and use the xlink test there).
# Exterior Wall/Roof/Ground are never here, so FAST mode can never make an outdoor face
# adiabatic.
INTERIOR_TYPES = frozenset({
    "PartyWallSurface", "IntermediateFloorSurface", "AtticFloorSurface",
    "BasementCeilingSurface", "FloorSurface", "CeilingSurface", "InteriorWallSurface",
})


def is_interior(type_name):
    """True if the surface is an indoor zone-to-zone interface (not exterior envelope)."""
    return type_name in INTERIOR_TYPES


def rule_for_type(type_name):
    """The SurfaceRule of a CityGML / ADE type name, or None when the type is not mapped."""
    return SURFACE_TYPES.get(type_name)


def rule_for_role(role):
    """The SurfaceRule of a classify role ('wall' / 'roof' / 'ground'), or None."""
    return ROLE_RULES.get(role)


#  only decides Floor versus Ceiling for slab-type surfaces
def resolve_floor_ceiling(surface_type, normal_z):
    """A 'FloorOrCeiling' rule as Ceiling (outward normal up) or Floor (down); any other
    surface_type is returned unchanged.

    Notes
    -----
    The same slab is a Ceiling to the zone below and a Floor to the zone above. Each zone writes
    its own surface for it, wound out of that zone (the file's winding is kept), so each
    surface's own normal gives the answer.
    """
    if surface_type != "FloorOrCeiling":
        return surface_type
    if normal_z > 0:
        return "Ceiling"
    return "Floor"


def sun_wind_exposure(boundary):
    """EnergyPlus Sun/Wind exposure follows the boundary: only Outdoors is exposed."""
    if boundary == "Outdoors":
        return "SunExposed", "WindExposed"
    return "NoSun", "NoWind"
