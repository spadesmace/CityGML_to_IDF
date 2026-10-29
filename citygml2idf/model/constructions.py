"""

This module is the RESOLVER: it walks the construction owners of a surface and runs
the TIER waterfall (see _resolve_surface). The pieces it stands on were split out for
readability and live next door:
    units.py        — value coercion + unit conversion (metres, W/m-K, …)
    citygml_read.py — typed GML child readers (_child_text / _child_measure)
                      (the property/xlink resolver is doc.property_object() in xml_io.py)
    materials.py    — the 3 EnergyPlus material builders + DEFAULT_MATERIAL
(Tier 3, an external archetype table, is not implemented — see the NOTE in _resolve_surface.)

HOW A CONSTRUCTION AND ITS MATERIALS FIND EACH OTHER (Energy ADE 3.0):
  The link (construction -> layer -> material) is by gml:id ONLY — inline nesting OR
  xlink:href. We do NOT read
  `libraryCode`/`codeSpace`: on real data that catalogue key resolved nothing (every
  surface xlinks straight to its construction, which already carries its layers or a
  uValue).

Same construction on many surfaces is resolved ONCE (dedup in resolve_all)
"""

from __future__ import annotations

import sys
from collections import Counter

from ..citygml import xml_io
from ..citygml.xml_io import GML_ID, local_name, warn
from .citygml_read import _child_measure, _child_text
from .materials import DEFAULT_MATERIAL, DEFAULT_ROUGHNESS, _material_from_citygml
from .model import ABSENT, INVALID, OK, Construction, Material, WindowConstruction, trace
from .units import MIN_NOMASS_RESISTANCE, to_reference

DEFAULT_NAME = "DEFAULT_CONSTRUCTION"


# ===== construction builders ================================================
def _base_layered_construction(doc, constr_el):
    """The baseLayeredConstruction a ReverseLayeredConstruction points to, or None."""
    props = doc.children(constr_el, "nrg", "baseLayeredConstruction")
    return doc.property_object(props[0]) if props else None


def _construction_name(doc, constr_el):
    """A stable E+ construction name = the construction's gml:id (constructions are identified BY
    their gml:id). We do NOT name by libraryCode."""
    if constr_el is None:
        return DEFAULT_NAME
    return constr_el.get(GML_ID)


