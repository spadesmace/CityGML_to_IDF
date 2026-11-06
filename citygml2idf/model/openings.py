"""
model/openings.py — the windows of each outside wall and roof.

Only a wall or roof whose FINAL boundary is Outdoors gets windows (this runs after the zones;
E+ refuses a window on an adiabatic surface). The building's ONE LoD decides the source
(Energy ADE spec §4.3.1, Table 1):
  LoD3   bldg:opening -> bldg:Window -> its own lod3MultiSurface polygon; nothing else
         (doors are skipped: the wall stays opaque)
  LoD2   nrg3:bdgBdrySurfOpeningToSurfaceRatio                  -> one window drawn on it
         else (TotalSurfaceArea - OpaqueSurfaceArea) / Total     -> the same
         else                                                    -> no window
  LoD1   no window (LoD1 has no openings and no ratio)

Glazing: a LoD3 Window's own nrg3:layeredConstruction (constructions.window_glazing), else
the default FALLBACK_WINDOW; a drawn LoD2 window always gets the default. Each glazing is
stored once by name in model.window_constructions. A window with more than 4 corners becomes
a rectangle of the same area (rings.same_area_quad; IDD FenestrationSurface:Detailed N3, at
most 4 vertices).
"""

from __future__ import annotations

import math

from ..citygml import xml_io
from ..citygml.xml_io import GML_ID, local_name, warn
from ..geometry import rings
from . import constructions
from ..citygml.citygml_read import child_measure
from .model import ABSENT, Window, WindowConstruction, trace
from .units import to_reference

FALLBACK_WINDOW = {"name": "DEFAULT_WINDOW",                        # last resort
                   "u_factor": constructions.DEFAULT_GLAZING_U,
                   "shgc": constructions.DEFAULT_GLAZING_SHGC}
MAX_WINDOW_TO_WALL_RATIO = 0.95   # EnergyPlus refuses a window as big as its surface ("too much area")


def default_window_construction():
    """The default glazing FALLBACK_WINDOW as a WindowConstruction (no visible transmittance)."""
    return WindowConstruction(**FALLBACK_WINDOW,
                              provenance={"source": trace(ABSENT, "default FALLBACK_WINDOW "
                                                                  "(no window construction in CityGML)")})


def _register_glazing(glazing, window_constructions):
    """Store a glazing once by name in the pool; return its name."""
    window_constructions.setdefault(glazing.name, glazing)
    return glazing.name


# reads a LoD3 window's own polygon
def window_ring(doc, window_element):
    """The first polygon ring of a bldg:Window's lod3MultiSurface (inline or xlink); [] if none.

    Notes
    -----
    Energy ADE thermal openings are LoD3 objects (Table 1); LoD2 uses ratios / areas instead.
    One polygon per window, like surfaces: more are warned and only the first is read.
    """
    geometry = doc.children(window_element, "bldg", "lod3MultiSurface")
    if not geometry:
        return []
    target = doc.property_object(geometry[0])                     # inline OR xlink
    if target is None:
        return []
    found = []
    for _, ring in xml_io.surface_polygons(doc, target):
        if ring:
            found.append(ring)
    if len(found) > 1:                                  # one polygon per window, like surfaces
        warn(f"window {window_element.get(GML_ID)}: {len(found)} polygons; only the first is read "
             f"(one polygon per window)")
    if not found:
        return []
    return found[0]


# LoD3 only: explicit windows
def explicit_windows(doc, surface_element, surface_points, ground_height, window_constructions):
    """The LoD3 bldg:Window polygons of one surface, lowered like their building, each with its
    own glazing.

    Notes
    -----
    The surface keeps the file's winding; each window is re-wound to face the same way
    (rings.face_like): the writer declares every polygon Counterclockwise "as viewed from
    OUTSIDE" (GlobalGeometryRules), and a window facing against its surface crashes
    EnergyPlus. Lowering is a translation, so it cannot change a normal.
    """
    surface_normal = rings.unit_normal(rings.drop_closing_point(surface_points))
    found_windows = []
    # surface → bldg:opening → bldg:Window
    for opening_element in doc.children(surface_element, "bldg", "opening"):
        window_element = doc.property_object(opening_element)
        if window_element is None or local_name(window_element) != "Window":
            continue
        ring = rings.drop_closing_point(window_ring(doc, window_element))
        if len(ring) < 3:
            warn(f"window {window_element.get(GML_ID)}: its LoD3 geometry cannot be read "
                 f"(not supported yet); no window")
            continue
        quad = rings.same_area_quad(ring)              # E+ fenestration is capped at 4 vertices
        lowered_points = [[float(x), float(y), float(z - ground_height)] for (x, y, z) in quad]
        aligned, _normal = rings.face_like(lowered_points, surface_normal)   # face the surface's way
        was_reversed = [list(p) for p in aligned] != lowered_points
        if was_reversed:
            warn(f"window {window_element.get(GML_ID)}: vertices ran opposite to "
                 f"wall {surface_element.get(GML_ID)}; re-wound to face the same way")
        window_points = [[float(x), float(y), float(z)] for (x, y, z) in aligned]
        area = round(rings.polygon_area(window_points), 3)
        glazing = constructions.window_glazing(doc, window_element) or default_window_construction()
        construction_name = _register_glazing(glazing, window_constructions)
        geometry_note = "explicit LoD3 bldg:Window polygon"
        if len(ring) > 4:
            geometry_note += f", simplified {len(ring)}->4 vertices (same-area quad)"
        if was_reversed:
            geometry_note += ", re-wound to match the wall's outward normal"
        found_windows.append(Window(
            source_id=window_element.get(GML_ID),
            points=window_points, area=area, source="explicit",
            construction=construction_name,
            provenance={"geometry": geometry_note,
                        "area": f"{area} m2 (from window vertices)",
                        "glazing": f"{construction_name} (U={glazing.u_factor}, SHGC={glazing.shgc})"}))
    return found_windows


