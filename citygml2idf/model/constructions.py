"""
model/constructions.py — the LIBRARIAN. Resolve each surface's construction into
ordered EnergyPlus material layers.

This module is the RESOLVER: it walks the construction owners of a surface and runs
the TIER waterfall (see _resolve_surface). The pieces it stands on were split out for
readability and live next door:
    units.py        — value coercion + unit conversion (metres, W/m-K, …)
    citygml_read.py — typed GML child readers (_first_el/_child_text/_measure)
    materials.py    — the 3 EnergyPlus material builders + DEFAULT_MATERIAL
    archetypes.py   — the EXTERNAL archetype fallback (swappable JSON) — DEFERRED, unwired

HOW A CONSTRUCTION AND ITS MATERIALS FIND EACH OTHER (Energy ADE 3.0):
  The link (construction -> layer -> material) is by gml:id ONLY — inline nesting OR
  xlink:href — exactly like the reference repo (piotre13/CityGML2Eplus). We do NOT read
  `libraryCode`/`codeSpace`: on real data that catalogue key resolved nothing (every
  surface xlinks straight to its construction, which already carries its layers or a
  uValue), and the future archetype fallback is keyed by building function/year/weight,
  NOT by libraryCode. Constructions are NAMED by their gml:id.

Same construction on many surfaces is resolved ONCE (dedup in resolve_all). Run as a
demo (from the repo root):
    python -m citygml2idf.model.constructions
resolves every surface and prints each construction's branch + layers + E+ material type.
"""

from __future__ import annotations

import sys
from collections import Counter

from ..citygml import xml_io
from ..citygml.xml_io import GML_ID, local_name, warn
from .citygml_read import _child_measure, _child_text, _first_el
from .materials import DEFAULT_MATERIAL, DEFAULT_ROUGHNESS, _material_from_citygml
from .model import Construction, Material, WindowConstruction
from .units import _length_to_meters, _num, _u_value_to_w_per_m2_k

# Compatibility re-exports: zones.py imports a couple of helpers through this module
# (`from .constructions import _child_text, _num`). They LIVE in the split modules
# (citygml_read.py / units.py); importing them here keeps `constructions.<name>` working
# so that caller needs no change.

DEFAULT_NAME = "DEFAULT_CONSTRUCTION"
ADE_LAYER_ORDER = "inside_to_outside" # in ernergy ade specifcation (3.8 The Layered construction module)


# ===== construction builders ================================================
def _base_layered_construction(doc, constr_el):
    """The baseLayeredConstruction a ReverseLayeredConstruction points to, or None."""
    props = doc.children(constr_el, "nrg", "baseLayeredConstruction")
    return _first_el(doc, props[0]) if props else None


def _construction_name(doc, constr_el):
    """A stable E+ construction name = the construction's gml:id (the reference repo's
    `constr_id`), else a default. We do NOT name by libraryCode."""
    if constr_el is None:
        return DEFAULT_NAME
    return constr_el.get(GML_ID) or "construction"


