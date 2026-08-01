"""
ONE generic unit converter:  to_reference(field, value, uom) -> value in E+ units, or None.

Two DATA tables drive it (adding a unit or a field is one line of data):
  QUANTITIES  per quantity: the reference unit we convert TO + every accepted uom -> its factor.
  FIELDS      per CityGML/ADE element: which quantity it is.

CONTRACT: convert, or return None. None = "we do not accept that unit". We never guess an
unknown unit was "probably already in E+ units" (that is how a BTU silently becomes a
wrong-by-1000 building). The CALLER turns None into its own default; this module picks no value.

WHY THIS IS DANGEROUS: every ADE measure is a gml:MeasureType whose uom is an anyURI constrained
by NOTHING, so any string can legally arrive.

UNITS vs VALIDITY are separate jobs: this answers "what unit is this?". Whether the number is
LEGAL (IDD minima, a 0..1 ratio) is the caller's (materials._resolve_field,
openings._checked_ratio, constructions._valid_fraction).

NOTE LIMIT: reads only a plain symbol ("mm"), not a URI reference ("#u23", "urn:...", "http://...").
To support them: resolve the ref to its gml:catalogSymbol first, then look that up here.
"""

from __future__ import annotations
from ..citygml.xml_io import warn

# Energy+.idd `Material` N4 Specific Heat: `\minimum 100` (J/kg-K).
MIN_SPECIFIC_HEAT = 100.0
# Energy+.idd `Material:NoMass` N1 Thermal Resistance: `\minimum .001` (m2-K/W).
MIN_NOMASS_RESISTANCE = 0.001

# =============================================================================================
# THE DATA — what we accept, and what we convert it to.
# =============================================================================================
# quantity -> (reference unit, {accepted uom: factor to multiply the value by})

# THIS TABLE IS THE WHOLE ANSWER to "what do we accept?" — there is no logic anywhere that
# computes, strips or guesses a unit. A uom is accepted if and only if it appears here, spelled
# EXACTLY as written . Adding a unit is ONE LINE of DATA, and every accepted spelling is visible on the page.

