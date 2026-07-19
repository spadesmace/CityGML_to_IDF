"""
Convert every physical quantity into the unit EnergyPlus expects (metres, W/m-K, kg/m3, J/kg-K,
m2-K/W, W/m2-K, and plain 0..1 fractions).

ONE GENERIC CONVERTER, DRIVEN BY A STATIC TABLE
-----------------------------------------------
    to_reference(field, value, uom)  ->  the value in that field's REFERENCE unit, or None

`QUANTITIES` declares, per kind of quantity, the reference unit we convert TO and every `uom`
spelling we ACCEPT (with its factor). `FIELDS` says which quantity each CityGML/ADE element is.
Adding a unit is one line of DATA; adding a field is one line of DATA. No function is edited,
and no if/elif chain grows.

THE ONE RULE HERE: the converter returns the E+-unit value, or **None when the unit is not one
we accept**. We never guess that an unknown unit "was probably already in E+ units": that is how
a BTU or a lb/ft3 silently becomes a wrong-by-a-factor building. `None` flows to the caller's
per-field DEFAULT, which is the one honest fallback. Callers keep their own `None -> default`
branches; this module never picks a fallback value.

WHY UNITS ARE DANGEROUS HERE: every measure in the ADE (`thickness`, `thermalConductivity`,
`density`, `specificHeatCapacity`, `Gas/rValue`, `uValue`) is a `gml:MeasureType`, whose `uom` is
an `anyURI` — and every GML measure type is an EMPTY `<restriction base="gml:MeasureType"/>`, so
the "must be suitable for a length" wording in gml/measures.xsd is DOCUMENTATION, not a
constraint. Any string can legally arrive. (The reference sample really does contain
`uom="xxx"` and `uom="units no idea..."`.)

MATCHING IS EXACT, NEVER BY SUBSTRING. This is what kills the old `mW` trap: a loose
"contains w, m and k" test also matches `mW/(m*K)`, so 35 mW/(m-K) used to read as
35 W/(m-K) — a thousand times too conductive, in silence. As dictionary KEYS, `mw/(m*k)` and
`w/(m*k)` are simply two different entries and cannot be confused. `_watt_prefix` is gone.

UNITS vs VALIDITY are two different jobs and live apart. This module answers "what unit is this
number in?". Whether the resulting number is LEGAL (IDD minima, a ratio inside 0..1) is the
caller's business (`materials._resolve_field`, `openings._checked_ratio`,
`constructions._clamp_open_unit`). MIN_* below are published here only because they are IDD
facts the callers share.
"""

from __future__ import annotations

import math

from ..citygml.xml_io import warn

# Energy+.idd `Material` N4 Specific Heat: `\minimum 100` (J/kg-K).
MIN_SPECIFIC_HEAT = 100.0
# Energy+.idd `Material:NoMass` N1 Thermal Resistance: `\minimum .001` (m2-K/W).
MIN_NOMASS_RESISTANCE = 0.001