# CityGML construction fallback:
# parse ordered Layer -> thickness -> material first; if no layers exist, use
# LayeredConstruction.uValue as an averaged no-mass construction (R = 1 / U).
def _from_citygml(doc, constr_el, materials):
    """Build a construction from a LayeredConstruction's own inline layers, or its
    uValue (R = 1/U). Returns {"layers": [...]} for either; empty layers = nothing usable."""
    if constr_el is None:
        return Construction(name="", source="citygml_none")
    # It points by XLink to a base LayeredConstruction, and means “use the same layers but reversed.”
    if local_name(constr_el) == "ReverseLayeredConstruction":
        base = _base_layered_construction(doc, constr_el)
        if base is None:
            warn(f"reverse construction '{constr_el.get(GML_ID)}': missing baseLayeredConstruction")
            return Construction(name="", source="citygml_reverse_missing_base")
        resolved = _from_citygml(doc, base, materials)
        return Construction(name="", layers=list(reversed(resolved.layers)),
                            source=resolved.source or "citygml",
                            provenance={"reversed_of": base.get(GML_ID)})

    layers = []
    # Each layer is inline inside LayeredConstruction, and its material is by XLink.
    for layer_prop in doc.children(constr_el, "nrg", "layer"):
        layer = _first_el(doc, layer_prop)
        if layer is None:
            warn(f"construction '{constr_el.get(GML_ID)}': empty layer property skipped")
            continue
        thickness_value, thickness_uom = _child_measure(doc, layer, "nrg", "thickness")
        thickness = _length_to_meters(thickness_value, thickness_uom,
                                      context=f"layer '{layer.get(GML_ID)}' thickness")
        mat_prop = doc.children(layer, "nrg", "material")
        mat_el = _first_el(doc, mat_prop[0]) if mat_prop else None
        m = _material_from_citygml(doc, mat_el, thickness, layer,
                                   thickness_raw=thickness_value, thickness_uom=thickness_uom)
        materials.setdefault(m.name, m)
        layers.append(m.name)
    if layers:
        return Construction(name="", layers=layers, source="citygml_layers")

    # Energy ADE LayeredConstructionType has optional uValue. EnergyPlus has no
    # direct U-value material, so for opaque averaged data we emit NoMass R=1/U.
    u_raw, u_uom = _child_measure(doc, constr_el, "nrg", "uValue")
    u_value = _u_value_to_w_per_m2_k(u_raw, u_uom,
                                     context=f"construction '{constr_el.get(GML_ID)}' uValue")
    if u_value and u_value > 0:
        mat_name = (constr_el.get(GML_ID) or "citygml_construction") + "_UValue"
        materials.setdefault(mat_name, Material(
            name=mat_name, eplus="Material:NoMass",
            roughness=DEFAULT_ROUGHNESS, thermal_resistance=1.0 / u_value,
            provenance={"thermal_resistance":
                        f"citygml uValue {u_raw}{(' ' + u_uom) if u_uom else ''} "
                        f"-> R = 1/U = {1.0 / u_value} m2-K/W"}))
        return Construction(name="", layers=[mat_name], source="citygml_uvalue",
                            provenance={"u_value": f"citygml uValue {u_raw}"
                                        f"{(' ' + u_uom) if u_uom else ''} -> {u_value} W/m2-K"})

    warn(f"construction '{constr_el.get(GML_ID)}': no layers or uValue; using default")
    return Construction(name="", source="citygml")


# ===== glazing constructions — RUNG B  ===============================
# A window's construction resolves through THIS module too (like the prof's
# resolve_construction(is_glazing=True)): instead of opaque layers/NoMass it yields the 3
# fields E+ WindowMaterial:SimpleGlazingSystem needs. "glazing" vs "opaque" is decided by
# the CALLER (a bldg:Window -> glazing), never by sniffing optical fields.
# Waterfall (raw converter, per field, default LAST):
#   u_factor : nrg3:uValue (converted)                       -> DEFAULT_GLAZING_U
#   shgc     : nrg3:gValue
#              -> FIRST solar nrg3:transmittance.fraction      (solar tau is a lower bound
#                 for SHGC; first-wins, warn on duplicates)
#              -> DEFAULT_GLAZING_SHGC
#   visible  : FIRST visible nrg3:transmittance.fraction       -> None (E+ N3 optional -> OMIT)
# Detailed panes (WindowMaterial:Glazing) + per-side emissivity/reflectance are DEFERRED
# (Rung A). SHGC/VT clamped into the OPEN (0,1) interval (IDD requires >0 and <1).
DEFAULT_GLAZING_U = 2.8       # W/m2-K
DEFAULT_GLAZING_SHGC = 0.7
_GLAZING_EPS = 1e-4


def _clamp_open_unit(value):
    """Force a fraction strictly inside (0,1) — the IDD requires SHGC/VT >0 and <1."""
    if value is None:
        return None
    return min(1.0 - _GLAZING_EPS, max(_GLAZING_EPS, float(value)))


