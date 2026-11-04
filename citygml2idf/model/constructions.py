"""The construction RESOLVER: each surface walks its construction owners and runs the TIER
waterfall, most detailed first; the file's own data always before a default.

  owners   the surface itself -> the zone that lists it (for a hull shell or a whole LoD1
           block: only when the building has ONE zone) -> the building
  TIER 1   the construction's own nrg3:layer list -> one material per layer (materials.py)
  TIER 2   no layers, only nrg3:uValue -> Material:NoMass, R = 1/U; R below the IDD
           Material:NoMass N1 minimum (0.001) is a data error -> Tier 4
  TIER 3   an external archetype table: NOT implemented (see the NOTE in _resolve_surface)
  TIER 4   DEFAULT_CONSTRUCTION (materials.DEFAULT_MATERIAL)
  A ReverseLayeredConstruction = its base's layers reversed, named by its own gml:id.

Constructions and materials are linked by gml:id only (inline or xlink); libraryCode /
codeSpace are not read. Each surface resolves its own construction, so one shared by many
surfaces is built again for each (its warnings repeat); the pool keeps the first.

Glazing (window_glazing) has its own waterfall, above _glazing_from_citygml.
LIMIT: simple glazing only (no WindowMaterial:Glazing panes, no per-side emissivity).
"""

from __future__ import annotations

from ..citygml import xml_io
from ..citygml.xml_io import GML_ID, local_name, warn
from ..citygml.citygml_read import child_measure, child_text
from .materials import DEFAULT_MATERIAL, DEFAULT_ROUGHNESS, _material_from_citygml
from .model import ABSENT, INVALID, OK, Construction, Material, WindowConstruction, trace
from .units import to_reference

# Energy+.idd `Material:NoMass` N1 Thermal Resistance: `\minimum .001` (m2-K/W).
MIN_NOMASS_RESISTANCE = 0.001
DEFAULT_NAME = "DEFAULT_CONSTRUCTION"


# ===== construction builders ================================================
def _base_layered_construction(doc, constr_el):
    """The baseLayeredConstruction a ReverseLayeredConstruction points to, or None."""
    props = doc.children(constr_el, "nrg", "baseLayeredConstruction")
    return doc.property_object(props[0]) if props else None


def _construction_name(doc, constr_el):
    """A stable E+ construction name = the construction's gml:id (constructions are identified BY
    their gml:id). We do NOT name by libraryCode."""
    if constr_el is None:
        return DEFAULT_NAME
    return constr_el.get(GML_ID)


