"""
model/materials.py — build ONE EnergyPlus material object per layer.

A CityGML layer material maps by its SOURCE (never guessed):
  nrg:SolidMaterial -> Material        (full opaque: k, rho, cp, thickness)
  nrg:Gas           -> Material:AirGap  (a thermal resistance)
`Material:NoMass` is NOT built here — it comes only from a uValue-only construction
(R = 1/U; see constructions._from_citygml).

PER-FIELD DEFAULTING (the audit rule): KEEP every value the file provides and default
ONLY the field that is missing — a SolidMaterial missing one number still becomes a real
Material with its other real values, never a whole default. Every field carries a `trace`
line (raw value + uom -> converted value + unit, or `source: default` + why).

Split out of constructions.py; the construction builders that USE these live there.
"""

from __future__ import annotations

from ..citygml.xml_io import GML_ID, local_name, warn
from .citygml_read import _child_measure, _child_text
from .units import (_conductivity_to_w_per_m_k, _density_to_kg_per_m3,
                    _specific_heat_to_j_per_kg_k)

# ===== defaults =====
# PER-FIELD defaults for a SolidMaterial: realistic mid-range values used ONLY for a field
# the file leaves out (tunable here, in one place). Note MIN_SPECIFIC_HEAT (100, in units.py)
# is the E+ validation FLOOR, not a good default value — a MISSING cp defaults to a realistic
# DEFAULT_SPECIFIC_HEAT instead of the floor.
DEFAULT_ROUGHNESS = "MediumRough"
DEFAULT_CONDUCTIVITY = 1.0         # W/m-K
DEFAULT_DENSITY = 1000.0           # kg/m3
DEFAULT_SPECIFIC_HEAT = 900.0      # J/kg-K
DEFAULT_THICKNESS = 0.10           # m
DEFAULT_AIRGAP_RESISTANCE = 0.18   # m2-K/W  (ISO 6946 still-air gap)

DEFAULT_MATERIAL = {"name": "DEFAULT_OPAQUE", "eplus": "Material",
                    "thickness": DEFAULT_THICKNESS, "conductivity": DEFAULT_CONDUCTIVITY,
                    "density": DEFAULT_DENSITY, "specific_heat": DEFAULT_SPECIFIC_HEAT,
                    "roughness": DEFAULT_ROUGHNESS}


# ===== per-field resolution + trace ==========================================
# Each field is resolved ONCE here: read the CityGML value, convert to E+ units, and
# KEEP it — falling back to a default ONLY when the field is absent. The returned trace
# line is the audit record for that one parameter (raw -> converted, or defaulted + why).
def _resolve_field(doc, mat_el, tag, convert, default, unit, mat_name):
    """(value, trace) for one nrg:<tag> measure. Real value kept; default only if absent."""
    raw, uom = _child_measure(doc, mat_el, "nrg", tag)
    if raw is not None:
        value = convert(raw, uom, context=f"material '{mat_name}' {tag}")
        return value, {"raw": raw, "raw_uom": uom or None,
                       "value": value, "unit": unit, "source": "citygml"}
    return default, {"raw": None, "value": default, "unit": unit,
                     "source": "default", "reason": f"{tag} not provided by CityGML"}


def _resolve_specific_heat(doc, mat_el, mat_name):
    """(value, trace) for specificHeatCapacity -> J/(kg-K). units.py auto-converts kJ and
    enforces the E+ floor; a MISSING value defaults to a realistic DEFAULT_SPECIFIC_HEAT."""
    raw, uom = _child_measure(doc, mat_el, "nrg", "specificHeatCapacity")
    if raw is None:
        return DEFAULT_SPECIFIC_HEAT, {"raw": None, "value": DEFAULT_SPECIFIC_HEAT,
                                       "unit": "J/kg-K", "source": "default",
                                       "reason": "specificHeatCapacity not provided by CityGML"}
    value = _specific_heat_to_j_per_kg_k(raw, uom, context=f"material '{mat_name}' specificHeatCapacity")
    return value, {"raw": raw, "raw_uom": uom or None,
                   "value": value, "unit": "J/kg-K", "source": "citygml"}


def _resolve_thickness(thickness, raw=None, raw_uom=None):
    """(value, trace) for layer thickness.

    `thickness` is the EnergyPlus-ready value in metres. `raw`/`raw_uom` preserve
    the original CityGML measure so the trace can explain unit conversion.
    """
    if thickness:
        trace = {"raw": raw, "raw_uom": raw_uom or None,
                 "value": thickness, "unit": "m",
                 "source": "citygml_layer", "conversion": "length_to_meters"}
        return thickness, trace
    return DEFAULT_THICKNESS, {"raw": raw, "raw_uom": raw_uom or None,
                               "value": DEFAULT_THICKNESS, "unit": "m",
                               "source": "default",
                               "reason": "layer thickness not provided"}


