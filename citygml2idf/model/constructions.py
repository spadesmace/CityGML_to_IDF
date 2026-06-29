"""
model/constructions.py — the LIBRARIAN. Resolve each surface's construction into
ordered EnergyPlus material layers, via the Excel-FIRST waterfall (MAPPING.md C/D).

Per surface's construction:
  1. its `libraryCode` is in the Excel   -> build from the EXCEL          (primary)
  2. code missing/unknown -> drill the file's own LayeredConstruction/Layer/Material
  3. nothing usable -> a generic DEFAULT construction + warning

Each layer becomes ONE of the 3 EnergyPlus material objects, chosen by the SOURCE
(never guessed): `Material` / `Material:NoMass` / `Material:AirGap`. Same construction
on many surfaces is resolved ONCE (dedup). All Excel-shape knowledge lives in
SHEET_NAMES / COLUMN_MAP — change the spreadsheet, not the code.

Run as a demo (from the repo root):
    python -m citygml2idf.model.constructions
resolves every surface and prints each construction's branch + layers + E+ material type.
"""

from __future__ import annotations

import math
import os
import sys
from collections import Counter

import pandas as pd

from ..citygml import xml_io
from ..citygml.xml_io import GML_ID, local_name, warn

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG = os.path.dirname(_HERE)
DEFAULT_DB = os.path.join(_PKG, "input", "construction_db.xlsx")

# ===== the ONLY place that knows the spreadsheet's shape =====================
SHEET_NAMES = {"constructions": "constructions", "materials": "materials", "windows": "windows"}
COLUMN_MAP = {
    "code": "code", "layer_order": "layer_order", "material_name": "material_name",
    "material_type": "material_type", "thickness": "thickness", "conductivity": "conductivity",
    "density": "density", "specific_heat": "specific_heat", "roughness": "roughness",
    "thermal_resistance": "thermal_resistance",
    "u_value": "u_value", "g_value": "g_value",   # windows sheet (used by model/openings.py)
}

# ===== defaults (RULES M2): never emit a material missing a required field ====
DEFAULT_ROUGHNESS = "MediumRough"
DEFAULT_MATERIAL = {"name": "DEFAULT_OPAQUE", "eplus": "Material", "thickness": 0.20,
                    "conductivity": 1.0, "density": 1800.0, "specific_heat": 1000.0,
                    "roughness": DEFAULT_ROUGHNESS}
DEFAULT_NAME = "DEFAULT_CONSTRUCTION"
ADE_LAYER_ORDER = "inside_to_outside"


# ----- small value helpers ---------------------------------------------------
def _num(v, default=None):
    if v is None or (isinstance(v, float) and math.isnan(v)):
        return default
    try:
        return float(v)
    except (TypeError, ValueError):
        return default


def _str(v, default=None):
    if v is None or (isinstance(v, float) and math.isnan(v)):
        return default
    return str(v)


def _first_el(doc, prop):
    """The object inside a property: its inline child, or the xlink it points to."""
    return doc.property_object(prop)


def _child_text(doc, parent, prefix, local):
    if parent is None:
        return None
    els = doc.children(parent, prefix, local)
    return els[0].text.strip() if els and els[0].text and els[0].text.strip() else None


def _child_measure(doc, parent, prefix, local):
    """Return (numeric value, uom) for a gml:MeasureType-like child."""
    if parent is None:
        return None, None
    els = doc.children(parent, prefix, local)
    if not els:
        return None, None
    el = els[0]
    text = el.text.strip() if el.text and el.text.strip() else None
    return _num(text), (el.get("uom") or "").strip()


def _length_to_meters(value, uom, context="length"):
    """EnergyPlus expects material thickness in metres."""
    if value is None:
        return None
    unit = (uom or "m").strip().lower()
    if unit in ("m", "meter", "meters", "metre", "metres"):
        return value
    if unit in ("mm", "millimeter", "millimeters", "millimetre", "millimetres"):
        return value / 1000.0
    if unit in ("cm", "centimeter", "centimeters", "centimetre", "centimetres"):
        return value / 100.0
    warn(f"{context}: unknown length unit '{uom}', assuming metres")
    return value


