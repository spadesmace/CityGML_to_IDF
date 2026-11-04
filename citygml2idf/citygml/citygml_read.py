"""Typed readers for ONE child of a CityGML element: text, xs:boolean, gml:MeasureType.

Shared by every module that reads an Energy ADE value.
"""

from __future__ import annotations


def _num(text):
    """text as a float; None when blank or unreadable."""
    try:
        return float(text)
    except (TypeError, ValueError):
        return None


def child_text(doc, parent, prefix, local):
    """The first such child's text, stripped; None when absent or empty."""
    if parent is None:
        return None
    els = doc.children(parent, prefix, local)
    if not els or els[0].text is None:
        return None
    text = els[0].text.strip()
    if not text:
        return None
    return text


def child_bool(doc, parent, prefix, local, default=None):
    """An xs:boolean child: True for 'true', False for 'false', `default` when absent.

    Notes
    -----
    xs:boolean also allows '1' / '0'; only the words are read (the team writes
    true / false), so '1' reads as False.
    """
    text = child_text(doc, parent, prefix, local)
    if text is None:
        return default
    return text == "true"


def child_measure(doc, parent, prefix, local):
    """(value, uom) of a gml:MeasureType child; (None, None) when the child is absent.

    value is None when the text is empty or unreadable; uom is "" when not written.
    The caller converts the unit and picks the default.
    """
    if parent is None:
        return None, None
    els = doc.children(parent, prefix, local)
    if not els:
        return None, None
    el = els[0]
    text = (el.text or "").strip()
    return _num(text), (el.get("uom") or "").strip()
