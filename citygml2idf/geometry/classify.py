"""
 give a face a ROLE (wall / roof / ground) from its geometry
alone.
CityGML buildings arrive at different levels of detail:

  * LOD2 / LOD3   -> the file LABELS each face (<bldg:WallSurface>, ...), so we
                    just read the label.
  * LOD1 / LOD1.2 -> the building is a bare BOX of polygons (a `lod1Solid`) with
                    NO labels. Nothing says which face is wall / roof / floor.
"""

from __future__ import annotations

import math

# --- thresholds in DEGREES (the physical, human-readable unit) ----------------
# tilt <= 60deg -> roof, tilt >= 120deg -> ground, otherwise (within 30deg of vertical)
# -> wall. Tunable in ONE place.

# Because real surfaces are never exactly flat
ROOF_MAX_TILT_DEG = 60.0       # tilt <= 60deg  -> faces the sky   -> roof
GROUND_MIN_TILT_DEG = 120.0    # tilt >= 120deg -> faces the soil  -> ground


def _clamped_nz(unit_normal):
    """nz = the up-component of the normal, clamped to [-1, 1] so arccos is always
    valid (floating-point can push a unit value a hair past +/-1)."""
    nz = float(unit_normal[2])
    return max(-1.0, min(1.0, nz))


def tilt_degrees(unit_normal):
    """TILT angle of a face = arccos(nz), in degrees.
        0deg   -> normal points straight up    (flat roof / ceiling)
        90deg  -> normal horizontal            (vertical wall)
        180deg -> normal points straight down  (floor on the ground)
    See the module docstring for why cos(tilt) = nz."""
    return math.degrees(math.acos(_clamped_nz(unit_normal)))


def classify_by_normal(unit_normal,
                       roof_max_tilt=ROOF_MAX_TILT_DEG,
                       ground_min_tilt=GROUND_MIN_TILT_DEG):
    """Return 'roof' | 'ground' | 'wall' from an OUTWARD unit normal, by TILT.

    Step by step (the whole logic, made explicit):
        1. tilt = arccos(nz)             how tipped the face is, in degrees
        2. tilt <=  60deg  -> 'roof'     faces the sky
        3. tilt >= 120deg  -> 'ground'   faces the soil (floor on the ground)
        4. otherwise       -> 'wall'     roughly vertical
    """
    tilt = tilt_degrees(unit_normal)
    if tilt <= roof_max_tilt:
        return "roof"
    if tilt >= ground_min_tilt:
        return "ground"
    return "wall"