def _specific_heat_to_j_per_kg_k(value, uom, context="specific heat"):
    """EnergyPlus Material requires specific heat in J/kg-K and at least 100."""
    if value is None:
        return None
    unit = (uom or "J/kg-K").strip().lower().replace(" ", "")
    if "kj" in unit:
        value *= 1000.0
    if value < 100.0:
        warn(f"{context}: value {value} J/kg-K is below EnergyPlus minimum; using default {DEFAULT_MATERIAL['specific_heat']}")
        return DEFAULT_MATERIAL["specific_heat"]
    return value


def _gas_resistance_for_energyplus(doc, mat_el, name):
    """EnergyPlus Material:AirGap thermal resistance is m2-K/W."""
    value, uom = _child_measure(doc, mat_el, "nrg", "rValue")
    unit = (uom or "").lower().replace(" ", "")
    if value is not None and ("m2" in unit or "m^2" in unit) and "k" in unit and "w" in unit:
        return value
    if value is not None:
        warn(f"gas material '{name}': rValue unit '{uom}' is not EnergyPlus thermal resistance; using 0.15")
    return 0.15


def _empty_database():
    return {"constructions": {}, "materials": {}}


def _load_database_or_empty():
    try:
        return load_database()
    except Exception as exc:
        warn(f"could not load Excel construction database ({type(exc).__name__}: {exc}); using CityGML/default fallback")
        return _empty_database()


# ===== Excel database ========================================================
def load_database(xlsx_path=DEFAULT_DB):
    """Read the spreadsheet into {constructions: code->[material_name…], materials:
    name->row}. Lookup by key, never row position (extra rows/cols are fine)."""
    cons_df = pd.read_excel(xlsx_path, sheet_name=SHEET_NAMES["constructions"])
    mats_df = pd.read_excel(xlsx_path, sheet_name=SHEET_NAMES["materials"])
    constructions = {}
    for code, grp in cons_df.groupby(COLUMN_MAP["code"]):
        grp = grp.sort_values(COLUMN_MAP["layer_order"])          # 1 = inside (Energy ADE)
        constructions[str(code)] = [str(m) for m in grp[COLUMN_MAP["material_name"]]]
    materials = {str(r[COLUMN_MAP["material_name"]]): r.to_dict() for _, r in mats_df.iterrows()}
    return {"constructions": constructions, "materials": materials}


# ===== material builders (one of the 3 E+ objects) ===========================
def _material_from_excel(name, db):
    row = db["materials"].get(name)
    if row is None:
        warn(f"material '{name}' missing from Excel materials sheet; using default")
        return dict(DEFAULT_MATERIAL, name=name)
    mtype = _str(row.get(COLUMN_MAP["material_type"]), "Material")
    if mtype == "Material:AirGap":
        return {"name": name, "eplus": "Material:AirGap",
                "thermal_resistance": _num(row.get(COLUMN_MAP["thermal_resistance"]), 0.15)}
    if mtype == "Material:NoMass":
        return {"name": name, "eplus": "Material:NoMass",
                "roughness": _str(row.get(COLUMN_MAP["roughness"]), DEFAULT_ROUGHNESS),
                "thermal_resistance": _num(row.get(COLUMN_MAP["thermal_resistance"]), 0.1)}
    return {"name": name, "eplus": "Material",
            "thickness": _num(row.get(COLUMN_MAP["thickness"]), 0.1),
            "conductivity": _num(row.get(COLUMN_MAP["conductivity"]), 1.0),
            "density": _num(row.get(COLUMN_MAP["density"]), 1800.0),
            "specific_heat": _num(row.get(COLUMN_MAP["specific_heat"]), 1000.0),
            "roughness": _str(row.get(COLUMN_MAP["roughness"]), DEFAULT_ROUGHNESS)}


def _citygml_material_name(mat_el, layer_el=None):
    mat_id = mat_el.get(GML_ID) if mat_el is not None else "citygml_material"
    layer_id = layer_el.get(GML_ID) if layer_el is not None else None
    return f"{layer_id}_{mat_id}" if layer_id else mat_id