# CityGML construction fallback:
# parse ordered Layer -> thickness -> material first; if no layers exist, use
# LayeredConstruction.uValue as an averaged no-mass construction (R = 1 / U).
def _from_citygml(doc, constr_el, materials):
    """Build a construction from a LayeredConstruction's own inline layers (TIER 1), else from
    its uValue (TIER 2 -> a Material:NoMass with R = 1/U).

    Returns a `Construction` dataclass either way. `Construction.layers` EMPTY means nothing in
    the CityGML was usable, and the caller falls through to the default construction."""
    if constr_el is None:
        return Construction(name="", source="citygml_none")
    
    if local_name(constr_el) == "ReverseLayeredConstruction": # go fetch its base, take the base's layers, TURN THEM AROUND
        base = _base_layered_construction(doc, constr_el)
        if base is None:
            warn(f"reverse construction '{constr_el.get(GML_ID)}': missing baseLayeredConstruction")
            return Construction(name="", source="citygml_reverse_missing_base")
        resolved = _from_citygml(doc, base, materials)
        reversed_layers = list(reversed(resolved.layers))
        # Spell out BOTH flips in the audit trail (they are different operations, easy to conflate):
        #   flip 1 (here)     : the CityGML expression device — this surface's stratigraphy IS the
        #                       base's, listed backwards; we reverse the base to recover it. The
        #                       result is STILL ADE inside->outside, just seen from THIS zone, so
        #                       layer_order stays "inside_to_outside".
        #   flip 2 (writer.py): the convention change ADE inside->outside -> E+ outside->inside,
        #                       applied to EVERY construction, base and reverse alike.
        return Construction(
            name="", layers=reversed_layers, source=resolved.source or "citygml",
            provenance={
                "reversed_of": base.get(GML_ID),
                "layer_order": (
                    f"ReverseLayeredConstruction of {base.get(GML_ID)}: base layers "
                    f"{resolved.layers} (ADE inside->outside, from the base's zone) reversed -> "
                    f"{reversed_layers} (ADE inside->outside, from THIS zone). "
                    f"layer_order stays 'inside_to_outside'; the writer flips again -> "
                    f"E+ outside->inside."
                ),
            })

    layers = []
    # Each layer is inline inside LayeredConstruction, and its material is by XLink.
    for layer_prop in doc.children(constr_el, "nrg", "layer"): # find <layer> wrapper
        layer = doc.property_object(layer_prop) # open <Layer> object 
        if layer is None:
            warn(f"construction '{constr_el.get(GML_ID)}': empty layer property skipped")
            continue
        thickness_value, thickness_uom = _child_measure(doc, layer, "nrg", "thickness")
        thickness = to_reference("thickness", thickness_value, thickness_uom,
                                 context=f"layer '{layer.get(GML_ID)}' thickness")
        mat_prop = doc.children(layer, "nrg", "material") # FIND the <material> wrapper
        mat_el = doc.property_object(mat_prop[0]) if mat_prop else None # OPEN → <SolidMaterial> (via xlink)
        m = _material_from_citygml(doc, mat_el, thickness, layer,
                                   thickness_raw=thickness_value, thickness_uom=thickness_uom)
        materials.setdefault(m.name, m)
        layers.append(m.name)
    if layers:
        return Construction(name="", layers=layers, source="citygml_layers")

    # Energy ADE LayeredConstructionType has optional uValue. EnergyPlus has no
    # direct U-value material, so for opaque averaged data we emit NoMass R=1/U.
    u_raw, u_uom = _child_measure(doc, constr_el, "nrg", "uValue")
    u_value = to_reference("uValue", u_raw, u_uom,
                           context=f"construction '{constr_el.get(GML_ID)}' uValue")
    if u_value and u_value > 0:
        thermal_resistance = 1.0 / u_value
        # IDD Material:NoMass N1 Thermal Resistance: `\minimum .001` (m2-K/W). R < 0.001 means
        # U > 1000 W/m2-K — not a building envelope, so the uValue is a DATA ERROR (typically a
        # wrong uom). E+ would Severe on it, so we do NOT emit it: warn and fall through to the
        # default construction below, exactly as if the uValue were unusable.
        if thermal_resistance < MIN_NOMASS_RESISTANCE:
            warn(f"construction '{constr_el.get(GML_ID)}': uValue {u_raw}"
                 f"{(' ' + u_uom) if u_uom else ''} -> R = 1/U = {thermal_resistance} m2-K/W, "
                 f"below the EnergyPlus Material:NoMass minimum ({MIN_NOMASS_RESISTANCE}); "
                 f"unusable (wrong uom?), using the default construction")
        else:
            mat_name = constr_el.get(GML_ID)
            u_text = f"citygml uValue {u_raw}{(' ' + u_uom) if u_uom else ''}"
            materials.setdefault(mat_name, Material(
                name=mat_name, eplus="Material:NoMass",
                roughness=DEFAULT_ROUGHNESS, thermal_resistance=thermal_resistance,
                provenance={"thermal_resistance":
                            trace(OK, f"{u_text} -> R = 1/U = {thermal_resistance} m2-K/W")}))
            return Construction(name="", layers=[mat_name], source="citygml_uvalue",
                                provenance={"u_value": trace(OK, f"{u_text} -> {u_value} W/m2-K")})

    warn(f"construction '{constr_el.get(GML_ID)}': no layers or uValue; using default")
    return Construction(name="", source="citygml")


