"""
geometry/rings.py — math on a single polygon ring. Pure numpy, no XML.

A "ring" is the list of (x, y, z) points returned by citygml.xml_io.read_pos_list.
CityGML rings are CLOSED (last point == first). These helpers give EnergyPlus the
three things it needs per surface: the polygon's NORMAL, its AREA, and a winding
oriented so the normal points OUTWARD (away from the zone). We never trust the
exporter's winding — we compute and flip if needed (the golden rule).
"""

from __future__ import annotations

import numpy as np


def drop_closing_point(points):
    """CityGML repeats the first vertex at the end to close the ring; EnergyPlus
    lists it once. Drop the duplicate if present.

    Compare with an ABSOLUTE tolerance (rtol=0): a closing point is the *exact*
    same vertex, so ~1 micron is plenty. np.allclose's default RELATIVE tolerance
    (rtol=1e-5) is unsafe on large UTM coordinates — on a 5.3e6 m northing it
    treats points ~50 m apart as equal and would collapse the polygon."""
    if len(points) >= 2 and np.allclose(points[0], points[-1], rtol=0.0, atol=1e-6):
        return [tuple(p) for p in points[:-1]]
    return [tuple(p) for p in points]


#compute the geometric arrow 
def newell_normal(points):
    """Polygon normal by Newell's method — robust for any polygon orientation and
    any vertex count, and stable for slightly non-planar rings. NOT normalised:
    its length equals TWICE the polygon area, which polygon_area() reuses.
     subtraction kills the big offset"""
    pts = drop_closing_point(points)
    n = np.zeros(3)
    m = len(pts)
    for i in range(m):
        x0, y0, z0 = pts[i]
        x1, y1, z1 = pts[(i + 1) % m]
        n[0] += (y0 - y1) * (z0 + z1)
        n[1] += (z0 - z1) * (x0 + x1)
        n[2] += (x0 - x1) * (y0 + y1)
    return n


def polygon_area(points):
    """Polygon area = half the Newell normal's length. True 3D area, so it is
    correct for tilted roofs and triangular gable walls, not just flat ground."""
    return 0.5 * float(np.linalg.norm(newell_normal(points)))


def unit_normal(points):
    """Newell normal scaled to length 1 (zeros for a degenerate ring). division kills the magnitude (unit_normal)"""
    n = newell_normal(points)
    length = np.linalg.norm(n)
    return n / length if length > 0 else n


def centroid(points):
    """Average of the unique vertices — the face's middle point (np.array of 3)."""
    pts = np.array(drop_closing_point(points), dtype=float)
    return pts.mean(axis=0)

# decide in vs out using a reference
def orient_outward(points, interior_point):
    """Return (ring, outward_unit_normal) with the ring wound so its normal points
    AWAY from interior_point (the zone centroid).

    Logic: the vector from the interior point to this face's centre should agree
    with the normal (dot > 0). If it doesn't, the normal points inward, so we
    reverse the ring (which flips the normal)."""
    pts = drop_closing_point(points)
    n = unit_normal(pts)
    to_face = centroid(pts) - np.asarray(interior_point, dtype=float)
    if float(np.dot(n, to_face)) < 0.0: # # arrow points back at inside?
        pts = list(reversed(pts)) # # flip it
        n = -n
    return pts, n
