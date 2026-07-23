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
from .model import ABSENT, INVALID, OK, Material, trace
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


# this is a last resort which we dont have anything for material layers
DEFAULT_MATERIAL = Material(name="DEFAULT_OPAQUE", eplus="Material",
                            thickness=DEFAULT_THICKNESS, conductivity=DEFAULT_CONDUCTIVITY,
                            density=DEFAULT_DENSITY, specific_heat=DEFAULT_SPECIFIC_HEAT,
                            roughness=DEFAULT_ROUGHNESS,
                            provenance={"all": trace(ABSENT, "project default (no CityGML material)")})


# ===== per-field resolution + provenance =====================================
# The status vocabulary (ok / absent / invalid) + trace() live in model.py, shared by every
# builder. See that module's header for what each status means.
def _measure_note(raw, uom, value, unit):
    """The `ok` entry: "citygml <raw> <uom> -> <value> <unit>" (uom omitted when absent)."""
    return trace(OK, f"citygml {raw}{(' ' + uom) if uom else ''} -> {value} {unit}")


def _resolve_field(doc, mat_el, tag, default, unit, mat_name):
    """(value, trace) for one nrg:<tag> measure. Real value KEPT; DEFAULT when unusable.

    Reading `raw` FIRST is what makes the status unambiguous: once we know the element was
    there, a None back from `to_reference` can only mean "we could not interpret it".
    IDD `Material`: N1 Thickness, N2 Conductivity, N3 Density are all `\\minimum> 0`.

    `tag` IS the unit-table field name, so units.py needs no converter passed in.
    """
    raw, uom = _child_measure(doc, mat_el, "nrg", tag)
    if raw is None:
        return default, trace(ABSENT, f"{tag} not in CityGML -> default {default} {unit}")
    value = to_reference(tag, raw, uom, context=f"material '{mat_name}' {tag}")  # None = bad unit
    if value is None:
        return default, trace(INVALID, f"citygml {tag} {raw} '{uom}' unit not accepted "
                                        f"-> default {default} {unit}")
    if value <= 0:
        warn(f"material '{mat_name}' {tag}: {value} {unit} is not allowed - EnergyPlus requires > 0; "
             f"using default {default}")
        return default, trace(INVALID, f"citygml {tag} {raw}{(' ' + uom) if uom else ''} -> {value} "
                                        f"is <= 0 -> default {default} {unit}")
    return value, _measure_note(raw, uom, value, unit)


def _resolve_specific_heat(doc, mat_el, mat_name):
    """(value, provenance) for specificHeatCapacity -> J/(kg-K). units.py converts kJ/(kg-K) and
    J/(g-K); ABSENT or unknown-unit -> DEFAULT_SPECIFIC_HEAT.

    Note the E+ floor here is 100, NOT 0 (IDD `Material` N4 Specific Heat: `\\minimum 100`), and
    100 is a VALIDATION FLOOR, not a sensible material value — so a cp below it falls back to the
    realistic DEFAULT_SPECIFIC_HEAT rather than being clamped to 100."""
    raw, uom = _child_measure(doc, mat_el, "nrg", "specificHeatCapacity")
    if raw is None:
        return DEFAULT_SPECIFIC_HEAT, trace(
            ABSENT, f"specificHeatCapacity not in CityGML -> default {DEFAULT_SPECIFIC_HEAT} J/kg-K")
    value = to_reference("specificHeatCapacity", raw, uom,
                         context=f"material '{mat_name}' specificHeatCapacity")
    if value is None:
        return DEFAULT_SPECIFIC_HEAT, trace(
            INVALID, f"citygml specificHeatCapacity {raw} '{uom}' unit not accepted "
                     f"-> default {DEFAULT_SPECIFIC_HEAT} J/kg-K")
    if value < MIN_SPECIFIC_HEAT:
        warn(f"material '{mat_name}' specificHeatCapacity: {value} J/kg-K is below the "
             f"EnergyPlus minimum ({MIN_SPECIFIC_HEAT}); using default {DEFAULT_SPECIFIC_HEAT}")
        return DEFAULT_SPECIFIC_HEAT, trace(
            INVALID, f"citygml specificHeatCapacity {raw} -> {value} is below the E+ minimum "
                     f"{MIN_SPECIFIC_HEAT} -> default {DEFAULT_SPECIFIC_HEAT} J/kg-K")
    return value, _measure_note(raw, uom, value, "J/kg-K")