def _default_material_copy(name, reason):
    """A named copy of DEFAULT_MATERIAL, tagged with why the fallback fired."""
    material = dict(DEFAULT_MATERIAL, name=name)
    material["source"] = "default"
    material["fallback_reason"] = reason
    return material


# ===== material builders (one of the 3 E+ objects) ===========================
def _citygml_material_name(mat_el, layer_el=None):
    """Stable material name from the layer + material gml:id (layer disambiguates)."""
    mat_id = mat_el.get(GML_ID) if mat_el is not None else "citygml_material"
    layer_id = layer_el.get(GML_ID) if layer_el is not None else None
    return f"{layer_id}_{mat_id}" if layer_id else mat_id


def _solid_material(doc, mat_el, name, thickness, thickness_raw=None, thickness_uom=None):
    """CityGML nrg:SolidMaterial -> a full E+ Material. Every provided value is KEPT; only
    a MISSING field is defaulted (per-field), and every field carries its own trace line."""
    cond, cond_tr = _resolve_field(doc, mat_el, "thermalConductivity",
                                   _conductivity_to_w_per_m_k, DEFAULT_CONDUCTIVITY, "W/m-K", name)
    dens, dens_tr = _resolve_field(doc, mat_el, "density",
                                   _density_to_kg_per_m3, DEFAULT_DENSITY, "kg/m3", name)
    cp, cp_tr = _resolve_specific_heat(doc, mat_el, name)
    thick, thick_tr = _resolve_thickness(thickness, thickness_raw, thickness_uom)
    return {"name": name, "eplus": "Material",
            "thickness": thick, "conductivity": cond, "density": dens, "specific_heat": cp,
            "roughness": DEFAULT_ROUGHNESS,
            "source": "citygml_solid",
            "trace": {"thermalConductivity": cond_tr, "density": dens_tr,
                      "specificHeatCapacity": cp_tr, "thickness": thick_tr}}


def _airgap_material(doc, mat_el, name, thickness, thickness_raw=None, thickness_uom=None):
    """CityGML nrg:Gas -> E+ Material:AirGap. The real nrg:rValue (thermal resistance,
    m2-K/W) is kept; it defaults to 0.18 (ISO 6946 still-air gap) when missing/unusable.
    gas_type (nrg:type) is recorded for the trace only (E+ AirGap has no gas field)."""
    raw, uom = _child_measure(doc, mat_el, "nrg", "rValue")
    gas_type = _child_text(doc, mat_el, "nrg", "type") or "Air"
    unit = (uom or "").lower().replace(" ", "")
    if raw is not None and ("m2" in unit or "m^2" in unit) and "k" in unit and "w" in unit:
        r_value = raw
        r_tr = {"raw": raw, "raw_uom": uom, "value": raw, "unit": "m2-K/W", "source": "citygml"}
    else:
        reason = f"rValue unit '{uom}' not m2-K/W" if raw is not None else "rValue not provided by CityGML"
        warn(f"gas material '{name}': {reason}; using ISO 6946 default {DEFAULT_AIRGAP_RESISTANCE}")
        r_value = DEFAULT_AIRGAP_RESISTANCE
        r_tr = {"raw": raw, "raw_uom": uom or None, "value": DEFAULT_AIRGAP_RESISTANCE,
                "unit": "m2-K/W", "source": "default", "reason": reason}
    return {"name": name, "eplus": "Material:AirGap", "thermal_resistance": r_value,
            "source": "citygml_gas", "gas_type": gas_type,
            "trace": {"rValue": r_tr, "gas_type": gas_type,
                      "thickness": _resolve_thickness(thickness, thickness_raw, thickness_uom)[1]}}


def _material_from_citygml(doc, mat_el, thickness, layer_el=None, thickness_raw=None, thickness_uom=None):
    """One E+ material from a CityGML layer's material:
      nrg:Gas           -> Material:AirGap   (real rValue, else 0.18)
      nrg:SolidMaterial -> Material          (per-field: real values kept, missing defaulted)
    (`Material:NoMass` is produced elsewhere — only from a uValue-only construction.)"""
    name = _citygml_material_name(mat_el, layer_el)
    if mat_el is None:
        return _default_material_copy(name, "no material referenced by the layer")
    if local_name(mat_el) == "Gas":
        return _airgap_material(doc, mat_el, name, thickness, thickness_raw, thickness_uom)
    return _solid_material(doc, mat_el, name, thickness, thickness_raw, thickness_uom)
