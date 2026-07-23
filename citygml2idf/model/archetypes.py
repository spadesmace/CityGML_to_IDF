"""
the ARCHETYPE fallback tier  in the CityGML, the building
is looked up in an archetype table keyed by its TYPE — function = residential + construction year +
construction weight (TABULA / UBEM-CARDs style) — to get a per-surface-type U-value.

NOTE map could be :  ( need to check what available)
from bldg:Building 
bldg:yearOfConstruction
parse this order
bldg:function
bldg:usage
bldg:class = “residentail”
bldg:storysAboveGround

define @dataclass
class ArchetypeInput:
"""

from __future__ import annotations

import json
import os
import sys

from ..citygml.xml_io import warn

_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG = os.path.dirname(_HERE)
ARCHETYPES_JSON = os.path.join(_PKG, "input", "archetypes.json")


def load_archetypes(path=ARCHETYPES_JSON):
    """Read the archetype JSON into a plain {key: {param: value}} dict.

    Keys beginning with '_' are documentation (e.g. `A`) and are dropped. A
    missing / empty / broken file returns {} (the tier stays inert), warned once.
    """
    try:
        with open(path, encoding="utf-8") as handle:
            data = json.load(handle)
    except FileNotFoundError:
        return {}
    except (OSError, ValueError) as error:
        warn(f"could not read archetype JSON {path} ({type(error).__name__}: {error}); "
             f"archetype tier ignored")
        return {}
    if not isinstance(data, dict):
        warn(f"archetype JSON {path} is not an object; archetype tier ignored")
        return {}
    return {key: value for key, value in data.items() if not str(key).startswith("_")}


def lookup(table, key):
    """The archetype row for `key` (exact match), else the 'default' row, else None.
    """
    if not table:
        return None
    return table.get(key) or table.get("default")