def _resolve_thickness(thickness, raw=None, raw_uom=None, mat_name="material"):
    """(value, trace) for layer thickness — same three outcomes as _resolve_field.

    Thickness is read on the LAYER (not the material), so it arrives already converted. `raw`
    is what distinguishes the two ways `thickness` can be None: absent (the layer never stated
    it) vs invalid (it stated one we could not read). Without `raw` those collapse into one
    message, which is what used to hide a lost value.
    EnergyPlus requires Thickness > 0 (IDD `Material` N1)."""
    if thickness is None:
        if raw is None:
            return DEFAULT_THICKNESS, trace(
                ABSENT, f"thickness not in CityGML -> default {DEFAULT_THICKNESS} m")
        return DEFAULT_THICKNESS, trace(
            INVALID, f"citygml thickness {raw} '{raw_uom}' unit not accepted "
                     f"-> default {DEFAULT_THICKNESS} m")
    if thickness <= 0:
        warn(f"layer of '{mat_name}': thickness {thickness} m is not allowed - EnergyPlus requires > 0; "
             f"using default {DEFAULT_THICKNESS}")
        return DEFAULT_THICKNESS, trace(
            INVALID, f"citygml thickness {raw}{(' ' + raw_uom) if raw_uom else ''} -> {thickness} "
                     f"is <= 0 -> default {DEFAULT_THICKNESS} m")
    return thickness, _measure_note(raw, raw_uom, thickness, "m")

# this is default for layers like we have 3 layers but two got real data for the last one we use this (differnt from DEFAULT all at top)
def _default_material_copy(name, reason):
    """A named copy of DEFAULT_MATERIAL, tagged with why the fallback fired."""
    return Material(name=name, eplus="Material",
                    thickness=DEFAULT_THICKNESS, conductivity=DEFAULT_CONDUCTIVITY,
                    density=DEFAULT_DENSITY, specific_heat=DEFAULT_SPECIFIC_HEAT,
                    roughness=DEFAULT_ROUGHNESS,
                    provenance={"all": trace(ABSENT, f"project default material ({reason})")})


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
    """CityGML nrg:Gas -> E+ Material:AirGap. The real nrg:rValue (m2-K/W) is kept.

    The XSD gives GasType exactly two own elements: `isVentilated` (boolean, `default="false"`)
    and `rValue` (MeasureType) — plus `libraryCode`, which we deliberately do not read. There is
    NO `nrg3:type` on a Gas, so the old `gas_type` (which always came out "Air" because the
    lookup never matched anything) is gone: it recorded a constant dressed up as file data.

    isVentilated MATTERS: DEFAULT_AIRGAP_RESISTANCE is an UNVENTILATED-cavity figure, so it
    cannot stand in for a ventilated gap — a ventilated cavity is a different calculation
    entirely, and a boolean cannot say how ventilated. Because the XSD declares
    `default="false"`, an ABSENT isVentilated legitimately means "not ventilated": that is the
    schema speaking, not us guessing.

    The three `thickness*` arguments are accepted but DELIBERATELY UNUSED — they only keep this
    builder interchangeable with `_solid_material` so `_material_from_citygml` can dispatch to
    either. IDD `Material:AirGap` has exactly TWO fields, A1 Name and N1 Thermal Resistance
    (`\\minimum> 0`): no Thickness and no Roughness, because a gap's geometry is already baked
    into its R-value. (Thickness is N1 of the FULL `Material` only; `Material:NoMass` has no
    thickness either, just A2 Roughness + N1 Thermal Resistance.)"""
    raw, uom = _child_measure(doc, mat_el, "nrg", "rValue")
    ventilated = (_child_text(doc, mat_el, "nrg", "isVentilated") or "false").lower() == "true"
    r_value = to_reference("rValue", raw, uom, context=f"gas material '{name}' rValue")

    if r_value is not None and r_value > 0:                 # the file gave a usable R — trust it
        resistance_trace = _measure_note(raw, uom, r_value, "m2-K/W")
    elif raw is not None:                                   # stated, but we cannot use it
        why = (f"unit '{uom}' not accepted" if r_value is None
               else f"-> {r_value} is <= 0 (IDD Material:AirGap N1 requires > 0)")
        warn(f"gas material '{name}': rValue {raw} {why}; "
             f"using default {DEFAULT_AIRGAP_RESISTANCE} m2-K/W")
        r_value = DEFAULT_AIRGAP_RESISTANCE
        resistance_trace = trace(INVALID, f"citygml rValue {raw} {why} "
                                          f"-> default {DEFAULT_AIRGAP_RESISTANCE} m2-K/W")
    elif ventilated:                                        # absent, and the default cannot apply
        warn(f"gas material '{name}': no rValue and nrg3:isVentilated=true — "
             f"{DEFAULT_AIRGAP_RESISTANCE} m2-K/W is an UNVENTILATED-cavity value and does not "
             f"describe a ventilated gap; using it anyway for lack of any stated resistance")
        r_value = DEFAULT_AIRGAP_RESISTANCE
        resistance_trace = trace(INVALID, f"no rValue and isVentilated=true; the unventilated "
                                          f"default {DEFAULT_AIRGAP_RESISTANCE} m2-K/W does not "
                                          f"apply to a ventilated cavity")
    else:                                                   # absent, unventilated -> the default fits
        r_value = DEFAULT_AIRGAP_RESISTANCE
        resistance_trace = trace(ABSENT, f"rValue not in CityGML; isVentilated=false -> "
                                         f"unventilated default {DEFAULT_AIRGAP_RESISTANCE} m2-K/W")
    return Material(name=name, eplus="Material:AirGap", thermal_resistance=r_value,
                    provenance={"thermal_resistance": resistance_trace})


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
