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
from .units import to_reference

FALLBACK_WINDOW = {"name": "DEFAULT_WINDOW", "u_factor": 2.8, "shgc": 0.7}   # last resort
MAX_WINDOW_TO_WALL_RATIO = 0.95   # keep a synthesized window strictly inside its wall


def default_window_construction():
    """The default glazing (FALLBACK_WINDOW) -> a WindowConstruction (SimpleGlazingSystem:
    U-Factor <- u_factor, SHGC <- shgc; no visible transmittance). Used for synthesized (WWR)
    windows and for explicit windows that carry no nrg3:layeredConstruction."""
    return WindowConstruction(**FALLBACK_WINDOW,
                              provenance={"source": "default FALLBACK_WINDOW (no window construction in CityGML)"})


def _register_glazing(glazing, window_constructions):
    """store each glazing once by name
    Dedupe a glazing into the model's window_constructions dict """
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
def explicit_windows(doc, wall_element, wall_points, origin_offset, window_constructions):
    """LoD3 explicit `bldg:Window` polygons, recentred to the building origin, each with
    its OWN glazing construction. Windows with >4 corners are reduced to their in-plane
    bounding quad (E+ caps fenestration at 4 vertices). Doors are skipped -> opaque 
    Coordinates are assumed metric, exactly like surfaces (no CRS reprojection), so the
    same origin offset applies to both.

    WINDING: the file's vertex order is NEVER trusted — the same  rule the walls already
    follow (rings.orient_outward). A window is re-wound to face the SAME WAY AS ITS WALL
    (rings.orient_like), because the writer promises EnergyPlus that every polygon is entered
    Counterclockwise "as viewed from OUTSIDE the surface" (GlobalGeometryRules / IDD), and
    CityGML guarantees no winding at all. `wall_points` are already oriented outward, so the wall's normal is the
    reference; both are in the same recentred frame, and translation cannot change a normal."""
    offset_x, offset_y, offset_z = origin_offset
    wall_normal = rings.unit_normal(rings.drop_closing_point(wall_points))
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
        aligned, _normal = rings.orient_like(recentred_points, wall_normal)   # face the wall's way
        was_reversed = [list(p) for p in aligned] != recentred_points
        if was_reversed:
            warn(f"window {window_element.get(GML_ID) or '(no id)'}: vertices ran opposite to "
                 f"wall {wall_element.get(GML_ID)}; re-wound to face the same way")
        window_points = [[float(x), float(y), float(z)] for (x, y, z) in aligned]
        area = round(rings.polygon_area(window_points), 3)
        glazing = constructions.window_glazing(doc, window_element) or default_window_construction()
        construction_name = _register_glazing(glazing, window_constructions)
        geometry_note = ("explicit LoD3 bldg:Window polygon"
                         + (f", simplified {len(ring)}->4 vertices (in-plane bounding quad)"
                            if len(ring) > 4 else "")
                         + (", re-wound to match the wall's outward normal" if was_reversed else ""))
        found_windows.append(Window(
            source_id=window_element.get(GML_ID) or "window",
            points=window_points, area=area, source="explicit",
            construction=construction_name,
            provenance={"geometry": geometry_note,
                        "area": f"{area} m2 (from window vertices)",
                        "glazing": f"{construction_name} (U={glazing.u_factor}, SHGC={glazing.shgc})"}))
    return found_windows

# ============================================================================================
# LoD2 WINDOWS Synthesizing :I
#
#   * SHAPE  = one CENTRED window per wall, similar to the wall (scale = sqrt(ratio)).
#              NOTE (possible future option): a horizontal STRIP at a fixed sill height —
#              same area/U/SHGC but DIFFERENT solar gains, because the glass sits elsewhere on
#              the wall. Not implemented; add here as an alternative shape if ever wanted.
#   * GLAZING = the DEFAULT (FALLBACK_WINDOW, U 2.8 / SHGC 0.7).
#              NOTE: a wall's own LayeredConstruction MAY legally carry a gValue (XSD
#              LayeredConstructionType, and Energy ADE spec case 5.1: "LayeredConstruction
#              objects (i.e. for U and g values) are associated to the building thematic
#              surfaces/openings"). Alderaan contains ZERO gValue elements, so the default is
#              all we can do today; if a real file ever states one, prefer it over the default.

# STILL OPEN — AN UNKNOWN `uom` COSTS THE WINDOW. openingToSurfaceRatio is a gml:ScaleType, so its
# uom is REQUIRED and may legally be `%` / permil / ppm — we convert those. But per the project
# rule "unknown unit -> use the default, never guess", an UNRECOGNISED uom makes
# units.to_reference return None, so NO window is derived from that wall (warned).
# The accepted spellings are deliberately generous (unit interval / unit / ratio / fraction /
# dimensionless / 1 / - / empty, plus % / permil / ppm), and all 477 ratios in Alderaan use
# "unit interval", so nothing is affected today. If we ever meet a file with an odd-but-clearly
# dimensionless uom, the lenient alternative is: "unknown uom BUT the number is already in
# 0..1 -> trust it" (a ratio is dimensionless by nature). Deliberately NOT done yet.
# ============================================================================================
def _checked_ratio(ratio, context):
    """A window-to-wall ratio must be a real 0..1 fraction. Outside that range it is a DATA
    ERROR (a wrong uom, a typo) — WARN, because synthesize_window would otherwise silently
    clamp it to MAX_WINDOW_TO_WALL_RATIO and hand back a 95 %-glass wall."""
    if ratio is None:
        return None
    if ratio < 0.0 or ratio > 1.0:
        warn(f"{context}: window-to-wall ratio {ratio} is outside 0..1 (wrong uom?)")
    return ratio

