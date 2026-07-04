"""
model/constructions.py — the LIBRARIAN. Resolve each surface's construction into
ordered EnergyPlus material layers.

This module is the RESOLVER: it walks the construction owners of a surface and runs
the TIER waterfall (see _resolve_surface). The pieces it stands on were split out for
readability and live next door:
    units.py        — value coercion + unit conversion (metres, W/m-K, …)
    citygml_read.py — typed GML child readers (_first_el/_child_text/_measure/_code)
    materials.py    — the 3 EnergyPlus material builders + DEFAULT_MATERIAL
    catalogue.py    — Excel/DB + in-file library, keyed by (codeSpace, code)

HOW A CONSTRUCTION AND ITS MATERIALS FIND EACH OTHER (Energy ADE 3.0):
  The STRUCTURAL link (construction -> layer -> material) is by gml:id — inline
  nesting OR xlink:href. It is NOT libraryCode. `libraryCode` (a gml:CodeType,
  qualified by its `codeSpace` attribute) is a SEPARATE catalogue key, used to look
  the construction/material up in a library or external DB. So the identity of a
  catalogue entry is the PAIR (codeSpace, code) — never the bare code, because two
  catalogues may reuse the same code string for different things.

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
from .catalogue import (COLUMN_MAP, DEFAULT_DB, SHEET_NAMES, _element_has_layers,
                        _excel_match, _index_file_library, _library_member_for_code,
                        _load_database_or_empty, load_database)
from .citygml_read import _child_code, _child_measure, _child_text, _first_el
from .materials import (DEFAULT_MATERIAL, DEFAULT_ROUGHNESS, _material_from_citygml,
                        _material_from_excel)
from .units import _length_to_meters, _num, _u_value_to_w_per_m2_k

# Compatibility re-exports: openings.py / zones.py / reader.py import several of the
# names above through this module (e.g. `from .constructions import _child_text, _num`,
# `constructions.COLUMN_MAP`). They now LIVE in the split modules; importing them here
# keeps `constructions.<name>` working so those callers need no change.

DEFAULT_NAME = "DEFAULT_CONSTRUCTION"
ADE_LAYER_ORDER = "inside_to_outside" # in ernergy ade specifcation (3.8 The Layered construction module)


# ===== construction builders (the 3 branches) ================================
def _from_excel(code, db, materials, reverse=False):
    """Build a construction from the Excel/DB catalogue entry `code`."""
    layer_names = list(db["constructions"][code])
    if reverse:
        layer_names = list(reversed(layer_names))
    for mname in layer_names:
        materials.setdefault(mname, _material_from_excel(mname, db))
    return {"source": "excel", "layers": layer_names, "layer_order": ADE_LAYER_ORDER,
            "reversed": reverse}


def _base_layered_construction(doc, constr_el):
    """The baseLayeredConstruction a ReverseLayeredConstruction points to, or None."""
    props = doc.children(constr_el, "nrg", "baseLayeredConstruction")
    return _first_el(doc, props[0]) if props else None


def _construction_code_info(doc, constr_el):
    """Read LayeredConstruction.libraryCode with its codeSpace.

    ReverseLayeredConstruction may omit its own code and point to a base
    LayeredConstruction; in that case the base construction code is used.
    """
    code, code_space = _child_code(doc, constr_el, "nrg", "libraryCode")
    if code or constr_el is None or local_name(constr_el) != "ReverseLayeredConstruction":
        return {"value": code, "codeSpace": code_space}
    base = _base_layered_construction(doc, constr_el)
    code, code_space = _child_code(doc, base, "nrg", "libraryCode")
    return {"value": code, "codeSpace": code_space,
            "from_base": base.get(GML_ID) if base is not None else None}


def _construction_code(doc, constr_el):
    """The libraryCode string of a construction (ignoring codeSpace)."""
    return _construction_code_info(doc, constr_el)["value"]


def _construction_name(doc, constr_el, code):
    """A stable E+ construction name: the code, else the gml:id, else a default."""
    if constr_el is None:
        return DEFAULT_NAME
    if local_name(constr_el) == "ReverseLayeredConstruction":
        return constr_el.get(GML_ID) or ((code + "_Rev") if code else "reverse_construction")
    return code or (constr_el.get(GML_ID) or "construction")


# CityGML construction fallback:
# parse ordered Layer -> thickness -> material first; if no layers exist, use
# LayeredConstruction.uValue as an averaged no-mass construction (R = 1 / U).
def _from_citygml(doc, constr_el, materials):
    """Build a construction from a LayeredConstruction's own inline layers, or its
    uValue (R = 1/U). Returns {"layers": [...]} for either; empty layers = nothing usable."""
    if constr_el is None:
        return {"source": "citygml_none", "layers": [], "layer_order": ADE_LAYER_ORDER}
    # It points by XLink to a base LayeredConstruction, and means “use the same layers but reversed.”
    if local_name(constr_el) == "ReverseLayeredConstruction":
        base = _base_layered_construction(doc, constr_el)
        if base is None:
            warn(f"reverse construction '{constr_el.get(GML_ID)}': missing baseLayeredConstruction")
            return {"source": "citygml_reverse_missing_base", "layers": []}
        resolved = _from_citygml(doc, base, materials)
        return {"source": resolved.get("source", "citygml"),
                "layers": list(reversed(resolved.get("layers", []))),
                "layer_order": ADE_LAYER_ORDER,
                "reversed": True,
                "base": base.get(GML_ID)}

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
        m = _material_from_citygml(doc, mat_el, thickness, layer)
        materials.setdefault(m["name"], m)
        layers.append(m["name"])
    if layers:
        return {"source": "citygml_layers", "layers": layers, "layer_order": ADE_LAYER_ORDER}

    # Energy ADE LayeredConstructionType has optional uValue. EnergyPlus has no
    # direct U-value material, so for opaque averaged data we emit NoMass R=1/U.
    u_raw, u_uom = _child_measure(doc, constr_el, "nrg", "uValue")
    u_value = _u_value_to_w_per_m2_k(u_raw, u_uom,
                                     context=f"construction '{constr_el.get(GML_ID)}' uValue")
    if u_value and u_value > 0:
        mat_name = (constr_el.get(GML_ID) or "citygml_construction") + "_UValue"
        materials.setdefault(mat_name, {"name": mat_name,
                                        "eplus": "Material:NoMass",
                                        "roughness": DEFAULT_ROUGHNESS,
                                        "thermal_resistance": 1.0 / u_value,
                                        "source": "citygml_uvalue",
                                        "raw_citygml": {"uValue": u_raw, "uValue_uom": u_uom},
                                        "converted": {"u_value": {"value": u_value, "unit": "W/m2-K"},
                                                      "thermal_resistance": {"value": 1.0 / u_value,
                                                                             "unit": "m2-K/W"}}})
        return {"source": "citygml_uvalue", "layers": [mat_name], "layer_order": ADE_LAYER_ORDER,
                "u_value": u_value, "u_value_uom": u_uom}

    warn(f"construction '{constr_el.get(GML_ID)}': no layers or uValue; using default")
    return {"source": "citygml", "layers": [], "layer_order": ADE_LAYER_ORDER}


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
def _with_context(resolved, owner_id):
    """Tag a resolved construction with the owner id it came from."""
    out = dict(resolved)
    if owner_id:
        out["source_context_id"] = owner_id
    return out


def _new_trace(surface_record, surf_el, owner_checks):
    """Fresh, empty resolution trace for one surface (filled in as tiers run)."""
    return {
        "surface_id": surface_record.get("source_id"),
        "source_gml_id": surface_record.get("source_gml_id") or surface_record.get("source_id"),
        "surface_xml_type": local_name(surf_el) if surf_el is not None else None,
        "candidate_owners_checked": owner_checks,
        "selected_owner": None,
        "selected_construction_id": None,
        "selected_construction_type": None,
        "libraryCode": None,
        "libraryCodeSpace": None,
        "source": None,
        "why_default": None,
    }


def _select_trace(trace, owner_id, constr_el, code_info, source):
    """Record which owner/construction/code the waterfall selected."""
    trace.update({
        "selected_owner": owner_id,
        "selected_construction_id": constr_el.get(GML_ID) if constr_el is not None else None,
        "selected_construction_type": local_name(constr_el) if constr_el is not None else None,
        "libraryCode": code_info.get("value") if code_info else None,
        "libraryCodeSpace": code_info.get("codeSpace") if code_info else None,
        "source": source,
    })
    return trace


# ===== the TIER waterfall (meeting decision) =================================
# Resolve ONE surface's construction. MOST DETAILED FIRST; the external code/Excel is
# the LAST fallback, never first.
#   TIER 1  CityGML DETAILED layers — the construction's own inline nrg:layer, OR an
#           in-file LayeredConstructionLibrary member (reached by xlink OR by the
#           (codeSpace, code) pair).
#   TIER 2  CityGML AVERAGED value  — no layers, only nrg:uValue -> Material:NoMass
#           (R = 1/U). The typical LoD1 hull case.
#   TIER 3  EXTERNAL Excel/DB code  — (codeSpace, code) -> construction_db.xlsx.
#           PLACEHOLDER for the archetype (TABULA / UBEM-CARDs) DB. LAST fallback,
#           reached ONLY when the CityGML gave nothing. Raw data always beats a code.
#   TIER 4  DEFAULT construction    — nothing usable anywhere.
# Tiers 1+2 are read from the CityGML (already in memory), so there is NO speed reason
# to check the Excel first. (xlink is implicit: property_object already followed it,
# so `constr_el` IS the referenced object.)
def _resolve_surface(doc, surf_el, surface_record, db, materials, file_library):
    """Return (construction_name, resolved_dict, trace) for one surface."""
    # For LoD1 raw solids, surf_el is a gml:Polygon and cannot own Energy ADE
    # layeredConstruction; the construction comes from the ThermalZone / Building
    # context passed in context_ids.
    context_ids = surface_record.get("construction_context_ids")
    trace = _new_trace(surface_record, surf_el, _construction_owner_checks(doc, surf_el, context_ids))
    candidates = _construction_candidates(doc, surf_el, context_ids)

    # ===== TIER 1 + TIER 2 : the CityGML's OWN data (try every owner first) =====
    #   TIER 1  detailed inline layers, or the in-file library member that holds them
    #           (own inline wins; else the (codeSpace, code) library member).
    #   TIER 2  no layers but a uValue -> Material:NoMass (R = 1/U).
    #   Both come out of _from_citygml (it returns "layers" for either case).
    for owner_id, constr_el in candidates:
        code_info = _construction_code_info(doc, constr_el)
        code = code_info["value"]
        code_space = code_info["codeSpace"]
        name = _construction_name(doc, constr_el, code)
        reverse = constr_el is not None and local_name(constr_el) == "ReverseLayeredConstruction"

        drill_el = constr_el
        if code and not reverse and not _element_has_layers(doc, constr_el):
            member = _library_member_for_code(code, code_space, file_library)
            if member is not None and member is not constr_el and _element_has_layers(doc, member):
                drill_el = member

        resolved = _from_citygml(doc, drill_el, materials)     # T1 layers, or T2 uValue
        if resolved.get("layers"):
            resolved = _with_context(resolved, owner_id)
            _select_trace(trace, owner_id, constr_el, code_info, resolved["source"])
            return name, resolved, trace

    # ===== TIER 3 : EXTERNAL Excel/DB by (codeSpace, code) — LAST fallback =====
    # ARCHETYPE placeholder (TABULA / UBEM-CARDs). This is only the code->Excel LOOKUP;
    # the real archetype logic is NOT built (deferred: "raw converter first, archetypes
    # LAST"). It fires ONLY here, after the CityGML tiers gave nothing. Raw data always
    # beats a code. LATER (the real archetype rung): read the archetype KEY from the
    # CityGML — the field(s) for building type/age (bldg:yearOfConstruction +
    # bldg:function/usage, + nrg3:bdgType). FIRST confirm which ADE field carries the
    # archetype (the open question the prof flagged); that field becomes the lookup key.
    # Map (type, age-band) -> a construction in the EXTERNAL DB — we do NOT invent the
    # numbers (TABULA / UBEM-CARDs, prepared by the teammate). construction_db.xlsx is
    # only a PLACEHOLDER; swap it via SHEET_NAMES/COLUMN_MAP (its own columns, e.g.
    # use_type/period/u_wall/…) with no pipeline change.
    for owner_id, constr_el in candidates:
        code_info = _construction_code_info(doc, constr_el)
        code = code_info["value"]
        code_space = code_info["codeSpace"]
        if _excel_match(code, code_space, db):
            name = _construction_name(doc, constr_el, code)
            reverse = constr_el is not None and local_name(constr_el) == "ReverseLayeredConstruction"
            resolved = _with_context(_from_excel(code, db, materials, reverse=reverse), owner_id)
            _select_trace(trace, owner_id, constr_el, code_info, resolved["source"])
            return name, resolved, trace
        if code:
            warn(f"construction code '{code}' (codeSpace={code_space!r}) has no CityGML "
                 f"layers/uValue and is not in the Excel/DB")

    # ===== TIER 4 : DEFAULT =====
    materials.setdefault(DEFAULT_MATERIAL["name"], DEFAULT_MATERIAL)
    trace["source"] = "default"
    trace["why_default"] = ("no CityGML detailed layers (T1), no uValue (T2), "
                            "and no Excel/DB (codeSpace, code) match (T3)")
    return DEFAULT_NAME, {"source": "default", "layers": [DEFAULT_MATERIAL["name"]],
                          "layer_order": ADE_LAYER_ORDER}, trace


def resolve_all(doc, middle, database=None):
    """Resolve every surface in the middle layer; fill middle['constructions'] and
    middle['materials'] (deduped) and tag each surface with its construction name."""
    database = database if database is not None else _load_database_or_empty()
    # The file's OWN catalogue (LayeredConstructionLibrary members), indexed by
    # (codeSpace, code) so a construction named only by libraryCode still resolves
    # even when it was not reached by xlink. Built once for the whole document.
    file_library = _index_file_library(doc)
    constructions, materials = {}, {}
    for b in middle["buildings"]:
        for s in b["surfaces"]:
            surf_el = doc.get_by_id(s.get("source_gml_id") or s["source_id"])
            name, resolved, trace = _resolve_surface(doc, surf_el, s, database, materials, file_library)
            s["construction"] = name
            s["construction_trace"] = trace
            constructions.setdefault(name, resolved)
    middle["constructions"] = constructions
    middle["materials"] = materials
    return constructions, materials


def _demo(path=None):
    from .reader import build_middle_layer
    doc = xml_io.CityGMLDoc(path or xml_io.DEFAULT_INPUT)
    middle = build_middle_layer(doc)
    constructions, materials = resolve_all(doc, middle)
    used = Counter(s["construction"] for b in middle["buildings"] for s in b["surfaces"])
    print(f"{len(constructions)} construction(s), {len(materials)} material(s)")
    for name, c in constructions.items():
        print(f"\n[{c['source'].upper():7}] {name}  (used by {used[name]} surface(s))")
        for mname in c["layers"]:
            m = materials[mname]
            detail = (f"R={m.get('thermal_resistance')}" if m["eplus"] != "Material"
                      else f"t={m.get('thickness')} k={m.get('conductivity')} "
                           f"rho={m.get('density')} cp={m.get('specific_heat')}")
            print(f"    {m['eplus']:<16} {mname:<32} {detail}")


if __name__ == "__main__":
    _demo(sys.argv[1] if len(sys.argv) > 1 else None)