# glazing constructions 
# Waterfall (raw converter, per field, default LAST):
#   u_factor : nrg3:uValue (converted)                       -> DEFAULT_GLAZING_U
#   shgc     : nrg3:gValue
#              -> FIRST solar nrg3:transmittance.fraction      (solar tau is a lower bound
#                 for SHGC; first-wins, warn on duplicates)
#              -> DEFAULT_GLAZING_SHGC
#   visible  : FIRST visible nrg3:transmittance.fraction       -> None (E+ N3 optional -> OMIT)
# TODO Detailed panes (WindowMaterial:Glazing) + per-side emissivity/reflectance are DEFERRED

DEFAULT_GLAZING_U = 2.8       # W/m2-K
DEFAULT_GLAZING_SHGC = 0.7
def _valid_fraction(value, context):
    """A glazing fraction (SHGC / visible transmittance) is usable only if it is ALREADY inside
    the open interval (0,1) — IDD WindowMaterial:SimpleGlazingSystem N2/N3 require > 0 and < 1.

    A value OUTSIDE that is a DATA ERROR (an odd/ignored uom, a typo): we WARN and return None
    so the caller falls to its honest default. We do NOT clamp it into range — clamping 60 to
    0.9999 turns a loud error into a quiet wrong number that LOOKS like real data.

    An already-None input (absent, or a uom units.py rejected) returns None silently — the
    converter already warned, and 'absent' is not an error."""
    if value is None:
        return None
    value = float(value)
    if 0.0 < value < 1.0:
        return value
    warn(f"{context}: value {value} is outside the open interval (0,1) (wrong uom?); "
         f"not usable, using the default")
    return None


def _glazing_transmittances(doc, constr_el, name="glazing"):
    """Read every nrg3:transmittance -> [(wavelengthRange, fraction 0..1), …].

    This is the ONE place we parse nrg3:transmittance. Each property holds a
    <nrg3:Transmittance> with a <nrg3:wavelengthRange> (the XSD ENUMERATES exactly
    solar|infrared|visible|total) and a <nrg3:fraction>. Transmittance has NO inside/outside
    side in the ADE (unlike reflectance/emissivity), so a band is just (wavelengthRange,
    fraction). Both 'solar' and 'visible' bands are captured here; the caller picks the one
    it needs.

    `fraction` is a gml:ScaleType: its uom is REQUIRED and may legally be a percent, so it is
    CONVERTED to a 0..1 fraction here and never read raw.
    """
    bands = []
    for prop in doc.children(constr_el, "nrg", "transmittance"):
        transmittance_el = doc.property_object(prop)          # inline <nrg3:Transmittance> (or xlink)
        if transmittance_el is None:
            continue
        wavelength = (_child_text(doc, transmittance_el, "nrg", "wavelengthRange") or "").strip().lower()
        raw, uom = _child_measure(doc, transmittance_el, "nrg", "fraction")
        fraction = to_reference(
            "fraction", raw, uom,
            context=f"glazing '{name}' {wavelength or 'unknown-band'} transmittance")
        if fraction is not None:
            bands.append((wavelength, fraction))
    return bands


def _first_fraction(bands, wavelength):
    """(first fraction whose wavelengthRange == wavelength, how many matched)."""
    hits = [fraction for (band, fraction) in bands if band == wavelength]
    return (hits[0] if hits else None), len(hits)