## LOD 2 superficial winodw check + logic for creation window 

def window_to_wall_ratio_from_attributes(doc, wall_element):
    """ openingToSurfaceRatio, else (total - opaque)/total. Returns (ratio,
    provenance-note); (None, note) if neither is given.

    ADE SPECIFICATION : totalSurfaceArea is the GROSS area (opaque + openings); opaqueSurfaceArea EXCLUDES
    the openings. So openings = total - opaque, and the ratio is their quotient.
    openingToSurfaceRatio IS the window-to-wall ratio.

    UNITS: openingToSurfaceRatio is a gml:ScaleType -> its uom is REQUIRED and a percent is
    legal, so it is CONVERTED. The two AREAS are gml:AreaType and are each converted to m2
    BEFORE the subtraction, so a file may legally state them in DIFFERENT area units (m^2 and
    cm^2) and still yield the right ratio. Comparing the two uom STRINGS instead would reject
    "m^2" vs "m2" — the same unit spelled two ways — and lose a real window."""
    wall_id = wall_element.get(GML_ID) or "wall"

    stated_ratio, ratio_uom = _child_measure(doc, wall_element, "nrg",
                                             "bdgBdrySurfOpeningToSurfaceRatio")
    ratio = to_reference(
        "bdgBdrySurfOpeningToSurfaceRatio", stated_ratio, ratio_uom,
        context=f"wall '{wall_id}' bdgBdrySurfOpeningToSurfaceRatio")
    if ratio is not None:
        ratio = _checked_ratio(ratio, f"wall '{wall_id}' bdgBdrySurfOpeningToSurfaceRatio")
        return ratio, (f"citygml bdgBdrySurfOpeningToSurfaceRatio = {stated_ratio}"
                       f"{(' ' + ratio_uom) if ratio_uom else ''} -> {round(ratio, 4)}")

    raw_total, total_uom = _child_measure(doc, wall_element, "nrg", "bdgBdrySurfTotalSurfaceArea")
    raw_opaque, opaque_uom = _child_measure(doc, wall_element, "nrg", "bdgBdrySurfOpaqueSurfaceArea")
    if raw_total and raw_opaque is not None and raw_total > 0:
        # Both are gml:AreaType -> convert each to m2 first, so the subtraction is meaningful
        # even when the file states them in different area units.
        total_area = to_reference("bdgBdrySurfTotalSurfaceArea", raw_total, total_uom,
                                  context=f"wall '{wall_id}' bdgBdrySurfTotalSurfaceArea")
        opaque_area = to_reference("bdgBdrySurfOpaqueSurfaceArea", raw_opaque, opaque_uom,
                                   context=f"wall '{wall_id}' bdgBdrySurfOpaqueSurfaceArea")
        if total_area is None or opaque_area is None or total_area <= 0:
            # to_reference already warned and named the offending unit.
            return None, (f"total ('{total_uom}') / opaque ('{opaque_uom}') areas are not in an "
                          f"accepted area unit; unusable")
        ratio = _checked_ratio(max(0.0, (total_area - opaque_area) / total_area),
                               f"wall '{wall_id}' (total - opaque) / total")
        return ratio, (f"citygml (total {raw_total} {total_uom} - opaque {raw_opaque} "
                       f"{opaque_uom}) -> ({total_area} - {opaque_area}) m2 / total "
                       f"= {round(ratio, 3)}")
    return None, "no opening ratio or total/opaque areas on wall"

# invent geometry It takes the wall polygon, finds its centre, and shrinks the wall's own shape toward that centre
def synthesize_window(wall_points, window_to_wall_ratio):
    """ a window coplanar with the wall, area = ratio x wall area -- scale the wall
    ring about its centre by sqrt(ratio). Works for any convex wall polygon.

    SHAPE = CENTRED 
    NOTE: a horizontal STRIP at a fixed sill
    height is the alternative convention — same area, same U/SHGC, but DIFFERENT solar gains
    because the glass sits elsewhere on the wall. NOT implemented; add it here as a second
    shape option if it is ever wanted.

    WINDING is inherited for free: the wall ring is ALREADY oriented outward, and scaling it
    about its own centre keeps the vertex ORDER, so the synthesized window necessarily faces
    the same way as its wall. Only an EXPLICIT (LoD3) window, whose vertices come from the
    file, has to be re-wound (see explicit_windows / rings.orient_like)."""
    corners = rings.drop_closing_point(wall_points)
    center_x = sum(corner[0] for corner in corners) / len(corners)
    center_y = sum(corner[1] for corner in corners) / len(corners)
    center_z = sum(corner[2] for corner in corners) / len(corners)
    scale = math.sqrt(min(max(window_to_wall_ratio, 0.0), MAX_WINDOW_TO_WALL_RATIO))
    return [[center_x + scale * (corner[0] - center_x),
             center_y + scale * (corner[1] - center_y),
             center_z + scale * (corner[2] - center_z)] for corner in corners]


def windows_for_wall(doc, wall_element, wall_points, origin_offset, window_constructions):
    """ one exterior wall -> a list of Window objects (or [] = opaque)."""
    windows_from_geometry = explicit_windows(doc, wall_element, wall_points, origin_offset,
                                             window_constructions)
    if windows_from_geometry:                                          
        return windows_from_geometry
    
    window_to_wall_ratio, ratio_note = window_to_wall_ratio_from_attributes(doc, wall_element)  
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
    return []                                                            


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
