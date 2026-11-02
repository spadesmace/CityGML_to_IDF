"""
 windows  the window as geometry
For each EXTERIOR wall and roof, by the BUILDING's ONE LoD (Building.lod; ADE spec §4.3.1, Table 1):
  LoD3       explicit `bldg:Window` geometry (via `bldg:opening`) -> the real polygon; nothing else
  LoD2       `nrg3:bdgBdrySurfOpeningToSurfaceRatio` (WWR)       -> synthesize a window
             else `(totalSurfaceArea - opaqueSurfaceArea)/total`  -> synthesize a window
             else                                                 -> opaque (no window)
             a wall with a dent (concave)                         -> warning, no window

Doors are skipped -> opaque for now

Glazing construction is PER-WINDOW: an explicit `bldg:Window` resolves its OWN
`nrg3:layeredConstruction` through `constructions.window_glazing` (uValue -> U-Factor,
gValue / solar transmittance -> SHGC, visible transmittance -> Visible Transmittance).
A synthesized (WWR) window, or an explicit window with no construction, falls back to the
default `FALLBACK_WINDOW` glazing. Each resolved glazing is deduped into
`model.window_constructions` (name -> WindowConstruction) and referenced by `Window.construction`.

>4-vertex windows: EnergyPlus caps FenestrationSurface:Detailed at 4 vertices, so a window
with more corners (an explicit LoD3 polygon, or a LoD2 window drawn on a wall with more than 4
corners) is replaced by a rectangle of the same area (`rings.same_area_quad`) before it is
emitted.
"""

from __future__ import annotations

import math
import sys

from ..citygml import xml_io
from ..citygml.xml_io import GML_ID, local_name, warn
from ..geometry import rings
from . import constructions
from .citygml_read import _child_measure
from .model import ABSENT, Window, WindowConstruction, trace
from .units import to_reference

FALLBACK_WINDOW = {"name": "DEFAULT_WINDOW", "u_factor": 2.8, "shgc": 0.7}   # last resort
MAX_WINDOW_TO_WALL_RATIO = 0.95   # EnergyPlus refuses a window as big as its surface ("too much area")


def default_window_construction():
    """The default glazing (FALLBACK_WINDOW) -> a WindowConstruction (SimpleGlazingSystem:
    U-Factor <- u_factor, SHGC <- shgc; no visible transmittance). Used for synthesized (WWR)
    windows and for explicit windows that carry no nrg3:layeredConstruction."""
    return WindowConstruction(**FALLBACK_WINDOW,
                              provenance={"source": trace(ABSENT, "default FALLBACK_WINDOW "
                                                                  "(no window construction in CityGML)")})


def _register_glazing(glazing, window_constructions):
    """store each glazing once by name
    Dedupe a glazing into the model's window_constructions dict """
    window_constructions.setdefault(glazing.name, glazing)
    return glazing.name

# reads lod3 window own polygon
def window_ring(doc, window_element):
    """

    Energy ADE thermal openings are LoD3 objects. LoD4 thermal openings are not
    allowed, and LoD2 uses ratios/areas rather than explicit opening geometry.
    """
    geometry = doc.children(window_element, "bldg", "lod3MultiSurface")
    target = doc.property_object(geometry[0]) if geometry else None   # inline OR xlink
    found = [ring for _, ring in xml_io.surface_polygons(doc, target) if ring] if target is not None else []
    if len(found) > 1:                                  # one polygon per window, like surfaces
        warn(f"window {window_element.get(GML_ID)}: {len(found)} polygons; only the first is read "
             f"(one polygon per window)")
    return found[0] if found else []