def _from_citygml(doc, constr_el, materials):
    """Build a construction from a LayeredConstruction's own inline layers (TIER 1), else from
    its uValue (TIER 2 -> a Material:NoMass with R = 1/U).

    Returns a `Construction` dataclass either way. `Construction.layers` EMPTY means nothing in
    the CityGML was usable, and the caller falls through to the default construction."""
    if constr_el is None:
        return Construction(name="", source="citygml_none")

    if local_name(constr_el) == "ReverseLayeredConstruction": # go fetch its base, take the base's layers, TURN THEM AROUND
        base = _base_layered_construction(doc, constr_el)
        if base is None:
            warn(f"reverse construction '{constr_el.get(GML_ID)}': missing baseLayeredConstruction")
            return Construction(name="", source="citygml_reverse_missing_base")
        resolved = _from_citygml(doc, base, materials)
        reversed_layers = list(reversed(resolved.layers))
        # Spell out BOTH flips in the audit trail (they are different operations, easy to conflate):
        #   flip 1 (here)     : the CityGML expression device — this surface's stratigraphy IS the
        #                       base's, listed backwards; we reverse the base to recover it. The
        #                       result is STILL ADE inside->outside, just seen from THIS zone.
        #   flip 2 (writer.py): the convention change ADE inside->outside -> E+ outside->inside,
        #                       applied to EVERY construction, base and reverse alike.
        return Construction(
            name="", layers=reversed_layers, source=resolved.source or "citygml",
            provenance={
                "reversed_of": base.get(GML_ID),
                "layer_order": (
                    f"ReverseLayeredConstruction of {base.get(GML_ID)}: base layers "
                    f"{resolved.layers} (ADE inside->outside, from the base's zone) reversed -> "
                    f"{reversed_layers} (ADE inside->outside, from THIS zone). "
                    f"The writer flips every construction -> E+ outside->inside."
                ),
            })

    layers = []
    # Each layer is inline inside LayeredConstruction, and its material is by XLink.
    for layer_prop in doc.children(constr_el, "nrg", "layer"): # find <layer> wrapper
        layer = doc.property_object(layer_prop) # open <Layer> object
        if layer is None:
            warn(f"construction '{constr_el.get(GML_ID)}': empty layer property skipped")
            continue
        mat_prop = doc.children(layer, "nrg", "material") # FIND the <material> wrapper
        mat_el = doc.property_object(mat_prop[0]) if mat_prop else None # OPEN → <SolidMaterial> (via xlink)
        m = _material_from_citygml(doc, mat_el, layer)
        materials.setdefault(m.name, m)
        layers.append(m.name)
    if layers:
        return Construction(name="", layers=layers, source="citygml_layers")

    # Energy ADE LayeredConstructionType has optional uValue. EnergyPlus has no
    # direct U-value material, so for opaque averaged data we emit NoMass R=1/U.
    u_raw, u_uom = child_measure(doc, constr_el, "nrg", "uValue")
    u_value = to_reference("uValue", u_raw, u_uom,
                           context=f"construction '{constr_el.get(GML_ID)}' uValue")
    if u_value and u_value > 0:
        thermal_resistance = 1.0 / u_value
        # IDD Material:NoMass N1 Thermal Resistance: `\minimum .001` (m2-K/W). R < 0.001 means
        # U > 1000 W/m2-K — not a building envelope, so the uValue is a DATA ERROR (typically a
        # wrong uom). E+ would Severe on it, so we do NOT emit it: warn and fall through to the
        # default construction below, exactly as if the uValue were unusable.
        if thermal_resistance < MIN_NOMASS_RESISTANCE:
            warn(f"construction '{constr_el.get(GML_ID)}': uValue {u_raw}"
                 f"{(' ' + u_uom) if u_uom else ''} -> R = 1/U = {thermal_resistance} m2-K/W, "
                 f"below the EnergyPlus Material:NoMass minimum ({MIN_NOMASS_RESISTANCE}); "
                 f"unusable (wrong uom?), using the default construction")
        else:
            mat_name = constr_el.get(GML_ID)
            u_text = f"citygml uValue {u_raw}{(' ' + u_uom) if u_uom else ''}"
            materials.setdefault(mat_name, Material(
                name=mat_name, eplus="Material:NoMass",
                roughness=DEFAULT_ROUGHNESS, thermal_resistance=thermal_resistance,
                provenance={"thermal_resistance":
                            trace(OK, f"{u_text} -> R = 1/U = {thermal_resistance} m2-K/W")}))
            return Construction(name="", layers=[mat_name], source="citygml_uvalue",
                                provenance={"u_value": trace(OK, f"{u_text} -> {u_value} W/m2-K")})

    warn(f"construction '{constr_el.get(GML_ID)}': no layers or uValue; using default")
    return Construction(name="", source="citygml")


# glazing constructions
# Waterfall (raw converter, per field, default LAST):
#   u_factor : nrg3:uValue (converted)                       -> DEFAULT_GLAZING_U
#   shgc     : nrg3:gValue
#              -> FIRST solar nrg3:transmittance.fraction      (solar tau is a lower bound
#                 for SHGC; first-wins, warn on duplicates)
#              -> DEFAULT_GLAZING_SHGC
#   visible  : FIRST visible nrg3:transmittance.fraction       -> None (E+ N3 optional -> OMIT)

DEFAULT_GLAZING_U = 2.8       # W/m2-K
DEFAULT_GLAZING_SHGC = 0.7


