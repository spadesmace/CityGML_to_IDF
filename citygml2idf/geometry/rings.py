"""
geometry/rings.py — pure math on one polygon ring (a list of (x, y, z) points).

No XML and no EnergyPlus here: the readers hand in points, these functions return numbers or
re-ordered points. A ring's DIRECTION is its vertex order (GML3 / CityGML 2.0: counter-clockwise
seen from the side the normal points to), and EnergyPlus GlobalGeometryRules uses the same rule.
"""

from __future__ import annotations

import numpy as np


def drop_closing_point(points):
    """The ring without its repeated last point.

    Parameters
    ----------
    points : sequence of (x, y, z)
        A ring; CityGML repeats the first vertex at the end, EnergyPlus lists it once.

    Returns
    -------
    list of tuple
        The points, the closing duplicate removed when present.

    Notes
    -----
    Compared with an ABSOLUTE tolerance (rtol=0, 1 micron): a closing point is the exact same
    vertex. numpy's default RELATIVE tolerance would treat points ~50 m apart as equal on a
    5.3e6 m UTM northing and collapse the polygon.
    """
    if len(points) >= 2 and np.allclose(points[0], points[-1], rtol=0.0, atol=1e-6):
        return [tuple(p) for p in points[:-1]]
    return [tuple(p) for p in points]


def normal_vector(points):
    """The ring's normal by Newell's method, NOT scaled to length 1.

    Parameters
    ----------
    points : sequence of (x, y, z)
        A ring (closing point optional).

    Returns
    -------
    numpy.ndarray
        3 numbers. Direction = the ring's normal from its vertex order; length = 2 x area.

    Notes
    -----
    Newell's method works for any vertex count and stays stable for slightly non-planar rings.
    It sums coordinate DIFFERENCES, so large site coordinates do not lose precision.
    """
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
    """The ring's true 3D area.

    Parameters
    ----------
    points : sequence of (x, y, z)
        A ring (closing point optional).

    Returns
    -------
    float
        Area in the units of the coordinates squared (m2 for metric data).

    Notes
    -----
    Half the length of `normal_vector`, so it is right for tilted roofs and triangular gable
    walls, not just for flat ground.
    """
    return 0.5 * float(np.linalg.norm(normal_vector(points)))


def unit_normal(points):
    """The ring's normal scaled to length 1.

    Parameters
    ----------
    points : sequence of (x, y, z)
        A ring (closing point optional).

    Returns
    -------
    numpy.ndarray
        3 numbers of length 1; all zeros for a degenerate ring (no area).
    """
    n = normal_vector(points)
    length = np.linalg.norm(n)
    return n / length if length > 0 else n


def min_corner(ring_list):
    """The lowest x, y and z over every point of several rings.

    Parameters
    ----------
    ring_list : list
        A building's rings.

    Returns
    -------
    numpy.ndarray
        (min x, min y, min z): the corner a building is recentred to, so its own origin is
        (0, 0) and its floor sits at z = 0. Coordinates are assumed metric (no reprojection).
    """
    allpts = np.array([p for ring in ring_list for p in ring], dtype=float)
    return allpts.min(axis=0)


def bounding_rectangle(points):
    """The polygon's bounding rectangle in its own plane, for a ring with more than 4 vertices.

    Parameters
    ----------
    points : sequence of (x, y, z)
        A window ring (closing point optional).

    Returns
    -------
    list of tuple
        The ring itself when it has 3 or 4 vertices (or no area); otherwise the 4 corners of
        its in-plane bounding rectangle, wound the same way as the input.

    Notes
    -----
    EnergyPlus FenestrationSurface:Detailed allows 3 or 4 vertices (IDD N3, maximum 4), so a
    window with more corners (e.g. an arch) is replaced by the rectangle that contains it.
    """
    pts = drop_closing_point(points)
    if len(pts) <= 4:
        return [tuple(float(c) for c in p) for p in pts]
    normal = unit_normal(pts)
    if float(np.linalg.norm(normal)) == 0.0:
        return [tuple(float(c) for c in p) for p in pts]
    pts_arr = np.array(pts, dtype=float)
    origin = pts_arr[0]
    # two axes u, v inside the polygon's plane: any direction not parallel to the normal,
    # minus its normal part, gives u; v = normal x u completes the right-handed pair
    ref = np.array([1.0, 0.0, 0.0]) if abs(float(np.dot(normal, [1.0, 0.0, 0.0]))) < 0.9 \
        else np.array([0.0, 1.0, 0.0])
    u = ref - float(np.dot(ref, normal)) * normal
    u /= np.linalg.norm(u)
    v = np.cross(normal, u)
    coords = [(float((p - origin) @ u), float((p - origin) @ v)) for p in pts_arr]
    min_u, max_u = min(a for a, _ in coords), max(a for a, _ in coords)
    min_v, max_v = min(b for _, b in coords), max(b for _, b in coords)
    corners = [(min_u, min_v), (max_u, min_v), (max_u, max_v), (min_u, max_v)]
    rectangle = [origin + a * u + b * v for (a, b) in corners]
    if float(np.dot(unit_normal(rectangle), normal)) < 0.0:      # keep the input's winding
        rectangle = list(reversed(rectangle))
    return [tuple(float(c) for c in p) for p in rectangle]


def face_like(points, reference_normal):
    """The ring wound so that its normal agrees with a reference normal.

    Parameters
    ----------
    points : sequence of (x, y, z)
        A window or door ring (closing point optional).
    reference_normal : sequence of 3 floats
        The normal of the wall the window sits in.

    Returns
    -------
    (list of tuple, numpy.ndarray)
        The ring (reversed only if it faced the other way) and its unit normal.

    Notes
    -----
    A window lies inside its wall and must face the same way: EnergyPlus reads every polygon
    as counter-clockwise seen from OUTSIDE (GlobalGeometryRules), and a window facing against
    its wall crashes EnergyPlus.
    """
    pts = drop_closing_point(points)
    n = unit_normal(pts)
    if float(np.dot(n, np.asarray(reference_normal, dtype=float))) < 0.0:
        pts = list(reversed(pts))
        n = -n
    return pts, n