# ============================================================================================
# LoD2 window check + logic for creating the window
#   SHAPE   = one centred window per wall or roof, similar to it (scale = sqrt(ratio))
#   GLAZING = the default FALLBACK_WINDOW; a surface's own LayeredConstruction may carry a
#             gValue (XSD LayeredConstructionType; spec case 5.1), not read for drawn windows
# ============================================================================================
def window_to_wall_ratio_from_attributes(doc, surface_element):
    """A LoD2 surface's opening ratio and its provenance line; (None, note) when not given.

    Notes
    -----
    bdgBdrySurfOpeningToSurfaceRatio (gml:ScaleType: uom required, % legal) is converted;
    else TotalSurfaceArea (gross, openings included) and OpaqueSurfaceArea (openings
    excluded), both gml:AreaType, are each converted to m2 BEFORE (total - opaque) / total,
    so they may use different area units.
    """
    surface_id = surface_element.get(GML_ID)

    stated_ratio, ratio_uom = child_measure(doc, surface_element, "nrg",
                                             "bdgBdrySurfOpeningToSurfaceRatio")
    ratio = to_reference(
        "bdgBdrySurfOpeningToSurfaceRatio", stated_ratio, ratio_uom,
        context=f"surface '{surface_id}' bdgBdrySurfOpeningToSurfaceRatio")
    if ratio is not None:
        source = (f"bdgBdrySurfOpeningToSurfaceRatio = {stated_ratio}"
                  f"{(' ' + ratio_uom) if ratio_uom else ''}")
        return ratio, f"citygml {source} -> {round(ratio, 4)}"

    raw_total, total_uom = child_measure(doc, surface_element, "nrg", "bdgBdrySurfTotalSurfaceArea")
    raw_opaque, opaque_uom = child_measure(doc, surface_element, "nrg", "bdgBdrySurfOpaqueSurfaceArea")
    if raw_total is not None and raw_opaque is not None and raw_total > 0:
        total_area = to_reference("bdgBdrySurfTotalSurfaceArea", raw_total, total_uom,
                                  context=f"surface '{surface_id}' bdgBdrySurfTotalSurfaceArea")
        opaque_area = to_reference("bdgBdrySurfOpaqueSurfaceArea", raw_opaque, opaque_uom,
                                   context=f"surface '{surface_id}' bdgBdrySurfOpaqueSurfaceArea")
        if total_area is None or opaque_area is None or total_area <= 0:
            # to_reference already warned and named the offending unit.
            return None, (f"total ('{total_uom}') / opaque ('{opaque_uom}') areas are not in an "
                          f"accepted area unit; unusable")
        ratio = (total_area - opaque_area) / total_area
        source = (f"(total {raw_total} {total_uom} - opaque {raw_opaque} {opaque_uom}) "
                  f"-> ({total_area} - {opaque_area}) m2 / total")
        return ratio, f"citygml {source} = {round(ratio, 3)}"
    return None, "no opening ratio or total/opaque areas on the surface"


# draws the window: takes the surface polygon, finds its centre and shrinks the surface's own
# shape toward that centre
def synthesize_window(surface_points, window_to_wall_ratio):
    """A window coplanar with the surface, area = ratio x surface area: the surface's corners
    scaled about their centre by sqrt(ratio) (any convex polygon).

    Notes
    -----
    Scaling about the centre keeps the corner order, so the window faces the same way as its
    surface (only a LoD3 file window must be re-wound). A horizontal strip at a fixed sill
    height would be another shape: same area and glazing, different solar gains; not
    implemented.
    """
    corners = rings.drop_closing_point(surface_points)
    center_x = sum(corner[0] for corner in corners) / len(corners)
    center_y = sum(corner[1] for corner in corners) / len(corners)
    center_z = sum(corner[2] for corner in corners) / len(corners)
    scale = math.sqrt(window_to_wall_ratio)
    window = []
    for corner in corners:
        window.append([center_x + scale * (corner[0] - center_x),
                       center_y + scale * (corner[1] - center_y),
                       center_z + scale * (corner[2] - center_z)])
    return window