def _valid_fraction(value, context):
    """A glazing fraction (SHGC / visible transmittance) is usable only if it is ALREADY inside
    the open interval (0,1) — IDD WindowMaterial:SimpleGlazingSystem N2/N3 require > 0 and < 1.

    A value OUTSIDE that is a DATA ERROR (an odd/ignored uom, a typo): we WARN and return None
    so the caller falls to its honest default. We do NOT clamp it into range — clamping 60 to
    0.9999 turns a loud error into a quiet wrong number that LOOKS like real data.

    An already-None input (absent, or a uom units.py rejected) returns None silently — the
    converter already warned, and 'absent' is not an error."""
    if value is None:
        return None
    value = float(value)
    if 0.0 < value < 1.0:
        return value
    warn(f"{context}: value {value} is outside the open interval (0,1) (wrong uom?); "
         f"not usable, using the default")
    return None


def _glazing_transmittances(doc, constr_el, name="glazing"):
    """Read every nrg3:transmittance -> [(wavelengthRange, fraction 0..1), …].

    This is the ONE place we parse nrg3:transmittance. Each property holds a
    <nrg3:Transmittance> with a <nrg3:wavelengthRange> (the XSD ENUMERATES exactly
    solar|infrared|visible|total) and a <nrg3:fraction>. Transmittance has NO inside/outside
    side in the ADE (unlike reflectance/emissivity), so a band is just (wavelengthRange,
    fraction). Both 'solar' and 'visible' bands are captured here; the caller picks the one
    it needs.

    `fraction` is a gml:ScaleType: its uom is REQUIRED and may legally be a percent, so it is
    CONVERTED to a 0..1 fraction here and never read raw.
    """
    bands = []
    for prop in doc.children(constr_el, "nrg", "transmittance"):
        transmittance_el = doc.property_object(prop)          # inline <nrg3:Transmittance> (or xlink)
        if transmittance_el is None:
            continue
        wavelength = (child_text(doc, transmittance_el, "nrg", "wavelengthRange") or "").strip().lower()
        raw, uom = child_measure(doc, transmittance_el, "nrg", "fraction")
        fraction = to_reference(
            "fraction", raw, uom,
            context=f"glazing '{name}' {wavelength or 'unknown-band'} transmittance")
        if fraction is not None:
            bands.append((wavelength, fraction))
    return bands


def _first_fraction(bands, wavelength):
    """(first fraction whose wavelengthRange == wavelength, how many matched)."""
    hits = [fraction for (band, fraction) in bands if band == wavelength]
    return (hits[0] if hits else None), len(hits)


