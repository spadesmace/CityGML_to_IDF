"""
model/units.py — PURE value + unit helpers (no XML, no doc).

Coerce raw spreadsheet/text values to Python numbers/strings, and convert every
physical quantity into the unit EnergyPlus expects (metres, W/m-K, kg/m3, J/kg-K,
W/m2-K). Each converter is a leaf function: given a value + its `uom`, return the
EnergyPlus-unit value, warning (never crashing) on an unrecognised unit.

Split out of constructions.py so the unit rules live in ONE readable place.
"""

from __future__ import annotations

import math

import pandas as pd

from ..citygml.xml_io import warn

# EnergyPlus minimum for Material.Specific Heat is 100 J/kg-K (Energy+.idd).
# One source of truth: DEFAULT_MATERIAL["specific_heat"] reuses this value.
MIN_SPECIFIC_HEAT = 100.0


# ----- small value helpers ---------------------------------------------------
def _num(v, default=None):
    """Coerce v to float; blank/NaN/unparseable -> default."""
    if v is None or (isinstance(v, float) and math.isnan(v)):
        return default
    try:
        return float(v)
    except (TypeError, ValueError):
        return default


def _str(v, default=None):
    """Coerce v to str; blank/NaN -> default."""
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


# ----- unit conversions (into EnergyPlus units) ------------------------------
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
    if value < MIN_SPECIFIC_HEAT:
        warn(f"{context}: value {value} J/kg-K is below EnergyPlus minimum; using minimum {MIN_SPECIFIC_HEAT}")
        return MIN_SPECIFIC_HEAT
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