def _material_from_citygml(doc, mat_el, thickness, layer_el=None):
    """SolidMaterial -> Material; Gas -> Material:AirGap; incomplete -> NoMass fallback."""
    if mat_el is None:
        return dict(DEFAULT_MATERIAL, name=_citygml_material_name(mat_el, layer_el))
    name = _citygml_material_name(mat_el, layer_el)
    if local_name(mat_el) == "Gas":
        return {"name": name, "eplus": "Material:AirGap",
                "thermal_resistance": _gas_resistance_for_energyplus(doc, mat_el, name)}
    cond = _num(_child_text(doc, mat_el, "nrg", "thermalConductivity"))
    dens = _num(_child_text(doc, mat_el, "nrg", "density"))
    cp_value, cp_uom = _child_measure(doc, mat_el, "nrg", "specificHeatCapacity")
    cp = _specific_heat_to_j_per_kg_k(cp_value, cp_uom, context=f"material '{name}' specificHeatCapacity")
    if cond and dens and cp and thickness:
        return {"name": name, "eplus": "Material", "thickness": thickness,
                "conductivity": cond, "density": dens, "specific_heat": cp,
                "roughness": DEFAULT_ROUGHNESS}
    if cond and thickness:                                        # mass data missing
        warn(f"material '{name}': no density/specific-heat; fallback to NoMass")
        return {"name": name, "eplus": "Material:NoMass",
                "roughness": DEFAULT_ROUGHNESS, "thermal_resistance": thickness / cond}
    warn(f"material '{name}': insufficient data; using default")
    return dict(DEFAULT_MATERIAL, name=name)


# ===== construction builders (the 3 branches) ================================
def _from_excel(code, db, materials, reverse=False):
    layer_names = list(db["constructions"][code])
    if reverse:
        layer_names = list(reversed(layer_names))
    for mname in layer_names:
        materials.setdefault(mname, _material_from_excel(mname, db))
    return {"source": "excel", "layers": layer_names, "layer_order": ADE_LAYER_ORDER,
            "reversed": reverse}


def _base_layered_construction(doc, constr_el):
    props = doc.children(constr_el, "nrg", "baseLayeredConstruction")
    return _first_el(doc, props[0]) if props else None


def _construction_code(doc, constr_el):
    code = _child_text(doc, constr_el, "nrg", "libraryCode")
    if code or constr_el is None or local_name(constr_el) != "ReverseLayeredConstruction":
        return code
    return _child_text(doc, _base_layered_construction(doc, constr_el), "nrg", "libraryCode")


def _construction_name(doc, constr_el, code):
    if constr_el is None:
        return DEFAULT_NAME
    if local_name(constr_el) == "ReverseLayeredConstruction":
        return constr_el.get(GML_ID) or ((code + "_Rev") if code else "reverse_construction")
    return code or (constr_el.get(GML_ID) or "construction")


# CityGML construction fallback:
# parse ordered Layer -> thickness -> material first; if no layers exist, use
# LayeredConstruction.uValue as an averaged no-mass construction (R = 1 / U).
def _from_citygml(doc, constr_el, materials):
    if constr_el is None:
        return {"source": "citygml", "layers": [], "layer_order": ADE_LAYER_ORDER}

    if local_name(constr_el) == "ReverseLayeredConstruction":
        base = _base_layered_construction(doc, constr_el)
        if base is None:
            warn(f"reverse construction '{constr_el.get(GML_ID)}': missing baseLayeredConstruction")
            return {"source": "citygml", "layers": []}
        resolved = _from_citygml(doc, base, materials)
        return {"source": resolved.get("source", "citygml"),
                "layers": list(reversed(resolved.get("layers", []))),
                "layer_order": ADE_LAYER_ORDER,
                "reversed": True,
                "base": base.get(GML_ID)}

    layers = []
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
        return {"source": "citygml", "layers": layers, "layer_order": ADE_LAYER_ORDER}

    # Energy ADE LayeredConstructionType has optional uValue. EnergyPlus has no
    # direct U-value material, so for opaque averaged data we emit NoMass R=1/U.
    u_value, _ = _child_measure(doc, constr_el, "nrg", "uValue")
    if u_value and u_value > 0:
        mat_name = (constr_el.get(GML_ID) or "citygml_construction") + "_UValue"
        materials.setdefault(mat_name, {"name": mat_name,
                                        "eplus": "Material:NoMass",
                                        "roughness": DEFAULT_ROUGHNESS,
                                        "thermal_resistance": 1.0 / u_value})
        return {"source": "citygml", "layers": [mat_name], "layer_order": ADE_LAYER_ORDER,
                "u_value": u_value}

    warn(f"construction '{constr_el.get(GML_ID)}': no layers or uValue; using default")
    return {"source": "citygml", "layers": [], "layer_order": ADE_LAYER_ORDER}


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


