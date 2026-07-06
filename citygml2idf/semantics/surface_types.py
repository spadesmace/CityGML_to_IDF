"""
semantics/surface_types.py — what each CityGML / Energy ADE surface TYPE means to
EnergyPlus. No XML, no geometry math: just the lookup table + tiny resolvers.

EnergyPlus has only FOUR Surface_Type keywords — Wall, Roof, Floor, Ceiling —
verified against the EnergyPlus 23.1 schema (templates/Energy+.idd,
BuildingSurface:Detailed field A2). The many CityGML/ADE thematic classes collapse
onto those four and differ mainly in their Outside_Boundary_Condition (field A6).
The full allowed keyword lists from that IDD are kept below as a reference
(EPLUS_SURFACE_TYPES and EPLUS_BOUNDARY_CONDITIONS) so we always map to a value
EnergyPlus actually accepts.

The COMPLETE list of boundary-surface classes (straight from the XSDs) is below.
Types we have DECIDED are active in SURFACE_TYPES. Types we have NOT decided yet
are listed but COMMENTED OUT (#), named, so we MUST come back here and choose
their role / Surface_Type / boundary — we never guess one inside the logic.

Match by LOCAL name (the namespace, bldg vs nrg3, is resolved by the reader).
"""

from __future__ import annotations

from collections import namedtuple

# role         = our writer-neutral label, kept in the middle layer
# surface_type = EnergyPlus Surface_Type: "Wall" | "Roof" | "Floor" | "Ceiling"
#                | "FloorOrCeiling" = a DECISION, not a TODO: a horizontal interface is
#                  a Ceiling to the zone below and a Floor to the zone above, so the
#                  type NAME cannot fix it — the GEOMETRY does. Resolved at runtime from
#                  the outward normal (up->Ceiling, down->Floor) in resolve_floor_ceiling,
#                  and flipped for the partner of an interzone pair in zones.py.
# boundary     = Outside_Boundary_Condition: "Outdoors" | "Ground" | "Adiabatic"
#                This is the DEFAULT for a single-owner / single-zone face. For a
#                face SHARED by two modelled zones, model/zones.py OVERRIDES this to
#                "Surface" and adds an explicit reciprocal partner (G12 — IMPLEMENTED).
SurfaceRule = namedtuple("SurfaceRule", ["role", "surface_type", "boundary"])

# --- EnergyPlus 23.1 allowed keywords, verbatim from templates/Energy+.idd ------
EPLUS_SURFACE_TYPES = ("Floor", "Wall", "Ceiling", "Roof")
# BuildingSurface:Detailed > Outside Boundary Condition — the FULL allowed list (kept
# for reference); the comment below says which ones THIS pipeline actually emits.
EPLUS_BOUNDARY_CONDITIONS = (
    "Adiabatic", "Surface", "Zone", "Outdoors", "Foundation", "Ground",
    "GroundFCfactorMethod", "OtherSideCoefficients", "OtherSideConditionsModel",
    "GroundSlabPreprocessorAverage", "GroundSlabPreprocessorCore",
    "GroundSlabPreprocessorPerimeter", "GroundBasementPreprocessorAverageWall",
    "GroundBasementPreprocessorAverageFloor", "GroundBasementPreprocessorUpperWall",
    "GroundBasementPreprocessorLowerWall",
)
# WHAT THIS PIPELINE EMITS:
#   Surface_Type     : {Wall, Roof, Floor, Ceiling}  ("FloorOrCeiling" resolved first)
#   Boundary (BC)    : {Outdoors, Ground, Adiabatic, Surface}
#                        - Outdoors/Ground/Adiabatic = exterior + default interior
#                        - Surface = interzone reciprocal PAIR (G12, IMPLEMENTED in zones.py)
#   "Zone" = documented fallback for interzone (unused); all other BCs above stay available.


