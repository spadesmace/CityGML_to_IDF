"""
model/citygml_read.py — typed GML child readers (thin wrappers over CityGMLDoc).

Pull ONE typed value out of a CityGML element: the object inside a property
(inline child or xlink), plain text, a gml:MeasureType (value + uom), or a
gml:CodeType (value + codeSpace). Keeping these four readers together localises
the small amount of element-touching the construction/material code needs, so the
rest reads as plain data logic.

Split out of constructions.py; shared by materials.py and constructions.py.
"""

from __future__ import annotations

from .units import _num


def _first_el(doc, prop):
    """The object inside a property: its inline child, or the xlink it points to."""
    return doc.property_object(prop)


def _child_text(doc, parent, prefix, local):
    """First child's stripped text, or None."""
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