def _glazing_transmittances(doc, constr_el):
    """Read every nrg3:transmittance -> [(wavelengthRange, fraction), …].

    This is the ONE place we parse nrg3:transmittance. Each property holds a
    <nrg3:Transmittance> with a <nrg3:wavelengthRange> (solar|infrared|visible|total)
    and a <nrg3:fraction>. Transmittance has NO inside/outside side in the ADE (unlike
    reflectance/emissivity), so a band is just (wavelengthRange, fraction). Both 'solar'
    and 'visible' bands are captured here; the caller picks the one it needs.
    """
    bands = []
    for prop in doc.children(constr_el, "nrg", "transmittance"):
        transmittance_el = _first_el(doc, prop)          # inline <nrg3:Transmittance> (or xlink)
        if transmittance_el is None:
            continue
        wavelength = (_child_text(doc, transmittance_el, "nrg", "wavelengthRange") or "").strip().lower()
        fraction, _uom = _child_measure(doc, transmittance_el, "nrg", "fraction")
        if fraction is not None:
            bands.append((wavelength, fraction))
    return bands


def _first_fraction(bands, wavelength):
    """(first fraction whose wavelengthRange == wavelength, how many matched)."""
    hits = [fraction for (band, fraction) in bands if band == wavelength]
    return (hits[0] if hits else None), len(hits)


def _glazing_from_citygml(doc, constr_el, name):
    """RUNG B: build a SIMPLE glazing (kind='glazing': u_factor, shgc, visible_transmittance)
    from a LayeredConstruction's uValue / gValue / transmittance. Real CityGML value first,
    default LAST; visible transmittance is OMITTED (None) when absent. Per-field trace."""
    trace = {}

    # --- u_factor : nrg3:uValue -> default ---
    u_raw, u_uom = _child_measure(doc, constr_el, "nrg", "uValue")
    u_value = _u_value_to_w_per_m2_k(u_raw, u_uom, context=f"glazing '{name}' uValue")
    if u_value and u_value > 0:
        u_factor = u_value
        trace["u_factor"] = {"raw": u_raw, "raw_uom": u_uom or None, "value": u_factor,
                             "unit": "W/m2-K", "source": "citygml_uValue"}
    else:
        u_factor = DEFAULT_GLAZING_U
        trace["u_factor"] = {"raw": u_raw, "value": u_factor, "unit": "W/m2-K",
                             "source": "default", "reason": "no usable nrg3:uValue"}

    bands = _glazing_transmittances(doc, constr_el)

    # --- shgc : nrg3:gValue -> FIRST solar transmittance -> default ---
    g_raw, g_uom = _child_measure(doc, constr_el, "nrg", "gValue")
    if g_raw is not None:
        shgc = _clamp_open_unit(g_raw)
        trace["shgc"] = {"raw": g_raw, "raw_uom": g_uom or None, "value": shgc,
                         "unit": "fraction", "source": "citygml_gValue"}
    else:
        solar, n_solar = _first_fraction(bands, "solar")
        if solar is not None:
            if n_solar > 1:
                warn(f"glazing '{name}': {n_solar} solar transmittances; using the first ({solar})")
            shgc = _clamp_open_unit(solar)
            trace["shgc"] = {"raw": solar, "value": shgc, "unit": "fraction",
                             "source": "citygml_solar_transmittance",
                             "approximation": "SHGC >= solar transmittance (lower bound)",
                             "solar_transmittance_count": n_solar}
        else:
            shgc = DEFAULT_GLAZING_SHGC
            trace["shgc"] = {"value": shgc, "unit": "fraction", "source": "default",
                             "reason": "no nrg3:gValue and no solar nrg3:transmittance"}

    # --- visible transmittance : FIRST visible transmittance -> OMIT (None) ---
    visible, _n_visible = _first_fraction(bands, "visible")
    if visible is not None:
        visible_transmittance = _clamp_open_unit(visible)
        trace["visible_transmittance"] = {"raw": visible, "value": visible_transmittance,
                                          "unit": "fraction",
                                          "source": "citygml_visible_transmittance"}
    else:
        visible_transmittance = None
        trace["visible_transmittance"] = {"value": None, "source": "omitted",
                                          "reason": "no visible nrg3:transmittance (E+ N3 optional)"}

    return {"name": name, "kind": "glazing", "u_factor": u_factor, "shgc": shgc,
            "visible_transmittance": visible_transmittance,
            "source": "citygml_glazing", "trace": trace}