def _glazing_from_citygml(doc, constr_el, name):
    """Build a SIMPLE glazing (u_factor, shgc, visible_transmittance) from a LayeredConstruction's
    uValue / gValue / transmittance. Real CityGML value first, default LAST; visible transmittance
    is OMITTED when absent/unusable. Each field carries a {status, note} provenance entry."""
    prov = {}

    # --- u_factor : nrg3:uValue -> default ---
    u_raw, u_uom = _child_measure(doc, constr_el, "nrg", "uValue")
    u_value = to_reference("uValue", u_raw, u_uom, context=f"glazing '{name}' uValue")
    if u_value and u_value > 0:
        u_factor = u_value
        prov["u_factor"] = trace(OK, f"citygml uValue {u_raw}{(' ' + u_uom) if u_uom else ''} "
                                     f"-> {u_factor} W/m2-K")
    else:
        u_factor = DEFAULT_GLAZING_U
        prov["u_factor"] = trace(ABSENT if u_raw is None else INVALID,
                                 f"no usable uValue -> default {DEFAULT_GLAZING_U} W/m2-K")

    bands = _glazing_transmittances(doc, constr_el, name)   # already converted to 0..1

    # --- shgc : nrg3:gValue -> FIRST solar transmittance -> default ---
    g_raw, g_uom = _child_measure(doc, constr_el, "nrg", "gValue")
    g_value = to_reference("gValue", g_raw, g_uom, context=f"glazing '{name}' gValue")
    shgc = _valid_fraction(g_value, f"glazing '{name}' gValue")   # None if absent OR out of range
    if shgc is not None:
        prov["shgc"] = trace(OK, f"citygml gValue {g_raw}{(' ' + g_uom) if g_uom else ''} -> SHGC {shgc}")
    else:
        solar, n_solar = _first_fraction(bands, "solar")
        solar_shgc = _valid_fraction(solar, f"glazing '{name}' solar transmittance")
        if solar_shgc is not None:
            if n_solar > 1:
                warn(f"glazing '{name}': {n_solar} solar transmittances; using the first ({solar})")
            shgc = solar_shgc
            prov["shgc"] = trace(OK, f"solar transmittance {solar} -> SHGC {shgc} (lower-bound approximation)")
        else:
            shgc = DEFAULT_GLAZING_SHGC
            had_source = g_raw is not None or solar is not None   # present but unusable = invalid
            prov["shgc"] = trace(INVALID if had_source else ABSENT,
                                 f"no usable gValue or solar transmittance -> default {DEFAULT_GLAZING_SHGC}")

    # --- visible transmittance : FIRST visible transmittance -> OMIT when absent/unusable ---
    visible, _n_visible = _first_fraction(bands, "visible")
    visible_transmittance = _valid_fraction(visible, f"glazing '{name}' visible transmittance")
    if visible_transmittance is not None:
        prov["visible_transmittance"] = trace(OK, f"citygml visible transmittance {visible} "
                                                  f"-> {visible_transmittance}")
    else:
        prov["visible_transmittance"] = trace(INVALID if visible is not None else ABSENT,
                                              "no usable visible transmittance; omitted (E+ N3 optional)")

    return {"name": name, "u_factor": u_factor, "shgc": shgc,
            "visible_transmittance": visible_transmittance, "provenance": prov}


def window_glazing(doc, window_el):
    """A bldg:Window's glazing (WindowConstruction) from its OWN nrg3:layeredConstruction,
    or None when the window carries no construction (caller then uses the default). This is
    the window side of the RAW CONVERTER: uValue -> U-Factor, gValue/solar transmittance ->
    SHGC, visible transmittance -> Visible Transmittance (omitted when absent)."""
    constr_el = _construction_element(doc, window_el)          # the window's own layeredConstruction
    if constr_el is None:
        return None
    name = _construction_name(doc, constr_el)                  # named by gml:id
    glazing = _glazing_from_citygml(doc, constr_el, name)
    return WindowConstruction(name=glazing["name"],
                              u_factor=glazing["u_factor"], shgc=glazing["shgc"],
                              visible_transmittance=glazing["visible_transmittance"],
                              provenance=glazing["provenance"])


# ===== construction owner cascade ============================================
# Read layeredConstruction only from schema-valid CityObject owners.
# This covers BoundarySurface, ThermalZone and Building; it rejects raw gml:Polygon faces from
# LoD1 solids. (bldg:BuildingPart is OUT OF SCOPE — one bldg:Building = one IDF — so it never
# appears in the cascade; see semantics/building_surfaces.py.)
def _construction_element(doc, owner_el):
    """A CityObject owner's LayeredConstruction (inline or via xlink), or None."""
    if owner_el is None:
        return None
    # Energy ADE layeredConstruction is a generic property of CityObject.
    # Raw GML geometry such as gml:Polygon is not a CityObject, so LoD1 solid
    # faces get construction from ThermalZone / Building context, not the face.
    if owner_el.tag.startswith(f"{{{xml_io.NS['gml']}}}"):
        return None
    prop = doc.children(owner_el, "nrg", "layeredConstruction")
    return doc.property_object(prop[0]) if prop else None


