"""
geometry/rings.py — pure math on one polygon ring (a list of (x, y, z) points).

No XML and no EnergyPlus here: the readers hand in points, these functions return numbers,
True/False, or points. A ring's DIRECTION is its vertex order (GML3 / CityGML 2.0: counter-clockwise
seen from the side the normal points to), and EnergyPlus GlobalGeometryRules uses the same rule.
"""

from __future__ import annotations

import numpy as np

# E+ wants each corner once
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

# get the direction of each surface
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


# To compare direction roof UP , floor Down, wall side!! 
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

# TO move building to (0,0,0) instead of  reprojection  for GlobalGeometry World E+
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

# It read all windows's points 
def same_area_quad(points):
    """A window ring with more than 4 corners turned into a rectangle of the same area.

    Parameters
    ----------
    points : sequence of (x, y, z)
        A window ring (closing point optional).

    Returns
    -------
    list of tuple
        The ring itself when it has 3 or 4 corners (or no area). Otherwise the 4 corners of a
        rectangle in the window's own plane: centred on the box around the window, with the
        window's own area, facing the same way.

    Notes
    -----
    EnergyPlus FenestrationSurface:Detailed allows 3 or 4 vertices (IDD N3, maximum 4).
    Keeping the area keeps the glass area the file states. A big window under a sloped
    edge can reach past the edge of its wall.
    """
    corners = drop_closing_point(points)
    if len(corners) <= 4:
        return [(float(x), float(y), float(z)) for (x, y, z) in corners]
    normal = unit_normal(corners)
    if float(np.linalg.norm(normal)) == 0.0:          # no area: nothing to turn into a rectangle
        return [(float(x), float(y), float(z)) for (x, y, z) in corners]

    # 1. two directions lying flat in the window's plane: "across" (level) and "up"
    across = np.cross([0.0, 0.0, 1.0], normal)
    if float(np.linalg.norm(across)) < 1e-9:          # a flat window (skylight): use the x axis
        across = np.array([1.0, 0.0, 0.0])
    across = across / np.linalg.norm(across)
    up = np.cross(normal, across)

    # 2. how far each corner lies along "across" and "up", measured from the first corner
    start = np.array(corners[0], dtype=float)
    across_values = []
    up_values = []
    for corner in corners:
        offset = np.array(corner, dtype=float) - start
        across_values.append(float(np.dot(offset, across)))
        up_values.append(float(np.dot(offset, up)))

    # 3. the box around the window: its width, height and centre
    width = max(across_values) - min(across_values)
    height = max(up_values) - min(up_values)
    centre = start + across * (min(across_values) + width / 2) + up * (min(up_values) + height / 2)

    # 4. shrink the box about its centre until it has the window's own area
    scale = float(np.sqrt(polygon_area(corners) / (width * height)))
    half_across = across * (scale * width / 2)
    half_up = up * (scale * height / 2)
    rectangle = [centre - half_across - half_up,
                 centre + half_across - half_up,
                 centre + half_across + half_up,
                 centre - half_across + half_up]

    # 5. face the same way as the window
    if float(np.dot(unit_normal(rectangle), normal)) < 0.0:
        rectangle = list(reversed(rectangle))
    return [(float(x), float(y), float(z)) for (x, y, z) in rectangle]

# ONLY for LOD3 WINDOW : Reverse corner if it faces against the parent wall 
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


# NOTE Used for LoD2 windows: the file gives only an opening ratio, so we draw the window
# ourselves by shrinking the surface toward its middle. That only works on a surface with
# no dent; a dented surface gets no drawn window.
def is_convex(points):
    """True when the ring has no dent (no corner pointing into the shape).

    Parameters
    ----------
    points : sequence of (x, y, z)
        A ring (closing point optional).

    Returns
    -------
    bool
        True = convex: walking around the ring, every corner turns the same way
        (a rectangle, a triangle, a gable wall). False = concave: at least one corner
        turns the other way, into the shape (an L-shaped roof). Corners on one straight
        line count as convex.

    Notes
    -----
    A LoD2 window is drawn by shrinking its surface toward the average of the corners;
    the window stays inside the surface only when the surface is convex.
    """
    normal = unit_normal(points)
    pts = drop_closing_point(points)
    count = len(pts)
    for i in range(count):
        a = np.array(pts[i])
        b = np.array(pts[(i + 1) % count])
        c = np.array(pts[(i + 2) % count])
        turn = np.cross(b - a, c - b)
        if float(np.dot(turn, normal)) < -1e-9:
            return False
    return True