# =============================================================================================
# THE DATA — what we accept, and what we convert it to.
# =============================================================================================
# quantity -> (reference unit, {accepted uom: factor to multiply the value by})
#
# Keys are stored NORMALISED: lower-case with every space removed (see `_tidy`), so
# "Unit Interval", "unit  interval" and "unitinterval" all reach the same row.
QUANTITIES = {
    "length": ("m", {
        "m": 1.0, "meter": 1.0, "meters": 1.0, "metre": 1.0, "metres": 1.0,
        "mm": 0.001, "millimeter": 0.001, "millimeters": 0.001,
        "millimetre": 0.001, "millimetres": 0.001,
        "cm": 0.01, "centimeter": 0.01, "centimeters": 0.01,
        "centimetre": 0.01, "centimetres": 0.01,
        "dm": 0.1, "decimeter": 0.1, "decimetre": 0.1,
    }),

    "thermal_conductivity": ("W/(m*K)", {
        "w/(m*k)": 1.0, "w/(k*m)": 1.0, "w/(m.k)": 1.0, "w/mk": 1.0,
        "w/m/k": 1.0, "w/m-k": 1.0, "w/m*k": 1.0,
        # milli / kilo get their OWN rows — never matched by substring (the old mW trap).
        "mw/(m*k)": 0.001, "mw/(k*m)": 0.001, "mw/mk": 0.001, "mw/m-k": 0.001,
        "kw/(m*k)": 1000.0, "kw/(k*m)": 1000.0, "kw/mk": 1000.0,
    }),

    "density": ("kg/m3", {
        "kg/m3": 1.0, "kg/m^3": 1.0, "kg/m**3": 1.0,
        "g/cm3": 1000.0, "g/cm^3": 1000.0, "g/cm**3": 1000.0,
    }),

    "specific_heat": ("J/(kg*K)", {
        "j/(kg*k)": 1.0, "j/(k*kg)": 1.0, "j/kg/k": 1.0, "j/kg-k": 1.0, "j/kgk": 1.0,
        "kj/(kg*k)": 1000.0, "kj/(k*kg)": 1000.0, "kj/kg/k": 1000.0, "kj/kg-k": 1000.0,
        "j/(g*k)": 1000.0, "j/g/k": 1000.0, "j/gk": 1000.0,
    }),

    # gml:AreaType (bdgBdrySurfTotalSurfaceArea / bdgBdrySurfOpaqueSurfaceArea). measures.xsd:
    # "the unit of measure referenced by uom must be suitable for an area, such as square metres
    # or square miles" — documentation only, the restriction is EMPTY, so we declare our own list.
    "area": ("m2", {
        "m2": 1.0, "m^2": 1.0, "m**2": 1.0, "sqm": 1.0,
        "squaremetre": 1.0, "squaremetres": 1.0, "squaremeter": 1.0, "squaremeters": 1.0,
        "cm2": 0.0001, "cm^2": 0.0001,
        "dm2": 0.01, "dm^2": 0.01,
        "ft2": 0.09290304, "ft^2": 0.09290304, "sqft": 0.09290304,
    }),

    "thermal_resistance": ("m2*K/W", {
        "m2*k/w": 1.0, "m^2*k/w": 1.0, "(m^2*k)/w": 1.0, "(m2*k)/w": 1.0,
        "m^2k/w": 1.0, "m2k/w": 1.0, "m^2*k*w^-1": 1.0,
    }),

    "u_value": ("W/(m2*K)", {
        "w/(m2*k)": 1.0, "w/(m^2*k)": 1.0, "w/(k*m2)": 1.0, "w/(k*m^2)": 1.0,
        "w/m2k": 1.0, "w/m^2k": 1.0, "w/m2-k": 1.0, "w/m^2-k": 1.0,
        "w/m2/k": 1.0, "w/m^2/k": 1.0,
        "mw/(m2*k)": 0.001, "mw/(m^2*k)": 0.001, "mw/(k*m^2)": 0.001,
        "kw/(m2*k)": 1000.0, "kw/(m^2*k)": 1000.0, "kw/(k*m^2)": 1000.0,
    }),

    # gml:ScaleType is DIMENSIONLESS, yet GML still REQUIRES a uom on it, and gml/measures.xsd
    # says that unit "must be suitable for a scale factor, such as PERCENT, PERMIL, or
    # PARTS-PER-MILLION". So a perfectly legal file may write
    #     <nrg3:gValue uom="%">60</nrg3:gValue>          meaning SHGC = 0.60
    # Ignoring the uom reads that as 60, and a downstream clamp quietly turns it into ~1.0.
    "scale": ("1", {
        "": 1.0, "unitinterval": 1.0, "unit": 1.0, "unity": 1.0, "ratio": 1.0,
        "fraction": 1.0, "dimensionless": 1.0, "1": 1.0, "-": 1.0,
        "%": 0.01, "percent": 0.01, "pct": 0.01,
        "permil": 0.001, "promille": 0.001, "o/oo": 0.001, "‰": 0.001,
        "ppm": 0.000001, "parts-per-million": 0.000001, "partspermillion": 0.000001,
    }),
}

# CityGML/ADE element name -> which quantity it is.
# This is the whole "what do we accept for this field" answer, in one place.
FIELDS = {
    "thickness":                        "length",
    "thermalConductivity":              "thermal_conductivity",
    "density":                          "density",
    "specificHeatCapacity":             "specific_heat",
    "rValue":                           "thermal_resistance",
    "uValue":                           "u_value",
    # gml:AreaType — the LoD2 "total - opaque" window source (openings.py path C)
    "bdgBdrySurfTotalSurfaceArea":      "area",
    "bdgBdrySurfOpaqueSurfaceArea":     "area",
    # every gml:ScaleType we read
    "gValue":                           "scale",
    "fraction":                         "scale",   # transmittance/reflectance/emissivity
    "glazingRatio":                     "scale",
    "bdgBdrySurfOpeningToSurfaceRatio": "scale",
}