def _glazing_provenance_line(glazing):
    """One readable line summarising a glazing's u_factor/shgc/visible sources (from the
    per-field trace) for WindowConstruction.provenance."""
    trace = glazing["trace"]
    return {field: f"{trace[field].get('value')} <- {trace[field].get('source')}"
            for field in ("u_factor", "shgc", "visible_transmittance") if field in trace}


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
    return WindowConstruction(name=glazing["name"], u_factor=glazing["u_factor"],
                              shgc=glazing["shgc"],
                              visible_transmittance=glazing["visible_transmittance"],
                              provenance=_glazing_provenance_line(glazing))


# ===== construction owner cascade ============================================
# Read layeredConstruction only from schema-valid CityObject owners.
# This covers BoundarySurface, ThermalZone, BuildingPart, Building; it rejects
# raw gml:Polygon faces from LoD1 solids.
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
    return _first_el(doc, prop[0]) if prop else None


# Construction owner cascade:
# LoD2/3 BoundarySurface first; then LoD1/whole-object context such as
# ThermalZone, BuildingPart, Building.
def _construction_candidates(doc, surf_el, context_ids=None):
    """"Construction owner cascade: BoundarySurface -> ThermalZone -> BuildingPart -> Building"""
    candidates = []
    seen = set()

    def add_candidate(owner_id, owner_el):
        constr_el = _construction_element(doc, owner_el)
        if constr_el is None:
            return
        key = constr_el.get(GML_ID) or id(constr_el)
        if key in seen:
            return
        seen.add(key)
        candidates.append((owner_id, constr_el))

    add_candidate(surf_el.get(GML_ID) if surf_el is not None else None, surf_el)
    for context_id in context_ids or []:
        add_candidate(context_id, doc.get_by_id(context_id))
    return candidates


def _construction_owner_checks(doc, surf_el, context_ids=None):
    """Trace every schema-valid owner checked for nrg3:layeredConstruction."""
    checks = []
    seen = set()

    def add(owner_id, owner_el, role):
        key = owner_id or id(owner_el)
        if key in seen:
            return
        seen.add(key)
        constr_el = _construction_element(doc, owner_el)
        checks.append({
            "role": role,
            "owner_id": owner_id,
            "owner_type": local_name(owner_el) if owner_el is not None else None,
            "has_layeredConstruction": constr_el is not None,
            "construction_id": constr_el.get(GML_ID) if constr_el is not None else None,
            "construction_type": local_name(constr_el) if constr_el is not None else None,
        })

    add(surf_el.get(GML_ID) if surf_el is not None else None, surf_el, "surface")
    for context_id in context_ids or []:
        add(context_id, doc.get_by_id(context_id), "context")
    return checks


# ===== resolution trace ======================================================
def _new_trace(surface_record, surf_el, owner_checks):
    """Fresh, empty resolution trace for one surface (filled in as tiers run)."""
    return {
        "surface_id": surface_record.source_id,
        "source_gml_id": surface_record.source_gml_id or surface_record.source_id,
        "surface_xml_type": local_name(surf_el) if surf_el is not None else None,
        "candidate_owners_checked": owner_checks,
        "selected_owner": None,
        "selected_construction_id": None,
        "selected_construction_type": None,
        "source": None,
        "why_default": None,
    }


def _select_trace(trace, owner_id, constr_el, source):
    """Record which owner/construction the waterfall selected."""
    trace.update({
        "selected_owner": owner_id,
        "selected_construction_id": constr_el.get(GML_ID) if constr_el is not None else None,
        "selected_construction_type": local_name(constr_el) if constr_el is not None else None,
        "source": source,
    })
    return trace


