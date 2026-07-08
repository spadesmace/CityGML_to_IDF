
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

# used for checking  geometry in middle layer , window area reporting 
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


def min_corner(ring_list):
    """(minx, miny, minz) across every point in a LIST OF RINGS — the origin corner a
    building is recentred against (min corner -> (0,0), floor -> z=0). Coordinates are
    assumed metric; there is no CRS reprojection."""
    allpts = np.array([p for ring in ring_list for p in ring], dtype=float)
    return allpts.min(axis=0)


def simplify_to_quad(points):
    """is mainly for windows because EnergyPlus fenestration surfaces can only have up to 4 vertices."""
    pts = drop_closing_point(points)
    if len(pts) <= 4:
        return [tuple(float(c) for c in p) for p in pts]
    normal = unit_normal(pts)
    if float(np.linalg.norm(normal)) == 0.0:
        return [tuple(float(c) for c in p) for p in pts]     # degenerate -> leave as-is
    pts_arr = np.array(pts, dtype=float)
    origin = pts_arr[0]
    # any vector not parallel to the normal, projected into the plane -> in-plane axis u
    ref = np.array([1.0, 0.0, 0.0]) if abs(float(np.dot(normal, [1.0, 0.0, 0.0]))) < 0.9 \
        else np.array([0.0, 1.0, 0.0])
    u = ref - float(np.dot(ref, normal)) * normal
    u /= np.linalg.norm(u)
    v = np.cross(normal, u)                                   # completes the right-handed basis
    coords = [(float((p - origin) @ u), float((p - origin) @ v)) for p in pts_arr]
    min_u, max_u = min(a for a, _ in coords), max(a for a, _ in coords)
    min_v, max_v = min(b for _, b in coords), max(b for _, b in coords)
    corners = [(min_u, min_v), (max_u, min_v), (max_u, max_v), (min_u, max_v)]
    quad = [origin + a * u + b * v for (a, b) in corners]
    if float(np.dot(unit_normal(quad), normal)) < 0.0:       # match original winding
        quad = list(reversed(quad))
    return [tuple(float(c) for c in p) for p in quad]

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
