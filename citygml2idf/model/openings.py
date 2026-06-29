"""
model/openings.py — windows (the W rules). Gated by `config.ENABLE_WINDOWS`.

For each EXTERIOR wall, the richest->poorest cascade (W1):
  A. explicit `bldg:Window` geometry (LoD3, via `bldg:opening`) -> use the real polygon
  B. `nrg3:bdgBdrySurfOpeningToSurfaceRatio` (WWR)              -> synthesize a window
  C. `(totalSurfaceArea - opaqueSurfaceArea)/totalSurfaceArea`  -> synthesize a window
  D. `config.DEFAULT_WWR` (TEST-ONLY; None in production)       -> synthesize a window
  E. none                                                       -> opaque (no window)

A window is NEVER invented in production (golden rule, W1.4): branch D fires only when a
test explicitly sets DEFAULT_WWR. Doors are skipped -> opaque for now (W5).

Glazing construction = ONE default `SimpleGlazingSystem` from the Excel `windows` sheet
(U-Factor <- u_value, SHGC <- g_value -- **g<->SHGC UNVERIFIED**, W3). Per-window
construction by explicit reference is a later refinement.
"""

from __future__ import annotations

import math
import sys

import pandas as pd

from .. import config
from ..citygml import xml_io
from ..citygml.xml_io import GML_ID, local_name, warn
from ..geometry import rings
from . import constructions
from .constructions import _child_text as child_text_value, _num as to_number   # reuse helpers

DEFAULT_DATABASE = constructions.DEFAULT_DB
FALLBACK_WINDOW = {"name": "DEFAULT_WINDOW", "u_factor": 2.8, "shgc": 0.7}   # last resort
MAX_WINDOW_TO_WALL_RATIO = 0.95   # keep a synthesized window strictly inside its wall


def default_window_construction(database_path=DEFAULT_DATABASE):
    """One default glazing from the Excel `windows` sheet (first row) -> a
    SimpleGlazingSystem (U-Factor <- u_value, SHGC <- g_value, W3)."""
    try:
        windows_sheet = pd.read_excel(database_path, sheet_name=constructions.SHEET_NAMES["windows"])
        first_row = windows_sheet.iloc[0]
        return {"name": str(first_row[constructions.COLUMN_MAP["code"]]),
                "u_factor": float(first_row[constructions.COLUMN_MAP["u_value"]]),
                "shgc": float(first_row[constructions.COLUMN_MAP["g_value"]])}
    except Exception as error:
        warn(f"window sheet unreadable ({type(error).__name__}: {error}); using fallback glazing")
        return dict(FALLBACK_WINDOW)


def window_ring(doc, window_element):
    """The thermal window's own LoD3 ring.

    Energy ADE thermal openings are LoD3 objects. LoD4 thermal openings are not
    allowed, and LoD2 uses ratios/areas rather than explicit opening geometry.
    """
    geometry = doc.children(window_element, "bldg", "lod3MultiSurface")
    return xml_io.read_pos_list(doc, geometry[0]) if geometry else []


def explicit_windows(doc, wall_element, origin_offset):
    """A. LoD3 explicit `bldg:Window` polygons, recentred to the building origin.
    (Doors are skipped -> opaque, W5. Reprojection for a geographic CRS = `#` later.)"""
    offset_x, offset_y, offset_z = origin_offset
    found_windows = []
    for opening_element in doc.children(wall_element, "bldg", "opening"):
        window_element = doc.property_object(opening_element)
        if window_element is None or local_name(window_element) != "Window":
            continue
        ring = rings.drop_closing_point(window_ring(doc, window_element))
        if len(ring) >= 3:
            recentred_points = [[float(x - offset_x), float(y - offset_y), float(z - offset_z)]
                                for (x, y, z) in ring]
            found_windows.append({"source_id": window_element.get(GML_ID) or "window",
                                  "points": recentred_points,
                                  "area": round(rings.polygon_area(recentred_points), 3),
                                  "from": "explicit"})
        else:
            warn(f"window {window_element.get(GML_ID) or '(no id)'} has no LoD3 geometry; falling back to ratios/areas")
    return found_windows