def _glazing_from_citygml(doc, constr_el, name):
    """Build a SIMPLE glazing (u_factor, shgc, visible_transmittance) from a LayeredConstruction's
    uValue / gValue / transmittance. Real CityGML value first, default LAST; visible transmittance
    is OMITTED when absent/unusable. Each field carries a {status, note} provenance entry."""
    prov = {}

    # --- u_factor : nrg3:uValue -> default ---
    u_raw, u_uom = child_measure(doc, constr_el, "nrg", "uValue")
    u_value = to_reference("uValue", u_raw, u_uom, context=f"glazing '{name}' uValue")
    if u_value and u_value > 0:
        u_factor = u_value
        prov["u_factor"] = trace(OK, f"citygml uValue {u_raw}{(' ' + u_uom) if u_uom else ''} "
                                     f"-> {u_factor} W/m2-K")
    else:
        u_factor = DEFAULT_GLAZING_U
        prov["u_factor"] = trace(ABSENT if u_raw is None else INVALID,
                                 f"no usable uValue -> default {DEFAULT_GLAZING_U} W/m2-K")

    bands = _glazing_transmittances(doc, constr_el, name)   # already converted to 0..1

    # --- shgc : nrg3:gValue -> FIRST solar transmittance -> default ---
    g_raw, g_uom = child_measure(doc, constr_el, "nrg", "gValue")
    g_value = to_reference("gValue", g_raw, g_uom, context=f"glazing '{name}' gValue")
    shgc = _valid_fraction(g_value, f"glazing '{name}' gValue")   # None if absent OR out of range
    if shgc is not None:
        prov["shgc"] = trace(OK, f"citygml gValue {g_raw}{(' ' + g_uom) if g_uom else ''} -> SHGC {shgc}")
    else:
        solar, n_solar = _first_fraction(bands, "solar")
        solar_shgc = _valid_fraction(solar, f"glazing '{name}' solar transmittance")
        if solar_shgc is not None:
            if n_solar > 1:
                warn(f"glazing '{name}': {n_solar} solar transmittances; using the first ({solar})")
            shgc = solar_shgc
            prov["shgc"] = trace(OK, f"solar transmittance {solar} -> SHGC {shgc} (lower-bound approximation)")
        else:
            shgc = DEFAULT_GLAZING_SHGC
            had_source = g_raw is not None or solar is not None   # present but unusable = invalid
            prov["shgc"] = trace(INVALID if had_source else ABSENT,
                                 f"no usable gValue or solar transmittance -> default {DEFAULT_GLAZING_SHGC}")

    # --- visible transmittance : FIRST visible transmittance -> OMIT when absent/unusable ---
    visible, _n_visible = _first_fraction(bands, "visible")
    visible_transmittance = _valid_fraction(visible, f"glazing '{name}' visible transmittance")
    if visible_transmittance is not None:
        prov["visible_transmittance"] = trace(OK, f"citygml visible transmittance {visible} "
                                                  f"-> {visible_transmittance}")
    else:
        prov["visible_transmittance"] = trace(INVALID if visible is not None else ABSENT,
                                              "no usable visible transmittance; omitted (E+ N3 optional)")

    return WindowConstruction(name=name, u_factor=u_factor, shgc=shgc,
                              visible_transmittance=visible_transmittance, provenance=prov)


def window_glazing(doc, window_el):
    """A bldg:Window's glazing (WindowConstruction) from its OWN nrg3:layeredConstruction,
    or None when the window carries no construction (caller then uses the default). This is
    the window side of the RAW CONVERTER: uValue -> U-Factor, gValue/solar transmittance ->
    SHGC, visible transmittance -> Visible Transmittance (omitted when absent)."""
    constr_el = _construction_element(doc, window_el)          # the window's own layeredConstruction
    if constr_el is None:
        return None
    return _glazing_from_citygml(doc, constr_el, _construction_name(doc, constr_el))


# ===== construction owner cascade ============================================
# Read layeredConstruction only from schema-valid CityObject owners.
# This covers BoundarySurface, ThermalZone and Building; it rejects raw gml:Polygon faces from
# LoD1 solids. (bldg:BuildingPart is OUT OF SCOPE — one bldg:Building = one IDF — so it never
# appears in the cascade; see semantics/building_surfaces.py.)
def _construction_element(doc, owner_el):
    """A CityObject owner's LayeredConstruction (inline or via xlink), or None."""
    if owner_el is None:
        return None
    # Energy ADE layeredConstruction is a generic property of CityObject.
    # Raw GML geometry such as gml:Polygon is not a CityObject, so LoD1 solid
    # faces get construction from ThermalZone / Building context, not the face.
    if owner_el.tag.startswith(f"{{{xml_io.NS['gml']}}}"):
        return None
    prop = doc.children(owner_el, "nrg", "layeredConstruction")
    return doc.property_object(prop[0]) if prop else None


# Construction owner cascade:
# LoD2/3 BoundarySurface first; then the LoD1/whole-object context (ThermalZone, Building),
# which arrives as `context_ids` from semantics/building_surfaces._fallback_context_ids.
def _construction_candidates(doc, surf_el, context_ids=None):
    """Construction owner cascade: BoundarySurface -> ThermalZone -> Building; each construction once."""
    owners = [(surf_el.get(GML_ID) if surf_el is not None else None, surf_el)]
    for context_id in context_ids or []:
        owners.append((context_id, doc.get_by_id(context_id)))
    candidates = []
    seen = set()
    for owner_id, owner_el in owners:
        constr_el = _construction_element(doc, owner_el)
        if constr_el is None:
            continue
        key = constr_el.get(GML_ID)              # always set: xml_io generates missing ids
        if key in seen:
            continue
        seen.add(key)
        candidates.append((owner_id, constr_el))
    return candidates


