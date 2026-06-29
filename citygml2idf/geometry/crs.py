"""
geometry/crs.py — coordinate handling. Pure pyproj/numpy, no XML.

EnergyPlus works in METRES with the model sitting near the origin. CityGML may
arrive already in metres (our sample is EPSG:25832, UTM 32N) or in degrees
(e.g. EPSG:4979 lon/lat). This module:
  1. reads the EPSG code from an srsName string,                      [parse_epsg]
  2. reprojects to metres ONLY if the CRS is geographic, auto-picking
     a UTM zone from the data,                            [build_transformer]
  3. recentres so the model min corner is the origin and the floor is z = 0.
                                                                       [recenter]
For an already-metric file, the transformer is None and reprojection is a no-op.
"""

from __future__ import annotations

import re

import numpy as np
from pyproj import CRS, Transformer


def parse_epsg(srs_name):
    """'urn:ogc:def:crs:EPSG::25832' or 'EPSG:25832' -> 25832 (or None)."""
    if not srs_name:
        return None
    m = re.search(r"(\d+)\s*$", srs_name.strip())
    return int(m.group(1)) if m else None


def is_geographic(epsg):
    """True for lon/lat CRS (degrees) we must reproject; False for projected
    (metre) CRS such as UTM. Unknown -> assume metric (safe: no reprojection)."""
    try:
        return CRS.from_epsg(epsg).is_geographic
    except Exception:
        return False


def pick_utm_epsg(lon, lat):
    """Auto-pick the UTM-zone EPSG for a lon/lat (north vs south hemisphere)."""
    zone = int((lon + 180) // 6) + 1
    return (32600 if lat >= 0 else 32700) + zone


def build_transformer(src_epsg, sample_lonlat=None):
    """Return a pyproj transformer (src -> metres), or None if already metric.
    sample_lonlat = one (lon, lat) from the data, used to choose the UTM zone."""
    if src_epsg is None or not is_geographic(src_epsg):
        return None                       # already metric -> nothing to do
    lon, lat = sample_lonlat or (0.0, 0.0)
    dst = pick_utm_epsg(lon, lat)
    return Transformer.from_crs(src_epsg, dst, always_xy=True)


def reproject(points, transformer):
    """Apply a transformer to [(x, y, z), ...]; z passes through unchanged.
    transformer=None -> points returned as plain float tuples."""
    if transformer is None:
        return [(float(x), float(y), float(z)) for (x, y, z) in points]
    out = []
    for x, y, z in points:
        X, Y = transformer.transform(x, y)
        out.append((X, Y, float(z)))
    return out


def min_corner(rings):
    """(minx, miny, minz) across every point in a list of rings."""
    allpts = np.array([p for ring in rings for p in ring], dtype=float)
    return allpts.min(axis=0)


def recenter(rings, offset=None):
    """Shift all rings by -offset so the model min corner -> origin, floor -> z=0.
    Returns (shifted_rings, offset_used) so the SAME shift can be reused across a
    whole site (keeping separate buildings in their correct relative positions)."""
    if offset is None:
        offset = min_corner(rings)
    ox, oy, oz = offset
    shifted = [[(x - ox, y - oy, z - oz) for (x, y, z) in ring] for ring in rings]
    return shifted, offset
