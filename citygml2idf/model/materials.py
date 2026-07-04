"""
model/materials.py — build ONE EnergyPlus material object per layer.

Every layer becomes exactly one of the 3 EnergyPlus material objects, chosen by
the SOURCE (never guessed): `Material` (full opaque), `Material:NoMass` (R only),
`Material:AirGap` (gas). Builders here read either a CityGML material element or an
Excel materials-sheet row, convert units (via units.py), and never emit a material
missing a required field (fall back to DEFAULT_MATERIAL + a warning).

Split out of constructions.py; the construction builders that USE these live there.
"""

from __future__ import annotations

from ..citygml.xml_io import GML_ID, local_name, warn
from .catalogue import COLUMN_MAP
from .citygml_read import _child_measure
from .units import (MIN_SPECIFIC_HEAT, _conductivity_to_w_per_m_k,
                    _density_to_kg_per_m3, _num, _specific_heat_to_j_per_kg_k,
                    _str, _trace_value)

# ===== defaults (RULES M2): never emit a material missing a required field ====
DEFAULT_ROUGHNESS = "MediumRough"
DEFAULT_MATERIAL = {"name": "DEFAULT_OPAQUE", "eplus": "Material", "thickness": 0.20,
                    "conductivity": 1.0, "density": 1800.0,
                    # EnergyPlus minimum for Material.Specific Heat is 100 J/kg-K.
                    "specific_heat": MIN_SPECIFIC_HEAT,
                    "roughness": DEFAULT_ROUGHNESS}


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
    """A named copy of DEFAULT_MATERIAL, tagged with why the fallback fired."""
    material = dict(DEFAULT_MATERIAL, name=name)
    material["source"] = "default"
    material["fallback_reason"] = reason
    return material


# ===== material builders (one of the 3 E+ objects) ===========================
def _material_from_excel(name, db):
    """Build an E+ material from the Excel materials-sheet row named `name`."""
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
    """Stable material name from the layer + material gml:id (layer disambiguates)."""
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
