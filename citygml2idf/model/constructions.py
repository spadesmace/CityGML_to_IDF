"""
model/constructions.py — the LIBRARIAN. Resolve each surface's construction into
ordered EnergyPlus material layers.

HOW A CONSTRUCTION AND ITS MATERIALS FIND EACH OTHER (Energy ADE 3.0):
  The STRUCTURAL link (construction -> layer -> material) is by gml:id — inline
  nesting OR xlink:href. It is NOT libraryCode. `libraryCode` (a gml:CodeType,
  qualified by its `codeSpace` attribute) is a SEPARATE catalogue key, used to look
  the construction/material up in a library or external DB. So the identity of a
  catalogue entry is the PAIR (codeSpace, code) — never the bare code, because two
  catalogues may reuse the same code string for different things.

ORDER we resolve ONE surface's construction (each step BYPASSES the rest on success):
  0. xlink   — if the surface's nrg:layeredConstruction points by gml:id, it is
               already followed upstream, so we hold the referenced LayeredConstruction.
  1. EXCEL   — (codeSpace, code) is in the Excel/DB   -> build from the EXCEL   (primary)
  2. inline  — the construction's OWN nrg:layer list   -> most-local explicit layers
  3. library — it only NAMED a code; the layers live in a LayeredConstructionLibrary
               member -> find that member by (codeSpace, code) and drill it
  4. uValue  — no layers, only nrg:uValue              -> Material:NoMass (R = 1/U), averaged (LoD1)
  5. default — nothing usable                          -> generic DEFAULT construction + warning

Each layer becomes ONE of the 3 EnergyPlus material objects, chosen by the SOURCE
(never guessed): `Material` / `Material:NoMass` / `Material:AirGap`. Same construction
on many surfaces is resolved ONCE (dedup). All Excel-shape knowledge lives in
SHEET_NAMES / COLUMN_MAP — change the spreadsheet, not the code. The DB is treated as
ONE catalogue identified by EXCEL_CODESPACE, so a better DB can be swapped in later.

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
    "code": "code", "code_space": "code_space", "layer_order": "layer_order",
    "material_name": "material_name",
    "material_type": "material_type", "thickness": "thickness", "conductivity": "conductivity",
    "density": "density", "specific_heat": "specific_heat", "roughness": "roughness",
    "thermal_resistance": "thermal_resistance",
    "u_value": "u_value", "g_value": "g_value",   # windows sheet (used by model/openings.py)
}
# `code_space` qualifies which catalogue a `code` belongs to (the DB declares it as
# data, so a better DB can be swapped in). A blank cell = catalogue-agnostic. The
# entry identity is the PAIR (code_space, code) — never the bare code.

# ===== defaults (RULES M2): never emit a material missing a required field ====
DEFAULT_ROUGHNESS = "MediumRough"
DEFAULT_MATERIAL = {"name": "DEFAULT_OPAQUE", "eplus": "Material", "thickness": 0.20,
                    "conductivity": 1.0, "density": 1800.0,
                    # EnergyPlus minimum for Material.Specific Heat is 100 J/kg-K.
                    "specific_heat": 100.0,
                    "roughness": DEFAULT_ROUGHNESS}
DEFAULT_NAME = "DEFAULT_CONSTRUCTION"
ADE_LAYER_ORDER = "inside_to_outside" # in ernergy ade specifcation (3.8 The Layered construction module)


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


def _trace_value(v):
    """JSON-safe raw trace value: pandas blanks/NaN become null."""
    try:
        if pd.isna(v):
            return None
    except (TypeError, ValueError):
        pass
    if hasattr(v, "item"):
        try:
            return v.item()
        except (TypeError, ValueError):
            pass
    return v


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


def _child_code(doc, parent, prefix, local):
    """Return (code text, codeSpace) for a gml:CodeType-like child."""
    if parent is None:
        return None, None
    els = doc.children(parent, prefix, local)
    if not els:
        return None, None
    el = els[0]
    text = el.text.strip() if el.text and el.text.strip() else None
    return text, el.get("codeSpace")


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


def _conductivity_to_w_per_m_k(value, uom, context="conductivity"):
    """EnergyPlus Material requires conductivity in W/m-K."""
    if value is None:
        return None
    unit = (uom or "W/m-K").strip().lower().replace(" ", "")
    if unit.startswith("kw"):
        return value * 1000.0
    if "w" in unit and "m" in unit and "k" in unit:
        return value
    warn(f"{context}: unknown conductivity unit '{uom}', assuming W/m-K")
    return value


def _density_to_kg_per_m3(value, uom, context="density"):
    """EnergyPlus Material requires density in kg/m3."""
    if value is None:
        return None
    unit = (uom or "kg/m3").strip().lower().replace(" ", "")
    if unit in ("kg/m3", "kg/m^3", "kg/m**3"):
        return value
    if unit in ("g/cm3", "g/cm^3", "g/cm**3"):
        return value * 1000.0
    warn(f"{context}: unknown density unit '{uom}', assuming kg/m3")
    return value


def _specific_heat_to_j_per_kg_k(value, uom, context="specific heat"):
    """EnergyPlus Material requires specific heat in J/kg-K and at least 100 due to Energy+.idd"""
    if value is None:
        return None
    unit = (uom or "J/kg-K").strip().lower().replace(" ", "")
    if "kj" in unit:
        value *= 1000.0
    if value < 100.0:
        warn(f"{context}: value {value} J/kg-K is below EnergyPlus minimum; using default {DEFAULT_MATERIAL['specific_heat']}")
        return DEFAULT_MATERIAL["specific_heat"]
    return value


def _u_value_to_w_per_m2_k(value, uom, context="uValue"):
    """EnergyPlus R-only fallback needs U in W/m2-K so R = 1 / U."""
    if value is None:
        return None
    unit = (uom or "W/m2-K").strip().lower().replace(" ", "")
    if "w" in unit and ("m2" in unit or "m^2" in unit) and "k" in unit:
        return value
    warn(f"{context}: unknown uValue unit '{uom}', assuming W/m2-K")
    return value


def _airgap_resistance_for_energyplus(doc, mat_el, name):
    """EnergyPlus Material:AirGap thermal resistance is m2-K/W."""
    value, uom = _child_measure(doc, mat_el, "nrg", "rValue")
    unit = (uom or "").lower().replace(" ", "")
    if value is not None and ("m2" in unit or "m^2" in unit) and "k" in unit and "w" in unit:
        return value, {"raw_value": value, "raw_uom": uom, "eplus_unit": "m2-K/W",
                       "converted_value": value, "usable": True}
    if value is not None:
        reason = f"rValue unit '{uom}' is not EnergyPlus thermal resistance"
        warn(f"gas material '{name}': {reason}; using default opaque material for this layer")
        return None, {"raw_value": value, "raw_uom": uom, "eplus_unit": "m2-K/W",
                      "converted_value": None, "usable": False, "reason": reason}
    reason = "missing rValue"
    warn(f"gas material '{name}': {reason}; using default opaque material for this layer")
    return None, {"raw_value": None, "raw_uom": uom, "eplus_unit": "m2-K/W",
                  "converted_value": None, "usable": False, "reason": reason}


def _default_material_copy(name, reason):
    material = dict(DEFAULT_MATERIAL, name=name)
    material["source"] = "default"
    material["fallback_reason"] = reason
    return material


def _empty_database():
    return {"constructions": {}, "construction_codespaces": {}, "materials": {}}


def _load_database_or_empty():
    try:
        return load_database()
    except Exception as exc:
        warn(f"could not load Excel construction database ({type(exc).__name__}: {exc}); using CityGML/default fallback")
        return _empty_database()


# ===== Excel database ========================================================
def load_database(xlsx_path=DEFAULT_DB):
    """Read the spreadsheet into {constructions: code->[material_name…],
    construction_codespaces: code->codeSpace, materials: name->row}.
    Lookup by key, never row position (extra rows/cols are fine).

    The `code_space` column is REQUIRED — it is the catalogue half of the
    (codeSpace, code) identity. A missing column RAISES (caught by
    _load_database_or_empty, which warns and degrades to CityGML/default) rather
    than silently matching by bare code, which would re-open the cross-catalogue
    collision this design exists to prevent. A blank CELL is fine: it means that
    row is catalogue-agnostic (matched by bare code)."""
    cons_df = pd.read_excel(xlsx_path, sheet_name=SHEET_NAMES["constructions"])
    mats_df = pd.read_excel(xlsx_path, sheet_name=SHEET_NAMES["materials"])
    if COLUMN_MAP["code_space"] not in cons_df.columns:
        raise KeyError(f"constructions sheet is missing the required "
                       f"'{COLUMN_MAP['code_space']}' column")
    constructions, construction_codespaces = {}, {}
    for code, grp in cons_df.groupby(COLUMN_MAP["code"]):
        grp = grp.sort_values(COLUMN_MAP["layer_order"])          # 1 = inside (Energy ADE)
        constructions[str(code)] = [str(m) for m in grp[COLUMN_MAP["material_name"]]]
        # which catalogue this code belongs to; blank cell -> None = agnostic
        construction_codespaces[str(code)] = _str(grp[COLUMN_MAP["code_space"]].iloc[0])
    materials = {str(r[COLUMN_MAP["material_name"]]): r.to_dict() for _, r in mats_df.iterrows()}
    return {"constructions": constructions,
            "construction_codespaces": construction_codespaces,
            "materials": materials}


# ===== material builders (one of the 3 E+ objects) ===========================
def _material_from_excel(name, db):
    row = db["materials"].get(name)
    if row is None:
        warn(f"material '{name}' missing from Excel materials sheet; using default")
        return _default_material_copy(name, "material missing from Excel materials sheet")

    mtype = _str(row.get(COLUMN_MAP["material_type"]), "Material")
    raw_excel = {
        "material_type": _trace_value(row.get(COLUMN_MAP["material_type"])),
        "thickness": _trace_value(row.get(COLUMN_MAP["thickness"])),
        "conductivity": _trace_value(row.get(COLUMN_MAP["conductivity"])),
        "density": _trace_value(row.get(COLUMN_MAP["density"])),
        "specific_heat": _trace_value(row.get(COLUMN_MAP["specific_heat"])),
        "roughness": _trace_value(row.get(COLUMN_MAP["roughness"])),
        "thermal_resistance": _trace_value(row.get(COLUMN_MAP["thermal_resistance"])),
        "assumed_units": {"thickness": "m", "conductivity": "W/m-K",
                          "density": "kg/m3", "specific_heat": "J/kg-K",
                          "thermal_resistance": "m2-K/W"},
    }

    if mtype == "Material:AirGap":
        resistance = _num(row.get(COLUMN_MAP["thermal_resistance"]), 0.15)
        return {"name": name, "eplus": "Material:AirGap",
                "thermal_resistance": resistance,
                "source": "excel", "eplus_unit": "m2-K/W",
                "raw_excel": raw_excel,
                "converted": {"thermal_resistance": {"value": resistance, "unit": "m2-K/W"}}}
    if mtype == "Material:NoMass":
        resistance = _num(row.get(COLUMN_MAP["thermal_resistance"]), 0.1)
        return {"name": name, "eplus": "Material:NoMass",
                "roughness": _str(row.get(COLUMN_MAP["roughness"]), DEFAULT_ROUGHNESS),
                "thermal_resistance": resistance,
                "source": "excel", "eplus_unit": "m2-K/W",
                "raw_excel": raw_excel,
                "converted": {"thermal_resistance": {"value": resistance, "unit": "m2-K/W"}}}

    thickness = _num(row.get(COLUMN_MAP["thickness"]), DEFAULT_MATERIAL["thickness"])
    conductivity = _num(row.get(COLUMN_MAP["conductivity"]), DEFAULT_MATERIAL["conductivity"])
    density = _num(row.get(COLUMN_MAP["density"]), DEFAULT_MATERIAL["density"])
    specific_heat = _num(row.get(COLUMN_MAP["specific_heat"]), DEFAULT_MATERIAL["specific_heat"])
    return {"name": name, "eplus": "Material",
            "thickness": thickness,
            "conductivity": conductivity,
            "density": density,
            "specific_heat": specific_heat,
            "roughness": _str(row.get(COLUMN_MAP["roughness"]), DEFAULT_ROUGHNESS),
            "source": "excel",
            "raw_excel": raw_excel,
            "converted": {"thickness": {"value": thickness, "unit": "m"},
                          "conductivity": {"value": conductivity, "unit": "W/m-K"},
                          "density": {"value": density, "unit": "kg/m3"},
                          "specific_heat": {"value": specific_heat, "unit": "J/kg-K"}},
            "eplus_units": {"thickness": "m", "conductivity": "W/m-K",
                            "density": "kg/m3", "specific_heat": "J/kg-K"}}


def _citygml_material_name(mat_el, layer_el=None):
    mat_id = mat_el.get(GML_ID) if mat_el is not None else "citygml_material"
    layer_id = layer_el.get(GML_ID) if layer_el is not None else None
    return f"{layer_id}_{mat_id}" if layer_id else mat_id


def _material_from_citygml(doc, mat_el, thickness, layer_el=None):
    """SolidMaterial -> Material; Gas -> Material:AirGap; incomplete -> NoMass fallback."""
    if mat_el is None:
        return _default_material_copy(_citygml_material_name(mat_el, layer_el), "missing material reference")
    name = _citygml_material_name(mat_el, layer_el)
    if local_name(mat_el) == "Gas":
        resistance, trace = _airgap_resistance_for_energyplus(doc, mat_el, name)
        raw_citygml = {"type": "Gas", "rValue": trace["raw_value"], "rValue_uom": trace["raw_uom"]}
        converted = {"thermal_resistance": {"value": trace["converted_value"],
                                             "unit": trace["eplus_unit"]}}
        if resistance is None:
            material = _default_material_copy(name, trace.get("reason", "gas rValue is not usable"))
            material["raw_citygml"] = raw_citygml
            material["converted"] = converted
            return material
        return {"name": name, "eplus": "Material:AirGap",
                "thermal_resistance": resistance,
                "source": "citygml_gas",
                "raw_citygml": raw_citygml,
                "converted": converted}
    cond_value, cond_uom = _child_measure(doc, mat_el, "nrg", "thermalConductivity")
    dens_value, dens_uom = _child_measure(doc, mat_el, "nrg", "density")
    cond = _conductivity_to_w_per_m_k(cond_value, cond_uom, context=f"material '{name}' thermalConductivity")
    dens = _density_to_kg_per_m3(dens_value, dens_uom, context=f"material '{name}' density")
    cp_value, cp_uom = _child_measure(doc, mat_el, "nrg", "specificHeatCapacity")
    cp = _specific_heat_to_j_per_kg_k(cp_value, cp_uom, context=f"material '{name}' specificHeatCapacity")
    raw_citygml = {"type": "SolidMaterial",
                   "thermalConductivity": cond_value, "thermalConductivity_uom": cond_uom,
                   "density": dens_value, "density_uom": dens_uom,
                   "specificHeatCapacity": cp_value, "specificHeatCapacity_uom": cp_uom,
                   "thickness": thickness}
    converted = {"thickness": {"value": thickness, "unit": "m"},
                 "conductivity": {"value": cond, "unit": "W/m-K"},
                 "density": {"value": dens, "unit": "kg/m3"},
                 "specific_heat": {"value": cp, "unit": "J/kg-K"}}
    if cond and dens and cp and thickness:
        return {"name": name, "eplus": "Material", "thickness": thickness,
                "conductivity": cond, "density": dens, "specific_heat": cp,
                "roughness": DEFAULT_ROUGHNESS,
                "source": "citygml_solid",
                "raw_citygml": raw_citygml,
                "converted": converted,
                "eplus_units": {"thickness": "m", "conductivity": "W/m-K",
                                "density": "kg/m3", "specific_heat": "J/kg-K"}}
    if cond and thickness:                                        # mass data missing
        warn(f"material '{name}': no density/specific-heat; fallback to NoMass")
        resistance = thickness / cond
        return {"name": name, "eplus": "Material:NoMass",
                "roughness": DEFAULT_ROUGHNESS, "thermal_resistance": resistance,
                "source": "citygml_partial_solid",
                "raw_citygml": raw_citygml,
                "converted": {"thermal_resistance": {"value": resistance, "unit": "m2-K/W"}},
                "eplus_unit": "m2-K/W"}
    warn(f"material '{name}': insufficient data; using default")
    material = _default_material_copy(name, "insufficient SolidMaterial data")
    material["raw_citygml"] = raw_citygml
    material["converted"] = converted
    return material


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
    return _construction_code_info(doc, constr_el)["value"]


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


def _with_context(resolved, owner_id):
    out = dict(resolved)
    if owner_id:
        out["source_context_id"] = owner_id
    return out


def _new_trace(surface_record, surf_el, owner_checks):
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
    trace.update({
        "selected_owner": owner_id,
        "selected_construction_id": constr_el.get(GML_ID) if constr_el is not None else None,
        "selected_construction_type": local_name(constr_el) if constr_el is not None else None,
        "libraryCode": code_info.get("value") if code_info else None,
        "libraryCodeSpace": code_info.get("codeSpace") if code_info else None,
        "source": source,
    })
    return trace


# ===== catalogue lookup by (codeSpace, code) =================================
# The identity of a library/DB entry is the PAIR (codeSpace, code), never the bare
# code: two catalogues may reuse the same code string for different things.
def _excel_match(code, code_space, db):
    """True when the Excel/DB should answer for this (codeSpace, code).

    The DB declares each code's codeSpace (the `code_space` column):
      * DB codeSpace blank (None) -> catalogue-agnostic row: match by bare code;
      * file code unqualified (None) -> accept the DB row (best effort);
      * otherwise -> match only when the two codeSpaces are EQUAL.
    This is what stops two catalogues that reuse a code from colliding.
    """
    if not code or code not in db.get("constructions", {}):
        return False
    db_code_space = db.get("construction_codespaces", {}).get(code)
    if db_code_space is None or code_space is None:
        return True
    return code_space == db_code_space


def _element_has_layers(doc, constr_el):
    """True if a LayeredConstruction carries its OWN inline nrg:layer children."""
    return constr_el is not None and bool(doc.children(constr_el, "nrg", "layer"))


def _index_file_library(doc):
    """Index every LayeredConstruction in the file by (codeSpace, code).

    This is the file's OWN catalogue (its LayeredConstructionLibrary members). It
    lets a construction named ONLY by libraryCode — whose layers live in a library
    member we did NOT reach by xlink — still be resolved by its code. Keyed by the
    (codeSpace, code) PAIR so codes are never confused across catalogues; first
    definition of a key wins.
    """
    library = {}
    for constr_el in doc.iter_type("nrg", "LayeredConstruction"):
        code, code_space = _child_code(doc, constr_el, "nrg", "libraryCode")
        if code:
            library.setdefault((code_space, code), constr_el)
    return library


def _library_member_for_code(code, code_space, file_library):
    """The file's own LayeredConstruction with this EXACT (codeSpace, code), or None.
    Exact-pair match only — we never guess across codeSpaces."""
    if not code or not file_library:
        return None
    return file_library.get((code_space, code))


# Resolve ONE surface's construction. ORDER (each step BYPASSES the rest on success):
#   1. EXCEL by (codeSpace, code)            -> the curated DB                  (primary)
#   2. the construction's OWN inline layers  -> most-local explicit statement
#   3. IN-FILE library by (codeSpace, code)  -> layers held in a library member not
#                                               reached by xlink; find it, drill it
#   4. uValue -> Material:NoMass (R = 1/U)   -> averaged fallback (e.g. LoD1)
#   5. DEFAULT construction + warning        -> nothing usable
# Step 0 is implicit: if the surface's layeredConstruction is an xlink, it is already
# followed by property_object, so `constr_el` IS the referenced library member.
def _resolve_surface(doc, surf_el, surface_record, db, materials, file_library):
    """Return (construction_name, resolved_dict, trace) for one surface."""
    # For LoD1 raw solids, surf_el is a gml:Polygon and cannot own Energy ADE
    # layeredConstruction. The valid averaged construction path is via the
    # ThermalZone / Building context passed in context_ids.
    context_ids = surface_record.get("construction_context_ids")
    trace = _new_trace(surface_record, surf_el, _construction_owner_checks(doc, surf_el, context_ids))
    for owner_id, constr_el in _construction_candidates(doc, surf_el, context_ids):
        code_info = _construction_code_info(doc, constr_el)
        code = code_info["value"]
        code_space = code_info["codeSpace"]
        name = _construction_name(doc, constr_el, code)
        reverse = constr_el is not None and local_name(constr_el) == "ReverseLayeredConstruction"

        # (1) EXCEL by (codeSpace, code): if the curated DB knows this code, it wins.
        if _excel_match(code, code_space, db):
            resolved = _with_context(_from_excel(code, db, materials, reverse=reverse), owner_id)
            _select_trace(trace, owner_id, constr_el, code_info, resolved["source"])
            return name, resolved, trace

        # Choose which element actually HOLDS the layers to drill:
        #   (2) the construction's OWN inline layers win (most local); otherwise
        #   (3) if it only NAMED a libraryCode, use the file's library member that
        #       holds the layers (exact codeSpace+code). Reverse constructions are
        #       left to _from_citygml, which follows their baseLayeredConstruction.
        drill_el = constr_el
        if code and not reverse and not _element_has_layers(doc, constr_el):
            member = _library_member_for_code(code, code_space, file_library)
            if member is not None and member is not constr_el and _element_has_layers(doc, member):
                drill_el = member

        # (2)/(3) inline or library-member layers, else (4) uValue -> NoMass.
        resolved = _from_citygml(doc, drill_el, materials)
        if resolved.get("layers"):
            resolved = _with_context(resolved, owner_id)
            _select_trace(trace, owner_id, constr_el, code_info, resolved["source"])
            return name, resolved, trace
        if code:
            warn(f"construction code '{code}' (codeSpace={code_space!r}) not in the Excel/DB, "
                 f"not in the file's library, and the construction has no usable layers or uValue")

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

    materials.setdefault(DEFAULT_MATERIAL["name"], DEFAULT_MATERIAL)  # (5) default
    trace["source"] = "default"
    trace["why_default"] = ("no reachable layeredConstruction matched the Excel/DB by (codeSpace, code), "
                            "the file's own library, inline layers, or uValue")
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