def window_to_wall_ratio_from_attributes(doc, wall_element):
    """B/C: openingToSurfaceRatio, else (total - opaque)/total. None if neither given."""
    stated_ratio = to_number(child_text_value(doc, wall_element, "nrg", "bdgBdrySurfOpeningToSurfaceRatio"))
    if stated_ratio is not None:
        return stated_ratio
    total_area = to_number(child_text_value(doc, wall_element, "nrg", "bdgBdrySurfTotalSurfaceArea"))
    opaque_area = to_number(child_text_value(doc, wall_element, "nrg", "bdgBdrySurfOpaqueSurfaceArea"))
    if total_area and opaque_area is not None and total_area > 0:
        return max(0.0, (total_area - opaque_area) / total_area)
    return None


def synthesize_window(wall_points, window_to_wall_ratio):
    """W2: a window coplanar with the wall, area = ratio x wall area -- scale the wall
    ring about its centre by sqrt(ratio). Works for any convex wall polygon."""
    corners = rings.drop_closing_point(wall_points)
    center_x = sum(corner[0] for corner in corners) / len(corners)
    center_y = sum(corner[1] for corner in corners) / len(corners)
    center_z = sum(corner[2] for corner in corners) / len(corners)
    scale = math.sqrt(min(max(window_to_wall_ratio, 0.0), MAX_WINDOW_TO_WALL_RATIO))
    return [[center_x + scale * (corner[0] - center_x),
             center_y + scale * (corner[1] - center_y),
             center_z + scale * (corner[2] - center_z)] for corner in corners]


def windows_for_wall(doc, wall_element, wall_points, origin_offset):
    """The W1 cascade for one exterior wall -> a list of window dicts (or [] = opaque)."""
    windows_from_geometry = explicit_windows(doc, wall_element, origin_offset)
    if windows_from_geometry:                                            # A
        return windows_from_geometry

    window_to_wall_ratio = window_to_wall_ratio_from_attributes(doc, wall_element)   # B / C
    source = "wwr"
    if window_to_wall_ratio is None and config.DEFAULT_WWR is not None:              # D (test-only)
        window_to_wall_ratio, source = config.DEFAULT_WWR, "DEFAULT_WWR(test)"

    if window_to_wall_ratio and window_to_wall_ratio > 0:
        window_points = synthesize_window(wall_points, window_to_wall_ratio)
        return [{"source_id": (wall_element.get(GML_ID) or "wall") + "_win",
                 "points": window_points,
                 "area": round(rings.polygon_area(window_points), 3),
                 "wwr": round(window_to_wall_ratio, 3), "from": source}]
    return []                                                            # E


def resolve_windows(doc, middle, database_path=DEFAULT_DATABASE):
    """Attach windows to exterior walls in the middle layer (gated by ENABLE_WINDOWS),
    and record the one default glazing construction. No-op when windows are off."""
    if not config.ENABLE_WINDOWS:
        middle["window_construction"] = None
        return None

    glazing = default_window_construction(database_path)
    any_window = False
    for building in middle["buildings"]:
        origin_offset = building.get("origin_offset", [0.0, 0.0, 0.0])
        for surface in building["surfaces"]:
            if surface.get("role") != "wall" or surface.get("boundary") != "Outdoors":
                continue                                                 # windows only on exterior walls
            if surface.get("surface_part_count", 1) > 1 and surface.get("surface_part_index", 1) > 1:
                continue  # avoid duplicating parent openings across split MultiSurface parts
            wall_element = doc.get_by_id(surface.get("source_gml_id") or surface["source_id"])
            if wall_element is None:
                continue
            
            # for each exterior wall BoundarySurface, it calls windows_for_wall()
            windows = windows_for_wall(doc, wall_element, surface["points"], origin_offset)
            if windows:
                surface["windows"] = windows
                any_window = True
    middle["window_construction"] = glazing if any_window else None
    return middle["window_construction"]


def _demo(path=None):
    from .reader import build_middle_layer
    doc = xml_io.CityGMLDoc(path or xml_io.DEFAULT_INPUT)
    middle = build_middle_layer(doc)            # build_middle_layer already calls resolve_windows
    print(f"ENABLE_WINDOWS={config.ENABLE_WINDOWS}  DEFAULT_WWR={config.DEFAULT_WWR}  "
          f"window_construction={middle.get('window_construction')}")
    for building in middle["buildings"]:
        windows = [(surface["source_id"], window["from"], window["area"])
                   for surface in building["surfaces"] for window in surface.get("windows", [])]
        print(f"  {building['id']}: {len(windows)} window(s) {windows[:6]}")


if __name__ == "__main__":
    _demo(sys.argv[1] if len(sys.argv) > 1 else None)
