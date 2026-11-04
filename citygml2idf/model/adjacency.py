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

WHAT IS NOT HERE: nrg3:relatedTo is optional. When the file gives none, model/zones.py looks
for the twin of a LoD2/3 face between zones by its corner points (geometry/rings.same_corners).
That needs the zones and the points, so it lives there, not in this file reader.

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
"""

from __future__ import annotations

from ..citygml.xml_io import GML_ID, local_name
from ..citygml.citygml_read import child_bool, child_text

ADJACENT_TO = "adjacentTo"     # the only nrg3:relationType we act on (codelist spelling)


def surface_is_adiabatic(doc, surf_el):
    """nrg3:bdgBdrySurfIsAdiabatic -> True / False / None (property absent).

    None and False are NOT the same: False means the file explicitly says "heat crosses
    me"; None means the file is silent, so the surface type's default decides."""
    return child_bool(doc, surf_el, "nrg", "bdgBdrySurfIsAdiabatic")


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
        relation_type = child_text(doc, relation, "nrg", "relationType")
        if relation_type != ADJACENT_TO:
            continue
        for target_property in doc.children(relation, "nrg", "relatedTo"):
            target = doc.property_object(target_property)           # follows xlink:href
            if target is not None and target.get(GML_ID):
                targets.append(target.get(GML_ID))
    return targets


def attach_facts(doc, model):
    """Read the adjacency facts onto every Surface in the model.

    READ-ONLY with respect to EnergyPlus: it sets `Surface.is_adiabatic` and
    `Surface.adjacent_ids` (+ provenance) and NEVER touches `boundary`,
    `boundary_object`, geometry or construction. `model/zones.py` applies the waterfall.
    A surface with no element in the document keeps its defaults.
    """
    for building in model.buildings:
        for surface in building.surfaces:
            element = doc.get_by_id(surface.source_id)
            if element is None:
                continue
            surface.is_adiabatic = surface_is_adiabatic(doc, element)
            surface.adjacent_ids = adjacent_target_ids(doc, element)
            if surface.is_adiabatic is not None:
                surface.provenance["is_adiabatic"] = (
                    f"citygml nrg3:bdgBdrySurfIsAdiabatic = {str(surface.is_adiabatic).lower()}")
            if surface.adjacent_ids:
                surface.provenance["adjacent_ids"] = (
                    f"citygml relatedTo/CityObjectRelation[relationType='adjacentTo'] -> "
                    f"{', '.join(surface.adjacent_ids)}")
