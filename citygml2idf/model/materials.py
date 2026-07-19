"""
model/materials.py — build ONE EnergyPlus material object per layer.

A CityGML layer material maps by its SOURCE (never guessed):
  nrg:SolidMaterial -> Material        (full opaque: k, rho, cp, thickness)
  nrg:Gas           -> Material:AirGap  (a thermal resistance)
`Material:NoMass` is NOT built here — it comes only from a uValue-only construction
(R = 1/U; see constructions._from_citygml).

PER-FIELD DEFAULTING (the audit rule): resolve every field ON ITS OWN. A SolidMaterial with one
bad number still becomes a REAL Material with its other real values — never a whole default.

A field falls back to its default for exactly THREE reasons, and only these:
  1. ABSENT        — the CityGML simply does not state it;
  2. UNKNOWN uom   — units.py could not convert it and returned None. We never guess that an
                     unrecognised unit "was probably already in E+ units" (that is how a BTU
                     silently becomes a wrong-by-a-factor building);
  3. E+ WOULD REJECT IT — the value breaks the IDD minimum of the field it feeds
                     (`Material` N1 Thickness / N2 Conductivity / N3 Density all `\\minimum> 0`,
                     N4 Specific Heat `\\minimum 100`; `Material:AirGap` N1 R `\\minimum> 0`).
                     Writing it anyway would only earn a Severe, so it is a DATA ERROR.
Cases 2 and 3 always WARN and name the field. Every field records a flat `provenance` line
(what we did: raw -> converted, or defaulted + why).

Split out of constructions.py; the construction builders that USE these live there.
"""

from __future__ import annotations

from ..citygml.xml_io import GML_ID, local_name, warn
from .citygml_read import _child_measure, _child_text
from .model import Material
from .units import MIN_SPECIFIC_HEAT, to_reference

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

DEFAULT_MATERIAL = Material(name="DEFAULT_OPAQUE", eplus="Material",
                            thickness=DEFAULT_THICKNESS, conductivity=DEFAULT_CONDUCTIVITY,
                            density=DEFAULT_DENSITY, specific_heat=DEFAULT_SPECIFIC_HEAT,
                            roughness=DEFAULT_ROUGHNESS,
                            provenance={"all": "project default (no CityGML material)"})


# ===== per-field resolution + provenance =====================================
# Each field is resolved ONCE here: read the CityGML value, convert it to the E+ unit, and KEEP
# it — falling back to the default only for the three reasons listed in the module docstring
# (absent / unknown uom / a value EnergyPlus would reject). The returned provenance line is the
# audit record for that one parameter (raw -> converted, or why defaulted), as ONE readable string.
def _measure_note(raw, uom, value, unit):
    """"citygml <raw> <uom> -> <value> <unit>" (uom omitted when absent)."""
    return f"citygml {raw}{(' ' + uom) if uom else ''} -> {value} {unit}"


def _resolve_field(doc, mat_el, tag, default, unit, mat_name):
    """(value, provenance) for one nrg:<tag> measure. Real value KEPT; DEFAULT when unusable.

    "Unusable" is ONE idea with three causes, all ending in the same place — the default:
      * the field is ABSENT;
      * its `uom` is not one we accept, so `to_reference` returned None (we never guess a unit);
      * it is <= 0, which EnergyPlus REJECTS (IDD `Material`: N1 Thickness, N2 Conductivity and
        N3 Density are all `\\minimum> 0`) — writing it would just earn a Severe.

    `tag` IS the unit-table field name, so units.py needs no converter passed in.
    """
    raw, uom = _child_measure(doc, mat_el, "nrg", tag)
    if raw is None:
        return default, f"default {default} {unit} ({tag} not in CityGML)"
    value = to_reference(tag, raw, uom, context=f"material '{mat_name}' {tag}")  # None = bad unit
    if value is None:
        return default, f"default {default} {unit} ({tag} unit '{uom}' not recognised)"
    if value <= 0:
        warn(f"material '{mat_name}' {tag}: {value} {unit} is not allowed - EnergyPlus requires > 0; "
             f"using default {default}")
        return default, f"default {default} {unit} (citygml {raw}{(' ' + uom) if uom else ''} is <= 0)"
    return value, _measure_note(raw, uom, value, unit)


def _resolve_specific_heat(doc, mat_el, mat_name):
    """(value, provenance) for specificHeatCapacity -> J/(kg-K). units.py converts kJ/(kg-K) and
    J/(g-K); ABSENT or unknown-unit -> DEFAULT_SPECIFIC_HEAT.

    Note the E+ floor here is 100, NOT 0 (IDD `Material` N4 Specific Heat: `\\minimum 100`), and
    100 is a VALIDATION FLOOR, not a sensible material value — so a cp below it falls back to the
    realistic DEFAULT_SPECIFIC_HEAT rather than being clamped to 100."""
    raw, uom = _child_measure(doc, mat_el, "nrg", "specificHeatCapacity")
    if raw is None:
        return DEFAULT_SPECIFIC_HEAT, (f"default {DEFAULT_SPECIFIC_HEAT} J/kg-K "
                                       f"(specificHeatCapacity not in CityGML)")
    value = to_reference("specificHeatCapacity", raw, uom,
                         context=f"material '{mat_name}' specificHeatCapacity")
    if value is None:
        return DEFAULT_SPECIFIC_HEAT, (f"default {DEFAULT_SPECIFIC_HEAT} J/kg-K "
                                       f"(specificHeatCapacity unit '{uom}' not recognised)")
    if value < MIN_SPECIFIC_HEAT:
        warn(f"material '{mat_name}' specificHeatCapacity: {value} J/kg-K is below the "
             f"EnergyPlus minimum ({MIN_SPECIFIC_HEAT}); using default {DEFAULT_SPECIFIC_HEAT}")
        return DEFAULT_SPECIFIC_HEAT, (f"default {DEFAULT_SPECIFIC_HEAT} J/kg-K "
                                       f"(citygml {raw} -> {value} is below the E+ minimum "
                                       f"{MIN_SPECIFIC_HEAT})")
    return value, _measure_note(raw, uom, value, "J/kg-K")