# LOD 3 only got explicit window:
def explicit_windows(doc, wall_element, wall_points, origin_offset, window_constructions):
    """LoD3 explicit `bldg:Window` polygons, recentred to the building origin, each with
    its OWN glazing construction.

    WINDING: the wall keeps the FILE's winding (building_surfaces.process_surfaces). The window
    is re-wound to face the SAME WAY AS ITS WALL (rings.face_like): the writer promises
    EnergyPlus that every polygon is entered Counterclockwise "as viewed from OUTSIDE the
    surface" (GlobalGeometryRules), and a window facing against its wall crashes EnergyPlus
    (measured: exit 0xC0000409). Wall and window are in the same recentred frame, and
    translation cannot change a normal."""
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
            warn(f"window {window_element.get(GML_ID)}: its LoD3 geometry cannot be read "
                 f"(not supported yet); no window")
            continue
        quad = rings.same_area_quad(ring)              # E+ fenestration is capped at 4 vertices
        recentred_points = [[float(x - offset_x), float(y - offset_y), float(z - offset_z)]
                            for (x, y, z) in quad]
        aligned, _normal = rings.face_like(recentred_points, wall_normal)   # face the wall's way
        was_reversed = [list(p) for p in aligned] != recentred_points
        if was_reversed:
            warn(f"window {window_element.get(GML_ID)}: vertices ran opposite to "
                 f"wall {wall_element.get(GML_ID)}; re-wound to face the same way")
        window_points = [[float(x), float(y), float(z)] for (x, y, z) in aligned]
        area = round(rings.polygon_area(window_points), 3)
        glazing = constructions.window_glazing(doc, window_element) or default_window_construction()
        construction_name = _register_glazing(glazing, window_constructions)
        geometry_note = ("explicit LoD3 bldg:Window polygon"
                         + (f", simplified {len(ring)}->4 vertices (same-area quad)"
                            if len(ring) > 4 else "")
                         + (", re-wound to match the wall's outward normal" if was_reversed else ""))
        found_windows.append(Window(
            source_id=window_element.get(GML_ID),
            points=window_points, area=area, source="explicit",
            construction=construction_name,
            provenance={"geometry": geometry_note,
                        "area": f"{area} m2 (from window vertices)",
                        "glazing": f"{construction_name} (U={glazing.u_factor}, SHGC={glazing.shgc})"}))
    return found_windows

# ============================================================================================
# LoD2 WINDOWS Synthesizing :
#
#   * SHAPE  = one CENTRED window per wall or roof, similar to it (scale = sqrt(ratio)).
#              A wall with a dent gets no window (the shrunk copy could stick out); a drawn
#              window with more than 4 corners becomes a rectangle of the same area.
#              NOTE (possible future option): a horizontal STRIP at a fixed sill height —
#              same area/U/SHGC but DIFFERENT solar gains, because the glass sits elsewhere on
#              the wall. Not implemented; add here as an alternative shape if ever wanted.
#   * GLAZING = the DEFAULT (FALLBACK_WINDOW, U 2.8 / SHGC 0.7).
#              NOTE: a wall's own LayeredConstruction MAY legally carry a gValue (XSD
#              LayeredConstructionType, and Energy ADE spec case 5.1: "LayeredConstruction
#              objects (i.e. for U and g values) are associated to the building thematic
#              surfaces/openings").
# ============================================================================================
def _checked_ratio(ratio, context):
    """A window-to-wall ratio must be a real fraction in [0,1]. Outside that it is a DATA ERROR
    (a wrong uom, a typo): WARN and return None so NO window is synthesized — instead of capping,
    say, a 60x ratio to MAX_WINDOW_TO_WALL_RATIO and handing back a 95%-glass wall that LOOKS
    like real data. Presence-based: a wall with no usable ratio simply gets no window (never a
    fabricated one)."""
    if ratio is None:
        return None
    if ratio < 0.0 or ratio > 1.0:
        warn(f"{context}: window-to-wall ratio {ratio} is outside 0..1 (wrong uom?); no window")
        return None
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
    wall_id = wall_element.get(GML_ID)

    stated_ratio, ratio_uom = _child_measure(doc, wall_element, "nrg",
                                             "bdgBdrySurfOpeningToSurfaceRatio")
    ratio = to_reference(
        "bdgBdrySurfOpeningToSurfaceRatio", stated_ratio, ratio_uom,
        context=f"surface '{wall_id}' bdgBdrySurfOpeningToSurfaceRatio")
    if ratio is not None:
        checked = _checked_ratio(ratio, f"surface '{wall_id}' bdgBdrySurfOpeningToSurfaceRatio")
        source = (f"bdgBdrySurfOpeningToSurfaceRatio = {stated_ratio}"
                  f"{(' ' + ratio_uom) if ratio_uom else ''}")
        if checked is None:                          # stated but out of 0..1 -> no window
            return None, f"citygml {source} is outside 0..1; no window"
        return checked, f"citygml {source} -> {round(checked, 4)}"

    raw_total, total_uom = _child_measure(doc, wall_element, "nrg", "bdgBdrySurfTotalSurfaceArea")
    raw_opaque, opaque_uom = _child_measure(doc, wall_element, "nrg", "bdgBdrySurfOpaqueSurfaceArea")
    if raw_total and raw_opaque is not None and raw_total > 0:
        # Both are gml:AreaType -> convert each to m2 first, so the subtraction is meaningful
        # even when the file states them in different area units.
        total_area = to_reference("bdgBdrySurfTotalSurfaceArea", raw_total, total_uom,
                                  context=f"surface '{wall_id}' bdgBdrySurfTotalSurfaceArea")
        opaque_area = to_reference("bdgBdrySurfOpaqueSurfaceArea", raw_opaque, opaque_uom,
                                   context=f"surface '{wall_id}' bdgBdrySurfOpaqueSurfaceArea")
        if total_area is None or opaque_area is None or total_area <= 0:
            # to_reference already warned and named the offending unit.
            return None, (f"total ('{total_uom}') / opaque ('{opaque_uom}') areas are not in an "
                          f"accepted area unit; unusable")
        checked = _checked_ratio(max(0.0, (total_area - opaque_area) / total_area),
                                 f"surface '{wall_id}' (total - opaque) / total")
        source = (f"(total {raw_total} {total_uom} - opaque {raw_opaque} {opaque_uom}) "
                  f"-> ({total_area} - {opaque_area}) m2 / total")
        if checked is None:                          # opaque > total etc. -> unusable, no window
            return None, f"citygml {source} is outside 0..1; no window"
        return checked, f"citygml {source} = {round(checked, 3)}"
    return None, "no opening ratio or total/opaque areas on the surface"

