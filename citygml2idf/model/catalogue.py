"""
model/catalogue.py — the CATALOGUES keyed by (codeSpace, code).

A construction/material may be NAMED by a `libraryCode` (a gml:CodeType qualified by
its `codeSpace`) and defined elsewhere. Its identity is the PAIR (codeSpace, code) —
never the bare code, because two catalogues may reuse the same code string. This
module owns the two catalogues that answer such a code:

  * the EXTERNAL Excel/DB   (`load_database`, matched by `_excel_match`), and
  * the file's OWN library  (`_index_file_library` over its LayeredConstructionLibrary
    members, matched by `_library_member_for_code`).

All spreadsheet-shape knowledge lives in SHEET_NAMES / COLUMN_MAP — swap the xlsx,
change no code. Split out of constructions.py; the waterfall that CHOOSES between
these lives there.
"""

from __future__ import annotations

import os

import pandas as pd

from ..citygml.xml_io import warn
from .citygml_read import _child_code
from .units import _str

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG = os.path.dirname(_HERE)
DEFAULT_DB = os.path.join(_PKG, "input", "construction_db.xlsx")

# ===== the ONLY place that knows the spreadsheet's shape =====================
SHEET_NAMES = {"constructions": "constructions", "materials": "materials", "windows": "windows"}
COLUMN_MAP = {
    "code": "code", "code_space": "code_space", "layer_order": "layer_order",
    "material_name": "material_name",
    "material_type": "material_type", "thickness": "thickness", "conductivity": "conductivity",
    "density": "density", "specific_heat": "specific_heat", "roughness": "roughness",
    "thermal_resistance": "thermal_resistance",
    "u_value": "u_value", "g_value": "g_value",   # windows sheet (used by model/openings.py)
}
# `code_space` qualifies which catalogue a `code` belongs to (the DB declares it as
# data, so a better DB can be swapped in). A blank cell = catalogue-agnostic. The
# entry identity is the PAIR (code_space, code) — never the bare code.


def _empty_database():
    """A DB shape with no entries (used when the Excel can't be loaded)."""
    return {"constructions": {}, "construction_codespaces": {}, "materials": {}}


def _load_database_or_empty():
    """load_database(), degrading to an empty DB (with a warning) on any failure."""
    try:
        return load_database()
    except Exception as exc:
        warn(f"could not load Excel construction database ({type(exc).__name__}: {exc}); using CityGML/default fallback")
        return _empty_database()


# ===== Excel database ========================================================
def load_database(xlsx_path=DEFAULT_DB):
    """Read the spreadsheet into {constructions: code->[material_name…],
    construction_codespaces: code->codeSpace, materials: name->row}.
    Lookup by key, never row position (extra rows/cols are fine).

    The `code_space` column is REQUIRED — it is the catalogue half of the
    (codeSpace, code) identity. A missing column RAISES (caught by
    _load_database_or_empty, which warns and degrades to CityGML/default) rather
    than silently matching by bare code, which would re-open the cross-catalogue
    collision this design exists to prevent. A blank CELL is fine: it means that
    row is catalogue-agnostic (matched by bare code)."""
    cons_df = pd.read_excel(xlsx_path, sheet_name=SHEET_NAMES["constructions"])
    mats_df = pd.read_excel(xlsx_path, sheet_name=SHEET_NAMES["materials"])
    if COLUMN_MAP["code_space"] not in cons_df.columns:
        raise KeyError(f"constructions sheet is missing the required "
                       f"'{COLUMN_MAP['code_space']}' column")
    constructions, construction_codespaces = {}, {}
    for code, grp in cons_df.groupby(COLUMN_MAP["code"]):
        grp = grp.sort_values(COLUMN_MAP["layer_order"])          # 1 = inside (Energy ADE)
        constructions[str(code)] = [str(m) for m in grp[COLUMN_MAP["material_name"]]]
        # which catalogue this code belongs to; blank cell -> None = agnostic
        construction_codespaces[str(code)] = _str(grp[COLUMN_MAP["code_space"]].iloc[0])
    materials = {str(r[COLUMN_MAP["material_name"]]): r.to_dict() for _, r in mats_df.iterrows()}
    return {"constructions": constructions,
            "construction_codespaces": construction_codespaces,
            "materials": materials}


# ===== catalogue lookup by (codeSpace, code) =================================
# The identity of a library/DB entry is the PAIR (codeSpace, code), never the bare
# code: two catalogues may reuse the same code string for different things.
def _excel_match(code, code_space, db):
    """True when the Excel/DB should answer for this (codeSpace, code).

    The DB declares each code's codeSpace (the `code_space` column):
      * DB codeSpace blank (None) -> catalogue-agnostic row: match by bare code;
      * file code unqualified (None) -> accept the DB row (best effort);
      * otherwise -> match only when the two codeSpaces are EQUAL.
    This is what stops two catalogues that reuse a code from colliding.
    """
    if not code or code not in db.get("constructions", {}):
        return False
    db_code_space = db.get("construction_codespaces", {}).get(code)
    if db_code_space is None or code_space is None:
        return True
    return code_space == db_code_space


def _element_has_layers(doc, constr_el):
    """True if a LayeredConstruction carries its OWN inline nrg:layer children."""
    return constr_el is not None and bool(doc.children(constr_el, "nrg", "layer"))


def _index_file_library(doc):
    """Index every LayeredConstruction in the file by (codeSpace, code).

    This is the file's OWN catalogue (its LayeredConstructionLibrary members). It
    lets a construction named ONLY by libraryCode — whose layers live in a library
    member we did NOT reach by xlink — still be resolved by its code. Keyed by the
    (codeSpace, code) PAIR so codes are never confused across catalogues; first
    definition of a key wins.
    """
    library = {}
    for constr_el in doc.iter_type("nrg", "LayeredConstruction"):
        code, code_space = _child_code(doc, constr_el, "nrg", "libraryCode")
        if code:
            library.setdefault((code_space, code), constr_el)
    return library


def _library_member_for_code(code, code_space, file_library):
    """The file's own LayeredConstruction with this EXACT (codeSpace, code), or None.
    Exact-pair match only — we never guess across codeSpaces."""
    if not code or not file_library:
        return None
    return file_library.get((code_space, code))
