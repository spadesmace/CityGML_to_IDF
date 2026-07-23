
from __future__ import annotations

from collections import namedtuple

# role         = our writer-neutral label, kept in the middle layer
# surface_type = EnergyPlus Surface_Type: "Wall" | "Roof" | "Floor" | "Ceiling"
#                | "FloorOrCeiling" = a DECISION, not a TO DO: a horizontal interface is
#                  a Ceiling to the zone below and a Floor to the zone above, so the
#                  type NAME cannot fix it — the GEOMETRY does. Resolved at runtime from
#                  the outward normal (up->Ceiling, down->Floor) in resolve_floor_ceiling,
#                  and flipped for the partner of an interzone pair in zones.py.
# boundary     = Outside_Boundary_Condition: "Outdoors" | "Ground" | "Adiabatic"
#                NOTE This is the DEFAULT for a single-owner / single-zone face. For a
#                face SHARED by two modelled zones, model/zones.py OVERRIDES this to
#                "Surface" and adds an explicit reciprocal partner
SurfaceRule = namedtuple("SurfaceRule", ["role", "surface_type", "boundary"])

# --- EnergyPlus 23.1 allowed keywords, verbatim from Energy+.idd 
EPLUS_SURFACE_TYPES = ("Floor", "Wall", "Ceiling", "Roof")
# BuildingSurface:Detailed > Outside Boundary Condition —
EPLUS_BOUNDARY_CONDITIONS = (
    "Adiabatic", "Surface", "Outdoors", "Ground")


SURFACE_TYPES = {
    # ---- CityGML 2.0 (bldg:) exterior envelope — role given by the file
    "WallSurface":   SurfaceRule("wall",   "Wall",  "Outdoors"),
    "RoofSurface":   SurfaceRule("roof",   "Roof",  "Outdoors"),
    "GroundSurface": SurfaceRule("ground", "Floor", "Ground"),

    # OuterFloor / OuterCeiling — horizontal OUTER-SHELL surfaces exposed to open air
    # Source: CityGML 2.0 (OGC 12-019) OuterFloorSurface / OuterCeilingSurface definitions.
    "OuterFloorSurface":   SurfaceRule("outer_floor",   "Roof",  "Outdoors"),
    "OuterCeilingSurface": SurfaceRule("outer_ceiling", "Floor", "Outdoors"),

    # ---- Energy ADE 3.0 (nrg3:) interior interfaces
    "PartyWallSurface":         SurfaceRule("party_wall",        "Wall",          "Adiabatic"),
    "IntermediateFloorSurface": SurfaceRule("intermediate_floor","FloorOrCeiling","Adiabatic"),
    "AtticFloorSurface":        SurfaceRule("attic_floor",       "FloorOrCeiling","Adiabatic"),
    "BasementCeilingSurface":   SurfaceRule("basement_ceiling",  "FloorOrCeiling","Adiabatic"),

    # ---- CityGML 2.0 (bldg:)
    "FloorSurface":        SurfaceRule("interior_floor",   "FloorOrCeiling", "Adiabatic"),  # interior floor between storeys
    "CeilingSurface":      SurfaceRule("interior_ceiling", "FloorOrCeiling", "Adiabatic"),  # interior ceiling between storeys
    "InteriorWallSurface": SurfaceRule("interior_wall",    "Wall",           "Adiabatic"),  # interior partition wall
    
    # "ClosureSurface":      SurfaceRule( ... ),  # Not  decide (+ a default construction)
  
}


# For the LOD1 fallback: geometry.classify returns a generic ROLE ("wall" /
# "roof" / "ground") instead of a type name. Those exterior roles reuse the same
# EnergyPlus rule as their named CityGML counterparts.
ROLE_RULES = {
    "wall":   SURFACE_TYPES["WallSurface"],
    "roof":   SURFACE_TYPES["RoofSurface"],
    "ground": SURFACE_TYPES["GroundSurface"],
}

# Interior zone-to-zone interfaces INSIDE one building. Only these are touched by the
# detailed/fast indoor switch in model/zones.py (fast -> Adiabatic; detailed -> Surface pair).
# Exterior Wall/Roof/Ground and LoD1 "classified" faces are never here, so the switch can
# never make an outdoor face adiabatic.
INTERIOR_TYPES = frozenset({
    "PartyWallSurface", "IntermediateFloorSurface", "AtticFloorSurface",
    "BasementCeilingSurface", "FloorSurface", "CeilingSurface", "InteriorWallSurface",
})


def is_interior(type_name):
    """True if the surface is an indoor zone-to-zone interface (not exterior envelope)."""
    return type_name in INTERIOR_TYPES


def rule_for_type(type_name):
    """SurfaceRule for a CityGML/ADE surface LOCAL name, or None when the type is
    unknown/undecided (the caller warns and skips — never crashes)."""
    return SURFACE_TYPES.get(type_name)


def rule_for_role(role):
    """SurfaceRule for a geometry-classified exterior role (LOD1 path), or None."""
    return ROLE_RULES.get(role)


def floor_or_ceiling(normal_z):
    """The EnergyPlus Surface_Type of a HORIZONTAL face, from its OUTWARD normal's z:
    normal pointing UP (the zone lies below the face) -> Ceiling; pointing DOWN -> Floor.

    The SAME physical slab is a Ceiling to the zone BELOW it and a Floor to the zone
    ABOVE it, so the normal must be taken relative to the OWNING ZONE (model/zones.py),
    never the building — otherwise both faces of an interior slab come out identical."""
    return "Ceiling" if normal_z > 0 else "Floor"


def resolve_floor_ceiling(surface_type, normal_z):
    """Turn a 'FloorOrCeiling' rule into a concrete EnergyPlus keyword using the
    outward normal's z. Other surface_types pass through unchanged."""
    if surface_type != "FloorOrCeiling":
        return surface_type
    return floor_or_ceiling(normal_z)


def sun_wind_exposure(boundary):
    """EnergyPlus Sun/Wind exposure follows the boundary: only Outdoors is exposed."""
    if boundary == "Outdoors":
        return "SunExposed", "WindExposed"
    return "NoSun", "NoWind"