# invent geometry It takes the wall polygon, finds its centre, and shrinks the wall's own shape toward that centre
def synthesize_window(wall_points, window_to_wall_ratio):
    """ a window coplanar with the surface (wall or roof), area = ratio x surface area -- scale
    the surface ring about its centre by sqrt(ratio). Works for any convex polygon.

    SHAPE = CENTRED 
    NOTE: a horizontal STRIP at a fixed sill
    height is the alternative convention — same area, same U/SHGC, but DIFFERENT solar gains
    because the glass sits elsewhere on the wall. NOT implemented; add it here as a second
    shape option if it is ever wanted.

    WINDING is inherited for free: the surface ring is ALREADY oriented outward, and scaling it
    about its own centre keeps the vertex ORDER, so the synthesized window necessarily faces
    the same way as its surface. Only an EXPLICIT (LoD3) window, whose vertices come from the
    file, has to be re-wound (see explicit_windows / rings.face_like)."""
    corners = rings.drop_closing_point(wall_points)
    center_x = sum(corner[0] for corner in corners) / len(corners)
    center_y = sum(corner[1] for corner in corners) / len(corners)
    center_z = sum(corner[2] for corner in corners) / len(corners)
    scale = math.sqrt(window_to_wall_ratio)
    return [[center_x + scale * (corner[0] - center_x),
             center_y + scale * (corner[1] - center_y),
             center_z + scale * (corner[2] - center_z)] for corner in corners]