# ===== the TIER waterfall (see the module docstring) ==========================
def _resolve_surface(doc, surf_el, surface_record, materials):
    """Resolve the EnergyPlus construction of one surface, most detailed source first.

    Parameters
    ----------
    doc : CityGMLDoc
        The loaded CityGML document.
    surf_el : lxml element or None
        The surface's own element: a BoundarySurface, or a raw ``gml:Polygon`` in LoD1
        (a polygon is not a CityObject, so it cannot own a construction).
    surface_record : Surface
        The middle-layer surface. Its ``construction_context_ids`` are the fallback
        owners (zone, then building), nearest first.
    materials : dict
        The shared material pool (name -> Material); new materials are added to it.

    Returns
    -------
    tuple of (str, Construction)
        The construction name (the construction's ``gml:id``, or ``DEFAULT_CONSTRUCTION``)
        and the resolved Construction.

    Notes
    -----
    The first owner whose construction yields layers (Tier 1 or 2) wins, else Tier 4. The
    audit line is built by ``_construction_provenance_line``.
    """
    # For LoD1 raw solids, surf_el is a gml:Polygon and cannot own Energy ADE
    # layeredConstruction; the construction comes from the ThermalZone / Building
    # context passed in context_ids.
    context_ids = surface_record.construction_context_ids
    candidates = _construction_candidates(doc, surf_el, context_ids)

    # ===== TIER 1 + TIER 2 : the file's own data, every owner first (_from_citygml) =====
    for owner_id, constr_el in candidates:
        name = _construction_name(doc, constr_el)             # = the construction's gml:id
        resolved = _from_citygml(doc, constr_el, materials)   # T1 layers, or T2 uValue
        if resolved.layers:
            resolved.name = name
            resolved.source_context_id = owner_id
            return name, resolved

    # ===== TIER 3 : EXTERNAL ARCHETYPE — NOT IMPLEMENTED =====
    # NOTE (future improvement): an external archetype table would be added EXACTLY HERE,
    # between the file's own data (Tiers 1-2, above) and the default (Tier 4, below). It would
    # be looked up by building TYPE, not by libraryCode — candidate keys: bldg:function,
    # bldg:yearOfConstruction, nrg3:bdgConstructionWeight (TABULA / UBEM-CARDs style)

    # ===== TIER 4 : DEFAULT =====
    materials.setdefault(DEFAULT_MATERIAL.name, DEFAULT_MATERIAL)
    return DEFAULT_NAME, Construction(name=DEFAULT_NAME, layers=[DEFAULT_MATERIAL.name],
                                      source="default")


def _construction_provenance_line(resolved):
    """The ONE readable line stored in Surface.provenance["construction"] — the audit record of
    how this surface got its construction. Read straight off the resolved Construction."""
    if resolved.source == "default":
        return ("default construction — no CityGML detailed layers (T1) or uValue (T2); "
                "archetype (T3) deferred")
    # A ReverseLayeredConstruction INHERITS its base's source, so it reads citygml_layers /
    # citygml_uvalue here too — the reversal itself is recorded in provenance["layer_order"].
    line = resolved.source                                  # citygml_layers | citygml_uvalue
    if resolved.name:
        line += f" from construction '{resolved.name}'"     # named by its gml:id
    if resolved.source_context_id:
        line += f" (owner {resolved.source_context_id})"
    return line


def resolve_all(doc, middle):
    """Give every surface its construction; fill middle.constructions and middle.materials.
    Each pool keeps the first object built under a name (file order), so every run is the same."""
    constructions, materials = {}, {}
    for b in middle.buildings:
        for s in b.surfaces:
            surf_el = doc.get_by_id(s.source_id)
            name, resolved = _resolve_surface(doc, surf_el, s, materials)
            s.construction = name
            s.provenance["construction"] = _construction_provenance_line(resolved)
            constructions.setdefault(name, resolved)
    middle.constructions = constructions
    middle.materials = materials
