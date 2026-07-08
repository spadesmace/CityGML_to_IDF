"""
 windows  the window as geometry 
For each EXTERIOR wall, the richest->poorest cascade:
  A. explicit `bldg:Window` geometry (LoD3, via `bldg:opening`) -> use the real polygon
  B. `nrg3:bdgBdrySurfOpeningToSurfaceRatio` (WWR)              -> synthesize a window
  C. `(totalSurfaceArea - opaqueSurfaceArea)/totalSurfaceArea`  -> synthesize a window
  D. none                                                       -> opaque (no window)

Doors are skipped -> opaque for now

Glazing construction is PER-WINDOW: an explicit `bldg:Window` resolves its OWN
`nrg3:layeredConstruction` through `constructions.window_glazing` (uValue -> U-Factor,
gValue / solar transmittance -> SHGC, visible transmittance -> Visible Transmittance).
A synthesized (WWR) window, or an explicit window with no construction, falls back to the
default `FALLBACK_WINDOW` glazing. Each resolved glazing is deduped into
`model.window_constructions` (name -> WindowConstruction) and referenced by `Window.construction`.

>4-vertex windows: EnergyPlus caps FenestrationSurface:Detailed at 4 vertices, so an
explicit window polygon with more corners is reduced to its in-plane bounding quad
(`rings.simplify_to_quad`) before it is emitted.
"""

from __future__ import annotations

import math
import sys

from ..citygml import xml_io
from ..citygml.xml_io import GML_ID, local_name, warn
from ..geometry import rings
from . import constructions
from .citygml_read import _child_measure
from .model import Window, WindowConstruction

FALLBACK_WINDOW = {"name": "DEFAULT_WINDOW", "u_factor": 2.8, "shgc": 0.7}   # last resort
MAX_WINDOW_TO_WALL_RATIO = 0.95   # keep a synthesized window strictly inside its wall


def default_window_construction():
    """The default glazing (FALLBACK_WINDOW) -> a WindowConstruction (SimpleGlazingSystem:
    U-Factor <- u_factor, SHGC <- shgc; no visible transmittance). Used for synthesized (WWR)
    windows and for explicit windows that carry no nrg3:layeredConstruction."""
    return WindowConstruction(**FALLBACK_WINDOW,
                              provenance={"source": "default FALLBACK_WINDOW (no window construction in CityGML)"})


def _register_glazing(glazing, window_constructions):
    """Dedupe a glazing into the model's window_constructions dict; return its name."""
    window_constructions.setdefault(glazing.name, glazing)
    return glazing.name


def window_ring(doc, window_element):
    """The thermal window's own LoD3 ring.

    Energy ADE thermal openings are LoD3 objects. LoD4 thermal openings are not
    allowed, and LoD2 uses ratios/areas rather than explicit opening geometry.
    """
    geometry = doc.children(window_element, "bldg", "lod3MultiSurface")
    return xml_io.read_pos_list(doc, geometry[0]) if geometry else []

# LOD 3
def explicit_windows(doc, wall_element, origin_offset, window_constructions):
    """A. LoD3 explicit `bldg:Window` polygons, recentred to the building origin, each with
    its OWN glazing construction. Windows with >4 corners are reduced to their in-plane
    bounding quad (E+ caps fenestration at 4 vertices). Doors are skipped -> opaque (W5).
    Coordinates are assumed metric, exactly like surfaces (no CRS reprojection), so the
    same origin offset applies to both."""
    offset_x, offset_y, offset_z = origin_offset
    found_windows = []
    # wall → bldg:opening → bldg:Window
    for opening_element in doc.children(wall_element, "bldg", "opening"):
        window_element = doc.property_object(opening_element)
        if window_element is None or local_name(window_element) != "Window":
            continue
        ring = rings.drop_closing_point(window_ring(doc, window_element))
        if len(ring) < 3:
            warn(f"window {window_element.get(GML_ID) or '(no id)'} has no LoD3 geometry; falling back to ratios/areas")
            continue
        quad = rings.simplify_to_quad(ring)            # E+ fenestration is capped at 4 vertices
        recentred_points = [[float(x - offset_x), float(y - offset_y), float(z - offset_z)]
                            for (x, y, z) in quad]
        area = round(rings.polygon_area(recentred_points), 3)
        glazing = constructions.window_glazing(doc, window_element) or default_window_construction()
        construction_name = _register_glazing(glazing, window_constructions)
        geometry_note = ("explicit LoD3 bldg:Window polygon"
                         + (f", simplified {len(ring)}->4 vertices (in-plane bounding quad)"
                            if len(ring) > 4 else ""))
        found_windows.append(Window(
            source_id=window_element.get(GML_ID) or "window",
            points=recentred_points, area=area, source="explicit",
            construction=construction_name,
            provenance={"geometry": geometry_note,
                        "area": f"{area} m2 (from window vertices)",
                        "glazing": f"{construction_name} (U={glazing.u_factor}, SHGC={glazing.shgc})"}))
    return found_windows

