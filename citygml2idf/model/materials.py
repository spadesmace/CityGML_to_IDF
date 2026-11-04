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
  2. UNKNOWN uom   — units.py returned None (an unknown unit is never guessed);
  3. E+ WOULD REJECT IT — the value breaks the IDD minimum of the field it feeds
                     (`Material` N1 Thickness / N2 Conductivity / N3 Density all `\\minimum> 0`,
                     N4 Specific Heat `\\minimum 100`; `Material:AirGap` N1 R `\\minimum> 0`).
                     Writing it anyway would only earn a Severe, so it is a DATA ERROR.
Cases 2 and 3 always WARN and name the field. Every field records a flat `provenance` line
(what we did: raw -> converted, or defaulted + why).
"""

from __future__ import annotations

from ..citygml.xml_io import GML_ID, local_name, warn
from ..citygml.citygml_read import child_bool, child_measure
from .model import ABSENT, INVALID, OK, Material, trace
from .units import to_reference

# Energy+.idd `Material` N4 Specific Heat: `\minimum 100` (J/kg-K).
MIN_SPECIFIC_HEAT = 100.0

# ===== defaults =====
# PER-FIELD defaults for a SolidMaterial: realistic mid-range values used ONLY for a field
# the file leaves out (tunable here, in one place). Note MIN_SPECIFIC_HEAT (100, above)
# is the E+ validation FLOOR, not a good default value — a MISSING cp defaults to a realistic
# DEFAULT_SPECIFIC_HEAT instead of the floor.
DEFAULT_ROUGHNESS = "MediumRough"
DEFAULT_CONDUCTIVITY = 1.0         # W/m-K
DEFAULT_DENSITY = 1000.0           # kg/m3
DEFAULT_SPECIFIC_HEAT = 900.0      # J/kg-K
DEFAULT_THICKNESS = 0.10           # m
DEFAULT_AIRGAP_RESISTANCE = 0.18   # m2-K/W  (ISO 6946 still-air gap)


def _default_material(name, note):
    """The project default opaque Material (every field a default), named and tagged."""
    return Material(name=name, eplus="Material",
                    thickness=DEFAULT_THICKNESS, conductivity=DEFAULT_CONDUCTIVITY,
                    density=DEFAULT_DENSITY, specific_heat=DEFAULT_SPECIFIC_HEAT,
                    roughness=DEFAULT_ROUGHNESS,
                    provenance={"all": trace(ABSENT, note)})


# this is a last resort which we don't have anything for material layers
DEFAULT_MATERIAL = _default_material("DEFAULT_OPAQUE", "project default (no CityGML material)")


# ===== per-field resolution + provenance =====================================
# The status vocabulary (ok / absent / invalid) + trace() live in model.py, shared by every
# builder. See that module's header for what each status means.
def _measure_note(raw, uom, value, unit):
    """The `ok` entry: "citygml <raw> <uom> -> <value> <unit>" (uom omitted when absent)."""
    return trace(OK, f"citygml {raw}{(' ' + uom) if uom else ''} -> {value} {unit}")


def _resolve_field(doc, element, tag, default, unit, mat_name, minimum=0.0, inclusive=False):
    """(value, trace) for one nrg:<tag> measure: the file's value, or the default when unusable.

    Parameters
    ----------
    doc : xml_io.CityGMLDoc
        The parsed CityGML file.
    element : lxml element
        The element that carries the measure: the material (k, rho, cp) or the Layer (thickness).
    tag : str
        The nrg: element name, also the units.py FIELDS key.
    default : float
        Used when the value is absent, in a unit we do not accept, or below the minimum.
    unit : str
        The E+ unit, for the notes.
    mat_name : str
        Names the material in the warning.
    minimum : float
        The IDD minimum of the E+ field.
    inclusive : bool
        True = the minimum itself is allowed (IDD `\\minimum`); False = it is not (`\\minimum>`).

    Returns
    -------
    (float, dict)
        The value and its provenance trace (ok / absent / invalid).

    Notes
    -----
    IDD `Material`: N1 Thickness, N2 Conductivity, N3 Density `\\minimum> 0`; N4 Specific Heat
    `\\minimum 100`. A value below the minimum is a DATA ERROR: warned and defaulted, never
    clamped. Reading `raw` first makes the status unambiguous: once the element is there, a None
    from `to_reference` can only mean "unit not accepted".
    """
    raw, uom = child_measure(doc, element, "nrg", tag)
    if raw is None:
        return default, trace(ABSENT, f"{tag} not in CityGML -> default {default} {unit}")
    value = to_reference(tag, raw, uom, context=f"material '{mat_name}' {tag}")  # None = bad unit
    if value is None:
        return default, trace(INVALID, f"citygml {tag} {raw} '{uom}' unit not accepted "
                                        f"-> default {default} {unit}")
    if inclusive:
        too_low = value < minimum
        rule = f">= {minimum:g}"
    else:
        too_low = value <= minimum
        rule = f"> {minimum:g}"
    if too_low:
        warn(f"material '{mat_name}' {tag}: {value} {unit} breaks the EnergyPlus minimum ({rule}); "
             f"using default {default}")
        return default, trace(INVALID, f"citygml {tag} {raw}{(' ' + uom) if uom else ''} -> {value} "
                                        f"breaks the E+ minimum ({rule}) -> default {default} {unit}")
    return value, _measure_note(raw, uom, value, unit)

# this is default for layers like we have 3 layers but two got real data for the last one we use this (different from DEFAULT all at top)
def _default_material_copy(name, reason):
    """A named copy of DEFAULT_MATERIAL, tagged with why the fallback fired."""
    return _default_material(name, f"project default material ({reason})")


# ===== material builders (one of the 3 E+ objects) ===========================
def _citygml_material_name(mat_el, layer_el=None):
    """Stable material name from the layer + material gml:id (layer disambiguates)."""
    mat_id = mat_el.get(GML_ID) if mat_el is not None else "citygml_material"
    layer_id = layer_el.get(GML_ID) if layer_el is not None else None
    return f"{layer_id}_{mat_id}" if layer_id else mat_id


def _solid_material(doc, mat_el, layer_el, name):
    """CityGML nrg:SolidMaterial -> a full E+ Material. Every provided value is KEPT; a MISSING
    field is defaulted (per-field); a field that is PRESENT but breaks the IDD minimum is
    warned + defaulted. Every field carries its own trace line. Thickness is read on the Layer
    (XSD LayerType: thickness), the other three on the material.
    IDD `Material`: N1 Thickness > 0, N2 Conductivity > 0, N3 Density > 0, N4 Specific Heat >= 100."""
    cond, cond_tr = _resolve_field(doc, mat_el, "thermalConductivity",
                                   DEFAULT_CONDUCTIVITY, "W/m-K", name)
    dens, dens_tr = _resolve_field(doc, mat_el, "density",
                                   DEFAULT_DENSITY, "kg/m3", name)
    cp, cp_tr = _resolve_field(doc, mat_el, "specificHeatCapacity",
                               DEFAULT_SPECIFIC_HEAT, "J/kg-K", name,
                               minimum=MIN_SPECIFIC_HEAT, inclusive=True)
    thick, thick_tr = _resolve_field(doc, layer_el, "thickness",
                                     DEFAULT_THICKNESS, "m", name)
    return Material(
        name=name, eplus="Material",
        thickness=thick, conductivity=cond, density=dens, specific_heat=cp,
        roughness=DEFAULT_ROUGHNESS,
        provenance={"conductivity": cond_tr, "density": dens_tr,
                    "specific_heat": cp_tr, "thickness": thick_tr})


def _airgap_material(doc, mat_el, name):
    """CityGML nrg:Gas -> E+ Material:AirGap. The real nrg:rValue (m2-K/W) is kept.

    The XSD gives GasType exactly two own elements: `isVentilated` (boolean, `default="false"`)
    and `rValue` (MeasureType) — plus `libraryCode`, which we deliberately do not read.

    isVentilated MATTERS: DEFAULT_AIRGAP_RESISTANCE is an UNVENTILATED-cavity figure, so it
    cannot stand in for a ventilated gap — a ventilated cavity is a different calculation
    entirely, and a boolean cannot say how ventilated. Because the XSD declares
    `default="false"`, an ABSENT isVentilated legitimately means "not ventilated": that is the
    schema speaking, not us guessing.

    IDD `Material:AirGap` has exactly TWO fields, A1 Name and N1 Thermal Resistance
    (`\\minimum> 0`): no Thickness and no Roughness, because a gap's geometry is already baked
    into its R-value."""
    raw, uom = child_measure(doc, mat_el, "nrg", "rValue")
    ventilated = child_bool(doc, mat_el, "nrg", "isVentilated", default=False)
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


def _material_from_citygml(doc, mat_el, layer_el):
    """One E+ material from a CityGML Layer and its material:
      nrg:Gas           -> Material:AirGap   (real rValue, else 0.18)
      nrg:SolidMaterial -> Material          (per-field: real values kept, missing defaulted)
    (`Material:NoMass` is produced elsewhere — only from a uValue-only construction.)"""
    name = _citygml_material_name(mat_el, layer_el)
    if mat_el is None:
        return _default_material_copy(name, "no material referenced by the layer")
    if local_name(mat_el) == "Gas":
        return _airgap_material(doc, mat_el, name)
    return _solid_material(doc, mat_el, layer_el, name)
