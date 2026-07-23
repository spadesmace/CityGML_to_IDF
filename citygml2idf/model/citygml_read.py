"""
model/citygml_read.py — typed GML child readers (thin wrappers over CityGMLDoc).

Pull ONE typed value out of a CityGML element: the object inside a property
(inline child or xlink), plain text, or a gml:MeasureType (value + uom). Keeping
these readers together localises the small amount of element-touching the
construction/material code needs, so the rest reads as plain data logic.

Split out of constructions.py; shared by materials.py and constructions.py.
"""

from __future__ import annotations

import math


def _num(v, default=None):
    """Coerce v to float; blank/NaN/unparseable -> default. (Text->number, not unit conversion,
    so it lives here with the other GML readers, not in units.py.)"""
    if v is None or (isinstance(v, float) and math.isnan(v)):
        return default
    try:
        return float(v)
    except (TypeError, ValueError):
        return default


def _child_text(doc, parent, prefix, local): # read value without uom
    """First child's stripped text, or None."""
    if parent is None:
        return None
    els = doc.children(parent, prefix, local)
    return els[0].text.strip() if els and els[0].text and els[0].text.strip() else None


def _child_measure(doc, parent, prefix, local): # read value with Uom
    """Return (numeric value, uom) for a gml:MeasureType-like child."""
    if parent is None:
        return None, None
    els = doc.children(parent, prefix, local)
    if not els:
        return None, None
    el = els[0]
    text = el.text.strip() if el.text and el.text.strip() else None
    return _num(text), (el.get("uom") or "").strip()