# LOD 2
def window_to_wall_ratio_from_attributes(doc, wall_element):
    """B/C: openingToSurfaceRatio, else (total - opaque)/total. Returns (ratio,
    provenance-note); (None, note) if neither is given."""
    stated_ratio, _uom = _child_measure(doc, wall_element, "nrg", "bdgBdrySurfOpeningToSurfaceRatio")
    if stated_ratio is not None:
        return stated_ratio, f"citygml bdgBdrySurfOpeningToSurfaceRatio = {stated_ratio}"
    total_area, _t_uom = _child_measure(doc, wall_element, "nrg", "bdgBdrySurfTotalSurfaceArea")
    opaque_area, _o_uom = _child_measure(doc, wall_element, "nrg", "bdgBdrySurfOpaqueSurfaceArea")
    if total_area and opaque_area is not None and total_area > 0:
        ratio = max(0.0, (total_area - opaque_area) / total_area)
        return ratio, f"citygml (total {total_area} - opaque {opaque_area}) / total = {round(ratio, 3)}"
    return None, "no opening ratio or total/opaque areas on wall"


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


def windows_for_wall(doc, wall_element, wall_points, origin_offset, window_constructions):
    """The W1 cascade for one exterior wall -> a list of Window objects (or [] = opaque)."""
    windows_from_geometry = explicit_windows(doc, wall_element, origin_offset, window_constructions)
    if windows_from_geometry:                                            # A
        return windows_from_geometry
    
    #TODO LoD2 synthesized window can be derieved but for now it is only with default  window construction!

    window_to_wall_ratio, ratio_note = window_to_wall_ratio_from_attributes(doc, wall_element)   # B / C
    if window_to_wall_ratio and window_to_wall_ratio > 0:
        window_points = synthesize_window(wall_points, window_to_wall_ratio)
        area = round(rings.polygon_area(window_points), 3)
        construction_name = _register_glazing(default_window_construction(), window_constructions)
        return [Window(source_id=(wall_element.get(GML_ID) or "wall") + "_win",
                       points=window_points, area=area,
                       source="wwr", wwr=round(window_to_wall_ratio, 3),
                       construction=construction_name,
                       provenance={"ratio": ratio_note,
                                   "geometry": "wall polygon scaled about centre by sqrt(ratio)",
                                   "area": f"{area} m2 = wall_area × ratio",
                                   "glazing": f"{construction_name} (default)"})]
    return []                                                            # E


def resolve_windows(doc, middle):
    """Attach windows to exterior walls in the model, resolving each window's glazing
    construction and collecting them into middle.window_constructions (deduped by name).
    Presence-based: only walls that carry a real window source get windows."""
    window_constructions = {}
    for building in middle.buildings:
        origin_offset = building.origin_offset or [0.0, 0.0, 0.0]
        for surface in building.surfaces:
            if surface.role != "wall" or surface.boundary != "Outdoors":
                continue                                                 # windows only on exterior walls
            wall_element = doc.get_by_id(surface.source_gml_id or surface.source_id)
            if wall_element is None:
                continue

            # for each exterior wall BoundarySurface, it calls windows_for_wall()
            windows = windows_for_wall(doc, wall_element, surface.points, origin_offset,
                                       window_constructions)
            if windows:
                surface.windows = windows
    middle.window_constructions = window_constructions
    return window_constructions


def _demo(path=None):
    from .reader import build_middle_layer
    doc = xml_io.CityGMLDoc(path)
    middle = build_middle_layer(doc)            # build_middle_layer already calls resolve_windows
    print(f"window_constructions={list(middle.window_constructions)}")
    for building in middle.buildings:
        windows = [(surface.source_id, window.source, window.area, window.construction)
                   for surface in building.surfaces for window in surface.windows]
        print(f"  {building.id}: {len(windows)} window(s) {windows[:6]}")


if __name__ == "__main__":
    _demo(sys.argv[1] if len(sys.argv) > 1 else None)