# Construction owner cascade:
# LoD2/3 BoundarySurface first; then the LoD1/whole-object context (ThermalZone, Building),
# which arrives as `context_ids` from semantics/building_surfaces._fallback_context_ids.
def _construction_candidates(doc, surf_el, context_ids=None):
    """Construction owner cascade: BoundarySurface -> ThermalZone -> Building."""
    candidates = []
    seen = set()

    def add_candidate(owner_id, owner_el):
        constr_el = _construction_element(doc, owner_el)
        if constr_el is None:
            return
        key = constr_el.get(GML_ID)              # always set: xml_io generates missing ids
        if key in seen:
            return
        seen.add(key)
        candidates.append((owner_id, constr_el))

    add_candidate(surf_el.get(GML_ID) if surf_el is not None else None, surf_el)
    for context_id in context_ids or []:
        add_candidate(context_id, doc.get_by_id(context_id))
    return candidates


# ===== the TIER waterfall (raw converter) ====================================
# Resolve ONE surface's construction. MOST DETAILED FIRST. This is the RAW CONVERTER:
# it reads ONLY the CityGML's own data (Tiers 1-2), then a project default (Tier 4).
#   TIER 1  CityGML DETAILED layers — the construction's own inline nrg:layer
#           (reached by xlink or inline nesting; property_object already followed it,
#           so `constr_el` IS the referenced construction). Named by gml:id.
#   TIER 2  CityGML AVERAGED value  — no layers, only nrg:uValue -> Material:NoMass
#           (R = 1/U). The typical LoD1 hull case. GUARDED: if R = 1/U lands below the IDD's
#           Material:NoMass floor (`\minimum .001` m2-K/W, i.e. U > 1000 W/m2-K — not a
#           building, almost always a wrong uom), the uValue is DISCARDED and the construction
#           falls through to Tier 4. We never invent a replacement R.
#   TIER 3  not implemented — see the NOTE inside _resolve_surface.
#   TIER 4  DEFAULT construction    — nothing usable in the CityGML.
def _resolve_surface(doc, surf_el, surface_record, materials):
    """Resolve the EnergyPlus construction of one surface, most detailed source first.

    Parameters
    ----------
    doc : CityGMLDoc
        The loaded CityGML document.
    surf_el : lxml element or None
        The surface's own element: a BoundarySurface, or a raw ``gml:Polygon`` in LoD1
        (a polygon is not a CityObject, so it cannot own a construction).
    surface_record : Surface
        The middle-layer surface. Its ``construction_context_ids`` are the fallback
        owners (zone, then building), nearest first.
    materials : dict
        The shared material pool (name -> Material); new materials are added to it.

    Returns
    -------
    tuple of (str, Construction)
        The construction name (the construction's ``gml:id``, or ``DEFAULT_CONSTRUCTION``)
        and the resolved Construction.

    Notes
    -----
    Owners are tried in order: the surface itself, then its context owners. The first
    owner whose construction yields something usable wins: Tier 1 = its ``nrg3:layer``
    list, Tier 2 = its ``nrg3:uValue`` (Material:NoMass, R = 1/U). Tier 3 is not
    implemented (see the NOTE in the body). Tier 4 = ``DEFAULT_CONSTRUCTION``.
    The audit trail is the one line ``_construction_provenance_line`` builds from the
    returned Construction (name, ``source`` = tier, ``source_context_id`` = owner).
    """
    # For LoD1 raw solids, surf_el is a gml:Polygon and cannot own Energy ADE
    # layeredConstruction; the construction comes from the ThermalZone / Building
    # context passed in context_ids.
    context_ids = surface_record.construction_context_ids
    candidates = _construction_candidates(doc, surf_el, context_ids)

    # ===== TIER 1 + TIER 2 : the CityGML's OWN data (try every owner first) =====
    #   TIER 1  detailed inline layers; TIER 2  no layers but a uValue -> NoMass (R = 1/U).
    #   Both come out of _from_citygml (it returns a Construction with layers for either case).
    for owner_id, constr_el in candidates:
        name = _construction_name(doc, constr_el)             # = the construction's gml:id
        resolved = _from_citygml(doc, constr_el, materials)   # T1 layers, or T2 uValue
        if resolved.layers:
            resolved.name = name
            resolved.source_context_id = owner_id
            return name, resolved

    # ===== TIER 3 : EXTERNAL ARCHETYPE — NOT IMPLEMENTED =====
    # NOTE (future improvement): an external archetype table would be added EXACTLY HERE,
    # between the file's own data (Tiers 1-2, above) and the default (Tier 4, below). It would
    # be looked up by building TYPE, not by libraryCode — candidate keys: bldg:function,
    # bldg:yearOfConstruction, nrg3:bdgConstructionWeight (TABULA / UBEM-CARDs style)

    # ===== TIER 4 : DEFAULT =====
    materials.setdefault(DEFAULT_MATERIAL.name, DEFAULT_MATERIAL)
    return DEFAULT_NAME, Construction(name=DEFAULT_NAME, layers=[DEFAULT_MATERIAL.name],
                                      source="default")