# ===== the TIER waterfall (raw converter) ====================================
# Resolve ONE surface's construction. MOST DETAILED FIRST. This is the RAW CONVERTER:
# it reads ONLY the CityGML's own data (Tiers 1-2), then a project default (Tier 4).
#   TIER 1  CityGML DETAILED layers — the construction's own inline nrg:layer
#           (reached by xlink or inline nesting; property_object already followed it,
#           so `constr_el` IS the referenced construction). Named by gml:id.
#   TIER 2  CityGML AVERAGED value  — no layers, only nrg:uValue -> Material:NoMass
#           (R = 1/U). The typical LoD1 hull case.
#   TIER 4  DEFAULT construction    — nothing usable in the CityGML.
# TIER 3 (the EXTERNAL archetype fallback, keyed by building function/year/weight) is
# DEFERRED to the end of the project and lives in model/archetypes.py (a swappable JSON,
# NOT Excel). It is NOT wired here: the professor asked for the raw converter first, and
# raw CityGML data always beats an archetype, so it would only ever slot in BETWEEN Tier
# 2 and Tier 4. No libraryCode/codeSpace lookup — link is by gml:id only (like the prof).
def _resolve_surface(doc, surf_el, surface_record, materials):
    """Return (construction_name, resolved_dict, trace) for one surface."""
    # For LoD1 raw solids, surf_el is a gml:Polygon and cannot own Energy ADE
    # layeredConstruction; the construction comes from the ThermalZone / Building
    # context passed in context_ids.
    context_ids = surface_record.construction_context_ids
    trace = _new_trace(surface_record, surf_el, _construction_owner_checks(doc, surf_el, context_ids))
    candidates = _construction_candidates(doc, surf_el, context_ids)

    # ===== TIER 1 + TIER 2 : the CityGML's OWN data (try every owner first) =====
    #   TIER 1  detailed inline layers; TIER 2  no layers but a uValue -> NoMass (R = 1/U).
    #   Both come out of _from_citygml (it returns "layers" for either case).
    for owner_id, constr_el in candidates:
        name = _construction_name(doc, constr_el)
        resolved = _from_citygml(doc, constr_el, materials)    # T1 layers, or T2 uValue
        if resolved.layers:
            resolved.name = name
            resolved.source_context_id = owner_id
            _select_trace(trace, owner_id, constr_el, resolved.source)
            trace["resolved_construction"] = {
                "name": name,
                "source": resolved.source,
                "layers": list(resolved.layers),
                "layer_order": resolved.layer_order,
                "source_context_id": resolved.source_context_id,
            }
            return name, resolved, trace

    # ===== TIER 3 : EXTERNAL ARCHETYPE — DEFERRED (see the waterfall comment) =====
    # A construction with no CityGML layers/uValue has no raw data to convert; in the raw
    # converter it falls through to the default. The archetype JSON (model/archetypes.py),
    # keyed by building function/year/weight, will fill this gap LATER.

    # ===== TIER 4 : DEFAULT =====
    materials.setdefault(DEFAULT_MATERIAL.name, DEFAULT_MATERIAL)
    trace["source"] = "default"
    trace["why_default"] = ("no CityGML detailed layers (T1) and no uValue (T2); "
                            "archetype fallback (T3) is deferred")
    trace["resolved_construction"] = {
        "name": DEFAULT_NAME,
        "source": "default",
        "layers": [DEFAULT_MATERIAL.name],
        "layer_order": ADE_LAYER_ORDER,
        "source_context_id": None,
    }
    return DEFAULT_NAME, Construction(name=DEFAULT_NAME, layers=[DEFAULT_MATERIAL.name],
                                      source="default"), trace


def _construction_provenance_line(resolved, trace):
    """One readable line summarising how a surface's construction resolved (replaces the
    old nested construction_trace dict; folded into Surface.provenance['construction'])."""
    if resolved.source == "default":
        return ("default construction — no CityGML detailed layers (T1) or uValue (T2); "
                "archetype (T3) deferred")
    line = resolved.source                                  # citygml_layers | citygml_uvalue | reversed
    construction_id = trace.get("selected_construction_id")
    if construction_id:
        line += f" from construction '{construction_id}'"
    if resolved.source_context_id:
        line += f" (owner {resolved.source_context_id})"
    return line


def resolve_all(doc, middle):
    """Resolve every surface in the middle layer; fill middle['constructions'] and
    middle['materials'] (deduped) and tag each surface with its construction name.
    Constructions and materials are found by gml:id (inline or xlink) only — no
    libraryCode/codeSpace lookup (like the reference repo)."""
    constructions, materials = {}, {}
    for b in middle.buildings:
        for s in b.surfaces:
            surf_el = doc.get_by_id(s.source_gml_id or s.source_id)
            name, resolved, trace = _resolve_surface(doc, surf_el, s, materials)
            s.construction = name
            s.provenance["construction"] = _construction_provenance_line(resolved, trace)
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