QUANTITIES = {
    "length": ("m", {
        "m": 1.0, "meter": 1.0, "meters": 1.0, "metre": 1.0, "metres": 1.0,
        "mm": 0.001, "millimeter": 0.001, "millimeters": 0.001,
        "millimetre": 0.001, "millimetres": 0.001,
        "cm": 0.01, "centimeter": 0.01, "centimeters": 0.01,
        "centimetre": 0.01, "centimetres": 0.01,
        "dm": 0.1, "decimeter": 0.1, "decimetre": 0.1,
        # we can expand it like :
        #"ft":0.3048 , "in":0.0254
    }),

    "thermal_conductivity": ("W/(m*K)", {
        # NO PREFIX — case carries no meaning here, so both spellings are simply listed.
        "W/(m*K)": 1.0, "W/(K*m)": 1.0, "W/(m.K)": 1.0, "W/mK": 1.0,
        "W/m/K": 1.0, "W/m-K": 1.0, "W/m*K": 1.0,
        "w/(m*k)": 1.0, "w/(k*m)": 1.0, "w/(m.k)": 1.0, "w/mk": 1.0,
        "w/m/k": 1.0, "w/m-k": 1.0, "w/m*k": 1.0,
        # PREFIXED — here the case IS the meaning: m = milli, M = mega, 10^9 apart. Both are
        # listed, so both convert correctly.
        # DO NOT ADD the all-lowercase "mw/..." : that spelling could be either milli or mega
        # and nobody can tell, so it is left out on purpose and falls to the caller's default with a warning
        "mW/(m*K)": 0.001, "mW/(K*m)": 0.001, "mW/mK": 0.001, "mW/m-K": 0.001,
        "MW/(m*K)": 1e6, "MW/(K*m)": 1e6, "MW/mK": 1e6, "MW/m-K": 1e6,
        # kilo: "K" alone is kelvin, never a prefix, so lowercase "kw" is unambiguous.
        "kW/(m*K)": 1000.0, "kW/(K*m)": 1000.0, "kW/mK": 1000.0,
        "kw/(m*k)": 1000.0, "kw/(k*m)": 1000.0, "kw/mk": 1000.0,
    }),

    "density": ("kg/m3", {
        "kg/m3": 1.0, "kg/m^3": 1.0, "kg/m**3": 1.0,
        "g/cm3": 1000.0, "g/cm^3": 1000.0, "g/cm**3": 1000.0,
    }),

    "specific_heat": ("J/(kg*K)", {
        "J/(kg*K)": 1.0, "J/(K*kg)": 1.0, "J/kg/K": 1.0, "J/kg-K": 1.0, "J/kgK": 1.0,
        "j/(kg*k)": 1.0, "j/(k*kg)": 1.0, "j/kg/k": 1.0, "j/kg-k": 1.0, "j/kgk": 1.0,
        "kJ/(kg*K)": 1000.0, "kJ/(K*kg)": 1000.0, "kJ/kg/K": 1000.0, "kJ/kg-K": 1000.0,
        "kj/(kg*k)": 1000.0, "kj/(k*kg)": 1000.0, "kj/kg/k": 1000.0, "kj/kg-k": 1000.0,
        "J/(g*K)": 1000.0, "J/g/K": 1000.0, "J/gK": 1000.0,
        "j/(g*k)": 1000.0, "j/g/k": 1000.0, "j/gk": 1000.0,
    }),

    # gml:AreaType (bdgBdrySurfTotalSurfaceArea / bdgBdrySurfOpaqueSurfaceArea). measures.xsd:
    # "the unit of measure referenced by uom must be suitable for an area, such as square metres
    # or square miles" — documentation only, the restriction is EMPTY, so we declare our own list.
    "area": ("m2", {
        "m2": 1.0, "m^2": 1.0, "m**2": 1.0, "sqm": 1.0, "sq m": 1.0,
        "squaremetre": 1.0, "squaremetres": 1.0, "squaremeter": 1.0, "squaremeters": 1.0,
        "square metre": 1.0, "square metres": 1.0, "square meter": 1.0, "square meters": 1.0,
        "cm2": 0.0001, "cm^2": 0.0001,
        "dm2": 0.01, "dm^2": 0.01,
        "ft2": 0.09290304, "ft^2": 0.09290304, "sqft": 0.09290304, "sq ft": 0.09290304,
    }),

    "thermal_resistance": ("m2*K/W", {
        "m2*K/W": 1.0, "m^2*K/W": 1.0, "(m^2*K)/W": 1.0, "(m2*K)/W": 1.0,
        "m^2K/W": 1.0, "m2K/W": 1.0, "m^2*K*W^-1": 1.0,
        "m2*k/w": 1.0, "m^2*k/w": 1.0, "(m^2*k)/w": 1.0, "(m2*k)/w": 1.0,
        "m^2k/w": 1.0, "m2k/w": 1.0, "m^2*k*w^-1": 1.0,
    }),

    "u_value": ("W/(m2*K)", {
        "W/(m2*K)": 1.0, "W/(m^2*K)": 1.0, "W/(K*m2)": 1.0, "W/(K*m^2)": 1.0,
        "W/m2K": 1.0, "W/m^2K": 1.0, "W/m2-K": 1.0, "W/m^2-K": 1.0,
        "W/m2/K": 1.0, "W/m^2/K": 1.0,
        "w/(m2*k)": 1.0, "w/(m^2*k)": 1.0, "w/(k*m2)": 1.0, "w/(k*m^2)": 1.0,
        "w/m2k": 1.0, "w/m^2k": 1.0, "w/m2-k": 1.0, "w/m^2-k": 1.0,
        "w/m2/k": 1.0, "w/m^2/k": 1.0,
        # PREFIXED — case IS the meaning. No all-lowercase "mw/..." (see thermal_conductivity).
        "mW/(m2*K)": 0.001, "mW/(m^2*K)": 0.001, "mW/(K*m^2)": 0.001,
        "MW/(m2*K)": 1e6, "MW/(m^2*K)": 1e6, "MW/(K*m^2)": 1e6,
        "kW/(m2*K)": 1000.0, "kW/(m^2*K)": 1000.0, "kW/(K*m^2)": 1000.0,
        "kw/(m2*k)": 1000.0, "kw/(m^2*k)": 1000.0, "kw/(k*m^2)": 1000.0,
    }),

    # gml:ScaleType: dimensionless but uom REQUIRED, and % is legal — <gValue uom="%">60</> means
    # 0.60, so the uom must be converted. Spaced and unspaced words are different keys.
    "scale": ("1", {
        "unit interval": 1.0, "unitinterval": 1.0, "unit": 1.0, "unity": 1.0,
        "ratio": 1.0, "fraction": 1.0, "dimensionless": 1.0, "1": 1.0, "-": 1.0,
        "%": 0.01, "percent": 0.01, "pct": 0.01, "scale":1,
        "permil": 0.001, "promille": 0.001, "o/oo": 0.001, "‰": 0.001,
        "ppm": 0.000001, "parts-per-million": 0.000001, "partspermillion": 0.000001,
        "parts per million": 0.000001,
    }),
    "air_change_rate": ("1/h",{
        "1/h":1.0 , "h^-1": 1.0, "ach": 1.0, "1/s": 3600,
    })
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
    "bdgBdrySurfOpeningToSurfaceRatio": "scale",
    "infiltrationRate":                 "air_change_rate"
}


# =============================================================================================
# THE LOGIC — one converter.
# =============================================================================================
def to_reference(field, value, uom, context=""):
    """`value` in the reference unit for `field`, or None if we do not accept the uom.

    ONE exact, case-SENSITIVE dict lookup — no lower-casing, no stripping, no prefix parsing.
    Case is meaning: mW/(m*K) (milli) and MW/(m*K) (mega) are 10^9 apart, both listed separately.
    An empty/absent uom is read as the reference unit (the one leniency we allow).
    """
    if value is None: # --> None (nothing to convert)
        return None

    quantity = FIELDS.get(field)
    if quantity is None:                       # --> None + warn   (WE forgot to declare it)
        warn(f"{context or field}: no unit rule declared for field '{field}'; "
             f"value unusable, using the default")
        return None

    reference, accepted = QUANTITIES[quantity]
    symbol = (uom or "").strip()               # trim padding only — CASE and inner spaces KEPT
    if symbol == "":                           # uom absent -> assume the reference unit
        return value

    factor = accepted.get(symbol)              # THE lookup: exact, case-sensitive
    if factor is None:
        warn(f"{context or field}: unit '{uom}' is not accepted for {field} "
             f"(reference unit {reference}); value unusable, using the default")
        return None
    return value * factor