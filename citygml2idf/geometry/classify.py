"""Give a face a ROLE (wall / roof / ground) from its direction alone.

Used where the file gives no usable type: LoD1 faces (a bare lod1Solid / lod1MultiSurface:
Energy ADE Table 1, no thermal boundaries) and a LoD2/3 surface whose type has no mapping
(e.g. ClosureSurface). The two thresholds are our choice; no spec gives one.
"""

from __future__ import annotations

import math

# tilt = the angle between the outward normal and straight up; between the two -> wall
ROOF_MAX_TILT_DEG = 60.0       # tilt <= 60 deg  -> faces the sky  -> roof
GROUND_MIN_TILT_DEG = 120.0    # tilt >= 120 deg -> faces the soil -> ground


def tilt_degrees(unit_normal):
    """The face's tilt in degrees: 0 = facing up, 90 = vertical, 180 = facing down.

    For a unit normal cos(tilt) = its z part, so tilt = acos(nz).
    """
    nz = max(-1.0, min(1.0, float(unit_normal[2])))     # float noise can pass +/-1
    return math.degrees(math.acos(nz))


def classify_by_normal(unit_normal):
    """'roof', 'ground' or 'wall' for an OUTWARD unit normal, by its tilt."""
    tilt = tilt_degrees(unit_normal)
    if tilt <= ROOF_MAX_TILT_DEG:
        return "roof"
    if tilt >= GROUND_MIN_TILT_DEG:
        return "ground"
    return "wall"
