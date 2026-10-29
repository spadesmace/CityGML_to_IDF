"""
model/adjacency.py — READ-ONLY schema-native adjacency facts.

This module answers two questions about ONE surface, straight from the XML. It decides
NOTHING: it never sets a boundary, never touches geometry. `model/zones.py` consumes the
facts and applies the boundary waterfall.

  1. Is the surface explicitly adiabatic?      nrg3:bdgBdrySurfIsAdiabatic  -> True/False/None
  2. Which surfaces is it adjacent to?         nrg3:relatedTo
                                                 -> nrg3:CityObjectRelation
                                                      -> nrg3:relationType == "adjacentTo"
                                                      -> nrg3:relatedTo/@xlink:href
                                               -> [target gml:id, ...]

WHY schema-native and not geometry (the reference repo computes adjacency with coplanar +
opposite-normal + polygon-overlap tests, then injects gen:stringAttribute "adjacentSurface"):
our Energy ADE files ALREADY carry the relation, so we read it instead of recomputing it —
the golden rule (trust structure + explicit references, never guess).

THE CODELIST DECIDES: nrg3:relationType is a RelationTypeValue, and the Energy ADE codelist
(codelists/RelationTypeValue.xml) allows exactly adjacentTo, installedOn and sharedWith. We act
on "adjacentTo" only, spelled exactly as in the codelist; any other value is not an adjacency.

TWO TRAPS this module is built around:
  * `relatedTo` is OVERLOADED. It also carries relationType="installedOn" (solar/PV modules
    mounted on a surface), which is skipped.
  * an `adjacentTo` target may be ANY core:_CityObject — another Building, BuildingPart,
    ThermalZone or CityFurniture, not just a surface. We return the raw target ids; the
    CALLER decides whether a target is a real surface inside the SAME IDF. (EnergyPlus
    Outside_Boundary_Condition=Surface must name a surface present in the same IDF.)

Run as a demo (from the repo root) to preview — without changing anything — what boundary
each surface WOULD get:
    python -m citygml2idf.model.adjacency [path.gml]
"""

from __future__ import annotations

import sys

from ..citygml import xml_io
from ..citygml.xml_io import GML_ID, local_name
from .citygml_read import _child_text

ADJACENT_TO = "adjacentTo"     # the only nrg3:relationType we act on (codelist spelling)


def surface_is_adiabatic(doc, surf_el):
    """nrg3:bdgBdrySurfIsAdiabatic -> True / False / None (property absent).

    None and False are NOT the same: False means the file explicitly says "heat crosses
    me"; None means the file is silent, so the surface type's default decides."""
    text = _child_text(doc, surf_el, "nrg", "bdgBdrySurfIsAdiabatic")
    if text is None:
        return None
    return text.strip().lower() == "true"


def adjacent_target_ids(doc, element):
    """The gml:ids this element declares itself adjacent to.

    Parameters
    ----------
    doc : xml_io.CityGMLDoc
        The parsed CityGML file.
    element : lxml element
        A boundary surface.

    Returns
    -------
    list of str
        Targets of nrg3:relatedTo -> nrg3:CityObjectRelation (relationType "adjacentTo")
        -> nrg3:relatedTo/@xlink:href; [] when there are none.

    Notes
    -----
    Only the codelist value "adjacentTo" counts (codelists/RelationTypeValue.xml); every other
    value, e.g. "installedOn" for PV modules, is skipped. The xlink is resolved through
    property_object, so both '#id' and a bare 'id' work.
    """
    targets = []
    for relation_property in doc.children(element, "nrg", "relatedTo"):
        relation = doc.property_object(relation_property)          # nrg3:CityObjectRelation
        if relation is None or local_name(relation) != "CityObjectRelation":
            continue
        relation_type = (_child_text(doc, relation, "nrg", "relationType") or "").strip()
        if relation_type != ADJACENT_TO:
            continue
        for target_property in doc.children(relation, "nrg", "relatedTo"):
            target = doc.property_object(target_property)           # follows xlink:href
            if target is not None and target.get(GML_ID):
                targets.append(target.get(GML_ID))
    return targets


def facts_for_surface(doc, surf_el):
    """(is_adiabatic, [adjacent target gml:ids]) for one surface element."""
    if surf_el is None:
        return None, []
    return surface_is_adiabatic(doc, surf_el), adjacent_target_ids(doc, surf_el)


def attach_facts(doc, model):
    """Read the adjacency facts onto every Surface in the model.

    READ-ONLY with respect to EnergyPlus: it sets `Surface.is_adiabatic` and
    `Surface.adjacent_ids` (+ provenance) and NEVER touches `boundary`,
    `boundary_object`, geometry or construction. `model/zones.py` applies the waterfall.
    Surfaces with no element in the document (e.g. generated partners) keep their defaults.
    """
    for building in model.buildings:
        for surface in building.surfaces:
            element = doc.get_by_id(surface.source_gml_id or surface.source_id)
            is_adiabatic, adjacent = facts_for_surface(doc, element)
            surface.is_adiabatic = is_adiabatic
            surface.adjacent_ids = adjacent
            if is_adiabatic is not None:
                surface.provenance["is_adiabatic"] = (
                    f"citygml nrg3:bdgBdrySurfIsAdiabatic = {str(is_adiabatic).lower()}")
            if adjacent:
                surface.provenance["adjacent_ids"] = (
                    f"citygml relatedTo/CityObjectRelation[relationType='adjacentTo'] -> "
                    f"{', '.join(adjacent)}")
    return model

# TODO must add geometry logic fall back to if we do not receive  full sample like with RelatedTo 

# ---------------------------------------------------------------------------
def _demo(path=None):
    """Preview the boundary each surface WOULD get. Changes nothing.

    Mirrors the waterfall zones.py will apply:
      1. isAdiabatic == True            -> Adiabatic (overrides everything)
      2. adjacent target IS a surface in THIS building's surface set (same IDF)
                                        -> Surface (reciprocal)
      3. adjacent target is anything else (other building / zone / missing)
                                        -> Adiabatic
      4. no facts                       -> the surface type's default
    """
    from .reader import build_middle_layer
    doc = xml_io.CityGMLDoc(path)
    model = build_middle_layer(doc)

    totals = {"Surface": 0, "Adiabatic(flag)": 0, "Adiabatic(off-IDF)": 0}
    for building in model.buildings:
        in_idf = {s.source_id for s in building.surfaces}
        in_idf |= {s.source_gml_id for s in building.surfaces if s.source_gml_id}

        rows = []
        for surface in building.surfaces:
            element = doc.get_by_id(surface.source_gml_id or surface.source_id)
            adiabatic, targets = facts_for_surface(doc, element)
            if adiabatic is None and not targets:
                continue                                   # rule 4 — nothing to report
            same_idf = [t for t in targets if t in in_idf]
            if adiabatic is True:
                verdict, key = "Adiabatic  (explicit isAdiabatic=true)", "Adiabatic(flag)"
            elif same_idf:
                verdict, key = f"Surface    -> {same_idf[0]}", "Surface"
            elif targets:
                verdict, key = f"Adiabatic  (adjacent {targets[0]} not in this IDF)", "Adiabatic(off-IDF)"
            else:
                continue                                   # isAdiabatic=false, no adjacency
            totals[key] += 1
            rows.append(f"    {surface.source_id:<44} {surface.type_name:<24} {verdict}")

        if rows:
            print(f"  {building.id}  ({len(building.zones)} zone(s))")
            for row in rows:
                print(row)

    print(f"\n  would-be boundaries: {totals}")


if __name__ == "__main__":
    _demo(sys.argv[1] if len(sys.argv) > 1 else None)