def windows_for_surface(doc, surface_element, surface_points, ground_height,
                        window_constructions, lod):
    """One outside wall or roof -> its list of Window objects ([] = opaque).

    Parameters
    ----------
    doc : xml_io.CityGMLDoc
        The parsed CityGML file.
    surface_element : lxml element
        The wall's or roof's boundary surface.
    surface_points : list
        Its points, lowered to the building's ground (file winding).
    ground_height : float
        The height the building was lowered by (Building.ground_height).
    window_constructions : dict
        The model's glazing pool, filled in place.
    lod : int or None
        The building's ONE LoD (Building.lod, from building_surfaces.select_lod).

    Returns
    -------
    list of Window

    Notes
    -----
    LoD3 building: windows come ONLY from the surface's bldg:Window objects. ADE spec §4.3.1:
    "For the opening(s), the corresponding CityGML classes (Window or Door) must be used";
    Table 1: thermal openings "must be modelled (if they exist) via openings". A LoD3 surface
    without a Window has no window; the ratio is never used.
    LoD2 building: no opening objects exist (CityGML 2.0 §10.3.9 req. 8), so the window comes
    from the surface's own ratio (window_to_wall_ratio_from_attributes). The building decides,
    not the surface: a LoD2 wall that also carries a LoD3 copy is still read as LoD2. The
    window is the surface shrunk about its centre to the file's area; a surface with a dent
    gets no window (warning), and a drawn window with more than 4 corners becomes a rectangle
    of the same area (rings.same_area_quad; IDD FenestrationSurface:Detailed N3, maximum 4).
    A ratio above MAX_WINDOW_TO_WALL_RATIO is drawn at that cap, with a warning, so some wall
    remains around the glass; `wwr` keeps the file's own ratio.
    """
    if lod == 3:                                                      # LoD3: openings ONLY
        return explicit_windows(doc, surface_element, surface_points, ground_height,
                                window_constructions)

    window_to_wall_ratio, ratio_note = window_to_wall_ratio_from_attributes(doc, surface_element)
    if window_to_wall_ratio is None or window_to_wall_ratio <= 0:   # no usable ratio: opaque
        return []
    surface_id = surface_element.get(GML_ID)
    if not rings.is_convex(surface_points):                         # a dent: the window could stick out
        warn(f"surface {surface_id}: has a dent (concave); no window drawn from its opening ratio")
        return []
    ratio_used = window_to_wall_ratio
    if ratio_used > MAX_WINDOW_TO_WALL_RATIO:                       # keep some wall around the glass
        warn(f"surface {surface_id}: opening ratio {round(window_to_wall_ratio, 3)} is above "
             f"{MAX_WINDOW_TO_WALL_RATIO}; window drawn with {MAX_WINDOW_TO_WALL_RATIO}")
        ratio_used = MAX_WINDOW_TO_WALL_RATIO
    window_points = synthesize_window(surface_points, ratio_used)
    geometry_note = "surface polygon scaled about centre by sqrt(ratio)"
    if len(window_points) > 4:                                      # EnergyPlus: at most 4 corners
        geometry_note += f", simplified {len(window_points)}->4 vertices (same-area quad)"
        window_points = [list(p) for p in rings.same_area_quad(window_points)]
    area = round(rings.polygon_area(window_points), 3)
    construction_name = _register_glazing(default_window_construction(), window_constructions)
    return [Window(source_id=surface_id + "_win",
                   points=window_points, area=area,
                   source="wwr", wwr=round(window_to_wall_ratio, 3),
                   construction=construction_name,
                   provenance={"ratio": ratio_note,
                               "geometry": geometry_note,
                               "area": f"{area} m2 = surface area × {round(ratio_used, 3)}",
                               "glazing": f"{construction_name} (default)"})]


def resolve_windows(doc, middle):
    """Give every outside wall and roof its windows, and fill model.window_constructions.

    Notes
    -----
    Runs after the zones, so "outside" is the surface's FINAL boundary (Outdoors). The opening
    ratio is "a more general form of the well-known window-to-wall ratio" (Energy ADE spec,
    footnote 15), so a roof's ratio gives a skylight like a wall's gives a window.
    """
    window_constructions = {}
    for building in middle.buildings:
        ground_height = building.ground_height or 0.0
        for surface in building.surfaces:
            if surface.role not in ("wall", "roof") or surface.boundary != "Outdoors":
                continue                                         # windows only on exterior walls and roofs
            surface_element = doc.get_by_id(surface.source_id)
            if surface_element is None:
                continue

            # for each outside wall or roof, it calls windows_for_surface()
            windows = windows_for_surface(doc, surface_element, surface.points, ground_height,
                                          window_constructions, building.lod)
            if windows:
                surface.windows = windows
    middle.window_constructions = window_constructions