def _construction_provenance_line(resolved):
    """The ONE readable line stored in Surface.provenance["construction"] — the audit record of
    how this surface got its construction. Read straight off the resolved Construction."""
    if resolved.source == "default":
        return ("default construction — no CityGML detailed layers (T1) or uValue (T2); "
                "archetype (T3) deferred")
    # A ReverseLayeredConstruction INHERITS its base's source, so it reads citygml_layers /
    # citygml_uvalue here too — the reversal itself is recorded in provenance["layer_order"].
    line = resolved.source                                  # citygml_layers | citygml_uvalue
    if resolved.name:
        line += f" from construction '{resolved.name}'"     # named by its gml:id
    if resolved.source_context_id:
        line += f" (owner {resolved.source_context_id})"
    return line


def resolve_all(doc, middle):
    """Resolve every surface in the middle layer; fill middle['constructions'] and
    middle['materials'] (deduped) and tag each surface with its construction name.
    Constructions and materials are found by gml:id (inline or xlink) only — no
    libraryCode/codeSpace lookup """
    constructions, materials = {}, {}
    for b in middle.buildings:
        for s in b.surfaces:
            surf_el = doc.get_by_id(s.source_gml_id or s.source_id)
            name, resolved = _resolve_surface(doc, surf_el, s, materials)
            s.construction = name
            s.provenance["construction"] = _construction_provenance_line(resolved)
            constructions.setdefault(name, resolved)
    middle.constructions = constructions
    middle.materials = materials
    return constructions, materials


def _demo(path=None):
    from .reader import build_middle_layer
    doc = xml_io.CityGMLDoc(path)
    middle = build_middle_layer(doc)
    constructions, materials = resolve_all(doc, middle)
    used = Counter(s.construction for b in middle.buildings for s in b.surfaces)
    print(f"{len(constructions)} construction(s), {len(materials)} material(s)")
    for name, c in constructions.items():
        print(f"\n[{c.source.upper():7}] {name}  (used by {used[name]} surface(s))")
        for mname in c.layers:
            m = materials[mname]
            detail = (f"R={m.thermal_resistance}" if m.eplus != "Material"
                      else f"t={m.thickness} k={m.conductivity} "
                           f"rho={m.density} cp={m.specific_heat}")
            print(f"    {m.eplus:<16} {mname:<32} {detail}")


if __name__ == "__main__":
    _demo(sys.argv[1] if len(sys.argv) > 1 else None)