def _resolve_thickness(thickness, raw=None, raw_uom=None, mat_name="material"):
    """(value, provenance) for layer thickness. Same rule as _resolve_field: absent, unknown
    unit (converter returned None), or <= 0 -> the default. EnergyPlus requires Thickness > 0
    (IDD `Material` N1), and a stated 0 must WARN, not default in silence."""
    if thickness is None:                       # absent, or its uom was not recognised
        return DEFAULT_THICKNESS, f"default {DEFAULT_THICKNESS} m (thickness missing/unusable)"
    if thickness <= 0:
        warn(f"layer of '{mat_name}': thickness {thickness} m is not allowed - EnergyPlus requires > 0; "
             f"using default {DEFAULT_THICKNESS}")
        return DEFAULT_THICKNESS, (f"default {DEFAULT_THICKNESS} m "
                                   f"(citygml {raw}{(' ' + raw_uom) if raw_uom else ''} is <= 0)")
    return thickness, _measure_note(raw, raw_uom, thickness, "m")


def _default_material_copy(name, reason):
    """A named copy of DEFAULT_MATERIAL, tagged with why the fallback fired."""
    return Material(name=name, eplus="Material",
                    thickness=DEFAULT_THICKNESS, conductivity=DEFAULT_CONDUCTIVITY,
                    density=DEFAULT_DENSITY, specific_heat=DEFAULT_SPECIFIC_HEAT,
                    roughness=DEFAULT_ROUGHNESS,
                    provenance={"all": f"project default ({reason})"})


# ===== material builders (one of the 3 E+ objects) ===========================
def _citygml_material_name(mat_el, layer_el=None):
    """Stable material name from the layer + material gml:id (layer disambiguates)."""
    mat_id = mat_el.get(GML_ID) if mat_el is not None else "citygml_material"
    layer_id = layer_el.get(GML_ID) if layer_el is not None else None
    return f"{layer_id}_{mat_id}" if layer_id else mat_id


def _solid_material(doc, mat_el, name, thickness, thickness_raw=None, thickness_uom=None):
    """CityGML nrg:SolidMaterial -> a full E+ Material. Every provided value is KEPT; a MISSING
    field is defaulted (per-field); a field that is PRESENT but breaks the IDD minimum is
    warned + defaulted. Every field carries its own trace line.
    IDD `Material`: N1 Thickness > 0, N2 Conductivity > 0, N3 Density > 0, N4 Specific Heat >= 100."""
    cond, cond_tr = _resolve_field(doc, mat_el, "thermalConductivity",
                                   DEFAULT_CONDUCTIVITY, "W/m-K", name)
    dens, dens_tr = _resolve_field(doc, mat_el, "density",
                                   DEFAULT_DENSITY, "kg/m3", name)
    cp, cp_tr = _resolve_specific_heat(doc, mat_el, name)
    thick, thick_tr = _resolve_thickness(thickness, thickness_raw, thickness_uom, name)
    return Material(
        name=name, eplus="Material",
        thickness=thick, conductivity=cond, density=dens, specific_heat=cp,
        roughness=DEFAULT_ROUGHNESS,
        provenance={"conductivity": cond_tr, "density": dens_tr,
                    "specific_heat": cp_tr, "thickness": thick_tr})


def _airgap_material(doc, mat_el, name, thickness, thickness_raw=None, thickness_uom=None):
    """CityGML nrg:Gas -> E+ Material:AirGap. The real nrg:rValue (thermal resistance,
    m2-K/W) is kept; it defaults to 0.18 (ISO 6946 still-air gap) when missing/unusable.
    gas_type (nrg:type) is recorded for the trace only (E+ AirGap has no gas field)."""
    raw, uom = _child_measure(doc, mat_el, "nrg", "rValue")
    gas_type = _child_text(doc, mat_el, "nrg", "type") or "Air"
    # SAME RULE AS EVERY OTHER MEASURE: units.py converts it, or returns None when it cannot,
    # and the default fires for absent / unknown-unit / <= 0 (IDD Material:AirGap N1: `minimum> 0`).
    r_value = to_reference("rValue", raw, uom, context=f"gas material '{name}' rValue")
    if r_value is not None and r_value > 0:
        r_note = _measure_note(raw, uom, r_value, "m2-K/W")
    elif r_value is None and raw is not None:
        # the converter ALREADY warned about the unrecognised unit — do not say it twice
        r_note = (f"default {DEFAULT_AIRGAP_RESISTANCE} m2-K/W "
                  f"(rValue unit '{uom}' is not m2-K/W)")
        r_value = DEFAULT_AIRGAP_RESISTANCE
    else:
        reason = ("rValue not provided by CityGML" if raw is None
                  else f"rValue {raw} is <= 0 (EnergyPlus requires > 0)")
        warn(f"gas material '{name}': {reason}; using ISO 6946 default {DEFAULT_AIRGAP_RESISTANCE}")
        r_value = DEFAULT_AIRGAP_RESISTANCE
        r_note = f"default {DEFAULT_AIRGAP_RESISTANCE} m2-K/W ({reason})"
    return Material(name=name, eplus="Material:AirGap", thermal_resistance=r_value,
                    provenance={"thermal_resistance": r_note, "gas_type": gas_type})


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