SURFACE_TYPES = {
    # ---- CityGML 2.0 (bldg:) exterior envelope — role given by the file --------
    "WallSurface":   SurfaceRule("wall",   "Wall",  "Outdoors"),
    "RoofSurface":   SurfaceRule("roof",   "Roof",  "Outdoors"),
    "GroundSurface": SurfaceRule("ground", "Floor", "Ground"),

    # OuterFloor / OuterCeiling — horizontal OUTER-SHELL surfaces exposed to open air
    # Source: CityGML 2.0 (OGC 12-019) OuterFloorSurface / OuterCeilingSurface definitions.
    "OuterFloorSurface":   SurfaceRule("outer_floor",   "Roof",  "Outdoors"),
    "OuterCeilingSurface": SurfaceRule("outer_ceiling", "Floor", "Outdoors"),

    # ---- Energy ADE 3.0 (nrg3:) interior interfaces ---------------------------
    # The "Adiabatic" below is only the DEFAULT (used when a single zone owns the
    # face, or it faces another building). When TWO modelled zones share the face,
    # model/zones.py overrides it to "Surface" + a reciprocal partne
    # The TYPE here still sets Surface_Type (Wall, or Floor/Ceiling
    # by normal)and will use  resolve_floor_ceiling(); the ZONE COUNT sets the boundary at runtime.
    "PartyWallSurface":         SurfaceRule("party_wall",        "Wall",          "Adiabatic"),
    "IntermediateFloorSurface": SurfaceRule("intermediate_floor","FloorOrCeiling","Adiabatic"),
    "AtticFloorSurface":        SurfaceRule("attic_floor",       "FloorOrCeiling","Adiabatic"),
    "BasementCeilingSurface":   SurfaceRule("basement_ceiling",  "FloorOrCeiling","Adiabatic"),

    # ---- CityGML 2.0 (bldg:) LoD4 room-INTERIOR surfaces ----------------------
    # Same generic-adiabatic treatment as the ADE interfaces above: they bound ONE
    # conditioned volume, so the DEFAULT boundary is Adiabatic; when two modelled
    # zones share the face, zones.py overrides it to "Surface" (interzone pair).
    # Horizontal -> FloorOrCeiling (resolved by the normal); vertical -> Wall.
    "FloorSurface":        SurfaceRule("interior_floor",   "FloorOrCeiling", "Adiabatic"),  # interior floor between storeys
    "CeilingSurface":      SurfaceRule("interior_ceiling", "FloorOrCeiling", "Adiabatic"),  # interior ceiling between storeys
    "InteriorWallSurface": SurfaceRule("interior_wall",    "Wall",           "Adiabatic"),  # interior partition wall

    # ===========================================================================
    # DEFERRED — ClosureSurface: a VIRTUAL face that only CLOSES an
    # open volume (the open side of a loggia, the top of a courtyard). It has NO real
    # material, and E+ BuildingSurface:Detailed REQUIRES a Construction_Name (IDD field
    # A3) we would have to INVENT. Left undecided for now. (Being unmapped, the reader
    # currently keeps it via geometry classification, like any other unknown label.)
    
    # "ClosureSurface":      SurfaceRule( ... ),  # Not  decide (+ a default construction)
    # ===========================================================================
}


# For the LOD1 fallback: geometry.classify returns a generic ROLE ("wall" /
# "roof" / "ground") instead of a type name. Those exterior roles reuse the same
# EnergyPlus rule as their named CityGML counterparts.
ROLE_RULES = {
    "wall":   SURFACE_TYPES["WallSurface"],
    "roof":   SURFACE_TYPES["RoofSurface"],
    "ground": SURFACE_TYPES["GroundSurface"],
}


def rule_for_type(type_name):
    """SurfaceRule for a CityGML/ADE surface LOCAL name, or None when the type is
    unknown/undecided (the caller warns and skips — never crashes)."""
    return SURFACE_TYPES.get(type_name)


def rule_for_role(role):
    """SurfaceRule for a geometry-classified exterior role (LOD1 path), or None."""
    return ROLE_RULES.get(role)


def resolve_floor_ceiling(surface_type, normal_z):
    """Turn a 'FloorOrCeiling' rule into a concrete EnergyPlus keyword using the
    outward normal's z: normal pointing up -> Ceiling, pointing down -> Floor.
    Other surface_types pass through unchanged."""
    if surface_type != "FloorOrCeiling":
        return surface_type
    return "Ceiling" if normal_z > 0 else "Floor"


def sun_wind_exposure(boundary):
    """EnergyPlus Sun/Wind exposure follows the boundary: only Outdoors is exposed."""
    if boundary == "Outdoors":
        return "SunExposed", "WindExposed"
    return "NoSun", "NoWind"