# =============================================================================================
# THE LOGIC — one converter.
# =============================================================================================
def _num(v, default=None):
    """Coerce v to float; blank/NaN/unparseable -> default."""
    if v is None or (isinstance(v, float) and math.isnan(v)):
        return default
    try:
        return float(v)
    except (TypeError, ValueError):
        return default


def _tidy(uom):
    """Reduce whatever the file wrote to the short symbol the table is keyed by.

    Lower-cases and removes every space, so "Unit Interval" / "unit  interval" / "UNITINTERVAL"
    all become "unitinterval", and "W/(m*K)" becomes "w/(m*k)". This is the ONLY normalisation
    we do; everything after it is an EXACT table lookup.

    It is deliberately dumb, because clever string surgery on unit strings is exactly where the
    bugs live — the old substring matcher read 35 mW/(m-K) as 35 W/(m-K).

    NOT HANDLED, on purpose: a uom written as a REFERENCE. measures.xsd says "The XML attribute
    uom REFERENCES the units... the abbreviated XPointer prefix '#' should be used", and uom is
    an anyURI, so "#m" or "urn:ogc:def:uom:UCUM::m" are legal ways to write "m". No real file
    uses them, so that unwrapping was removed rather than carried untested — such a uom simply
    falls to the caller's default WITH a warning naming it. If one ever turns up, either add the
    literal string as a table key, or re-add the unwrapping here — CAREFULLY: a unit SYMBOL also
    contains '/' and ':' ("W/(m*K)", "J/(kg*K)"), so splitting blindly on '/' turns "W/(m*K)"
    into "k)"; unwrap only a leading '#' or a urn:/http(s):// scheme.
    """
    return "".join((uom or "").lower().split())


def to_reference(field, value, uom, context=""):
    """`value` converted into the reference unit declared for `field`, or None.

    None means "we do not accept that unit" — the CALLER then applies its own default. An
    ABSENT/empty uom is read as the field's reference unit (the file omitted it because the
    quantity is already in the obvious unit); that is a deliberate, documented leniency and the
    only one we allow.
    """
    if value is None:
        return None

    quantity = FIELDS.get(field)
    if quantity is None:                       # a field nobody declared = a gap in FIELDS
        warn(f"{context or field}: no unit rule declared for field '{field}'; "
             f"value unusable, using the default")
        return None

    reference, accepted = QUANTITIES[quantity]
    key = _tidy(uom)
    if key == "":                              # uom absent -> assume the reference unit
        return value
    factor = accepted.get(key)                 # EXACT lookup — never a substring test
    if factor is None:
        warn(f"{context or field}: unit '{uom}' is not accepted for {field} "
             f"(reference unit {reference}); value unusable, using the default")
        return None
    return value * factor


# =============================================================================================
# TWO FIELD NOTES worth keeping (they are about the DATA, not the units):
#
#  specificHeatCapacity — a value-based guess was REMOVED from this module. The old converter
#      did `if value < 10: x1000`, silently rescuing a physically impossible cp (a real cp is
#      ~800-2000 J/(kg*K)). That is a DATA judgement, not a unit conversion, and it was made
#      with NO warning. Now an implausible cp simply fails the IDD floor in
#      `materials._resolve_specific_heat` (MIN_SPECIFIC_HEAT = 100) and takes that caller's
#      default, WITH a warning. Measured on the samples: 16 materials state `0.9 J/(kg*K)`;
#      old = 0.9x1000 = 900 silently, new = 0.9 rejected -> DEFAULT_SPECIFIC_HEAT (900.0).
#      Same number, but the file's error is reported instead of papered over.
#
#  rValue — the reference sample writes `<nrg3:rValue uom="J/K/mol">8.314</nrg3:rValue>`: the
#      UNIVERSAL GAS CONSTANT, not a thermal resistance. The ADE's rValue IS an R-value, so
#      that file is simply wrong. "J/K/mol" is not in the thermal_resistance row, so it returns
#      None -> the caller's ISO 6946 default. That is why those air gaps warn.
# =============================================================================================