def windows_for_wall(doc, wall_element, wall_points, origin_offset, window_constructions, lod):
    """One exterior wall or roof -> its list of Window objects ([] = opaque).

    Parameters
    ----------
    doc : xml_io.CityGMLDoc
        The parsed CityGML file.
    wall_element : lxml element
        The wall's or roof's boundary surface.
    wall_points : list
        The wall's or roof's recentred points (file winding).
    origin_offset : list
        The building's recentring shift.
    window_constructions : dict
        The model's glazing pool, filled in place.
    lod : int or None
        The building's ONE LoD (Building.lod, from building_surfaces.select_lod).

    Returns
    -------
    list of Window

    Notes
    -----
    LoD3 building: windows come ONLY from the wall's bldg:Window objects. ADE spec §4.3.1: "For the opening(s), the corresponding CityGML classes (Window or
    Door) must be used"; Table 1: thermal openings "must be modelled (if they exist) via openings".
    A LoD3 wall without a Window has no window; the ratio is never used.
    LoD2 building: no opening objects exist (CityGML 2.0 §10.3.9 req. 8), so the window comes
    from the surface's own attributes: bdgBdrySurfOpeningToSurfaceRatio, else (total - opaque) /
    total. The building decides, not the wall: a LoD2 wall that also carries a LoD3 copy is
    still read as LoD2. The window is the wall shrunk about its centre to the file's area; a
    wall with a dent gets no window (warning), and a drawn window with more than 4 corners
    becomes a rectangle of the same area (rings.same_area_quad; IDD FenestrationSurface:Detailed
    N3, maximum 4). A ratio above MAX_WINDOW_TO_WALL_RATIO is drawn at that cap, with a
    warning, so some wall remains around the glass; `wwr` keeps the file's own ratio.
    """
    if lod == 3:                                                      # LoD3: openings ONLY
        return explicit_windows(doc, wall_element, wall_points, origin_offset,
                                window_constructions)

    window_to_wall_ratio, ratio_note = window_to_wall_ratio_from_attributes(doc, wall_element)
    if not window_to_wall_ratio or window_to_wall_ratio <= 0:       # no usable ratio: opaque
        return []
    wall_id = wall_element.get(GML_ID)
    if not rings.is_convex(wall_points):                            # a dent: the window could stick out
        warn(f"surface {wall_id}: has a dent (concave); no window drawn from its opening ratio")
        return []
    ratio_used = window_to_wall_ratio
    if ratio_used > MAX_WINDOW_TO_WALL_RATIO:                       # keep some wall around the glass
        warn(f"surface {wall_id}: opening ratio {round(window_to_wall_ratio, 3)} is above "
             f"{MAX_WINDOW_TO_WALL_RATIO}; window drawn with {MAX_WINDOW_TO_WALL_RATIO}")
        ratio_used = MAX_WINDOW_TO_WALL_RATIO
    window_points = synthesize_window(wall_points, ratio_used)
    geometry_note = "surface polygon scaled about centre by sqrt(ratio)"
    if len(window_points) > 4:                                      # EnergyPlus: at most 4 corners
        geometry_note += f", simplified {len(window_points)}->4 vertices (same-area quad)"
        window_points = [list(p) for p in rings.same_area_quad(window_points)]
    area = round(rings.polygon_area(window_points), 3)
    construction_name = _register_glazing(default_window_construction(), window_constructions)
    return [Window(source_id=wall_id + "_win",
                   points=window_points, area=area,
                   source="wwr", wwr=round(window_to_wall_ratio, 3),
                   construction=construction_name,
                   provenance={"ratio": ratio_note,
                               "geometry": geometry_note,
                               "area": f"{area} m2 = surface area × {round(ratio_used, 3)}",
                               "glazing": f"{construction_name} (default)"})]


def resolve_windows(doc, middle):
    """Attach windows to exterior walls and roofs in the model, resolving each window's glazing
    construction and collecting them into middle.window_constructions (deduped by name).
    Presence-based: only surfaces that carry a real window source get windows. Runs after the
    zones, so "exterior" is the surface's FINAL boundary (Outdoors). The opening ratio is "a
    more general form of the well-known window-to-wall ratio" (Energy ADE spec, footnote 15),
    so a roof's ratio gives a skylight like a wall's gives a window."""
    window_constructions = {}
    for building in middle.buildings:
        origin_offset = building.origin_offset or [0.0, 0.0, 0.0]
        for surface in building.surfaces:
            if surface.role not in ("wall", "roof") or surface.boundary != "Outdoors":
                continue                                         # windows only on exterior walls and roofs
            wall_element = doc.get_by_id(surface.source_gml_id or surface.source_id)
            if wall_element is None:
                continue

            # for each exterior wall BoundarySurface, it calls windows_for_wall()
            windows = windows_for_wall(doc, wall_element, surface.points, origin_offset,
                                       window_constructions, building.lod)
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