def _with_context(resolved, owner_id):
    out = dict(resolved)
    if owner_id:
        out["source_context_id"] = owner_id
    return out


# Resolve one surface's construction:
# 1) Excel by libraryCode, 2) CityGML layers/materials, 3) CityGML uValue,
# 4) default only when no candidate has usable data.
def _resolve_surface(doc, surf_el, context_ids, db, materials):
    """Return (construction_name, resolved_dict) for one surface — the waterfall.
    1. Excel-first:  surface -> nrg:layeredConstruction -> libraryCode -> look up in construction_db.xlsx
    2. In-file:      drill the file's own nrg:Layer / nrg:Material
    3. Default:      generic construction + warning"""
    # For LoD1 raw solids, surf_el is a gml:Polygon and cannot own Energy ADE
    # layeredConstruction. The valid averaged construction path is via the
    # ThermalZone / Building context passed in context_ids.
    for owner_id, constr_el in _construction_candidates(doc, surf_el, context_ids):
        code = _construction_code(doc, constr_el)
        name = _construction_name(doc, constr_el, code)
        reverse = constr_el is not None and local_name(constr_el) == "ReverseLayeredConstruction"

        if code and code in db.get("constructions", {}):             # 1. Excel-first
            return name, _with_context(_from_excel(code, db, materials, reverse=reverse), owner_id)
        resolved = _from_citygml(doc, constr_el, materials)           # 2. CityGML fallback
        if resolved.get("layers"):
            return name, _with_context(resolved, owner_id)
        if code:
            warn(f"construction code '{code}' not in Excel and CityGML construction is incomplete")
    
    #####################         EPC improvement #################

    # 2b. FUTURE RUNG — NOT BUILT YET :
    #     when a building has geometry but NO construction (e.g. a bare LOD1/1.2 box
    #     like B1), DERIVE an archetype construction from the building's
    #     bldg:yearOfConstruction + bldg:function/usage (+ nrg3:bdgType) -> a TABULA
    #     archetype code -> look that code up in the Excel. It slots in HERE, BEFORE
    #     the flat default, so poor files still get realistic materials. This needs
    #     the BUILDING's attributes threaded down into _resolve_surface. Example:
    #         arch = archetype_code(year, use)            # the old envelope_eff logic
    #         if arch in db["constructions"]:
    #             return arch, _from_excel(arch, db, materials)
    #     (EPC-based thermal-zone splitting is a MUCH later step — out of scope now.)

    materials.setdefault(DEFAULT_MATERIAL["name"], DEFAULT_MATERIAL)  # 3. default
    return DEFAULT_NAME, {"source": "default", "layers": [DEFAULT_MATERIAL["name"]],
                          "layer_order": ADE_LAYER_ORDER}


def resolve_all(doc, middle, database=None):
    """Resolve every surface in the middle layer; fill middle['constructions'] and
    middle['materials'] (deduped) and tag each surface with its construction name."""
    database = database if database is not None else _load_database_or_empty()
    constructions, materials = {}, {}
    for b in middle["buildings"]:
        for s in b["surfaces"]:
            surf_el = doc.get_by_id(s.get("source_gml_id") or s["source_id"])
            candidate_names = [
                _construction_name(doc, constr_el, _construction_code(doc, constr_el))
                for _, constr_el in _construction_candidates(doc, surf_el, s.get("construction_context_ids"))
            ]
            cached_name = next((name for name in candidate_names if name in constructions), None)
            if cached_name:
                s["construction"] = cached_name
                continue
            name, resolved = _resolve_surface(doc, surf_el, s.get("construction_context_ids"), database, materials)
            s["construction"] = name
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
