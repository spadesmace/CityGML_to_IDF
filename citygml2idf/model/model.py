"""
This module now holds the WHOLE typed middle layer (Material, Construction, Window,
Surface, Zone, Building, WindowConstruction, Model).there is one
Model, and the writer reads the fields it needs and ignores `provenance`.
"""

from __future__ import annotations

from dataclasses import dataclass, field, fields, is_dataclass
from typing import Optional


# ===== provenance status vocabulary (shared by every model builder) ==========
# A VALUE field (one that could be "the file's number OR our default") records one entry:
# a machine-readable STATUS + a human note.
#   ok       stated, converted, EnergyPlus accepts it  -> the REAL value
#   absent   not stated                                -> field default
#   invalid  stated but unusable (uom we reject, or a value the IDD rejects) -> field default
# absent and invalid both fall back, but only `invalid` means a real value was LOST.
# DESCRIPTIONS (geometry, area, which-tier, layer order) stay plain strings — no default to
# contrast with, so no status.
OK, ABSENT, INVALID = "ok", "absent", "invalid"


def trace(status, note):
    """One VALUE-field provenance entry: {status, note}."""
    return {"status": status, "note": note}


@dataclass
class Material:
    """One EnergyPlus material object, tagged by `eplus`. Only the fields that object
    needs are set; the rest stay None (and are dropped on serialisation)."""
    name: str
    eplus: str                          # "Material" | "Material:NoMass" | "Material:AirGap"
    roughness: Optional[str] = None
    thickness: Optional[float] = None
    conductivity: Optional[float] = None
    density: Optional[float] = None
    specific_heat: Optional[float] = None
    thermal_resistance: Optional[float] = None
    provenance: dict = field(default_factory=dict)   # field -> "what we did" (one line)


@dataclass
class Construction:
    """An E+ Construction: ordered material-layer NAMES in ADE order (inside->outside).
    The writer reverses to E+ outside->inside using `layer_order`. `layers` empty = the
    construction carried nothing usable (the resolver then falls to the default)."""
    name: str
    layers: list = field(default_factory=list)          # material names, ADE inside->outside
    layer_order: str = "inside_to_outside"              # layer_order describes the stored list as seen from the zone that owns the surface using it
    source: str = ""                                    # citygml_layers | citygml_uvalue | default
    source_context_id: Optional[str] = None             # owner (surface/zone/building) it resolved from
    provenance: dict = field(default_factory=dict)      # notes (uValue conversion, reversed_of, …)


@dataclass
class Window:
    """One fenestration opening on a wall (E+ FenestrationSurface:Detailed)."""
    source_id: str
    points: list                                        # outward-wound vertices, metres, recentred
    area: float = 0.0
    source: str = ""                                    # "explicit" (LoD3 polygon) | "wwr" (synthesized)
    construction: str = ""                              # glazing construction name (key into Model.window_constructions)
    wwr: Optional[float] = None                         # window-to-wall ratio, if synthesized
    provenance: dict = field(default_factory=dict)


@dataclass
class Surface:
    """One envelope face (E+ BuildingSurface:Detailed). This is the SPINE: every parser
    stage mutates it in place — building_surfaces creates it (geometry + role), reader
    fills metric points + area, constructions sets `construction`, openings appends
    `windows`, adjacency sets the facts below, zones sets `zone`/`surface_type` (orientation)
    /`boundary`/`boundary_object`. `provenance` records one readable line per field."""
    source_id: str
    source_gml_id: str = ""
    type_name: str = ""                                 # CityGML/ADE label, or "classified"
    role: str = ""                                      # wall | roof | floor | ceiling
    surface_type: str = ""                              # E+ Surface_Type: Wall/Roof/Floor/Ceiling
    boundary: str = ""                                  # Outdoors | Ground | Surface | Adiabatic
    points: list = field(default_factory=list)          # outward-wound vertices, metres, recentred
    area: float = 0.0
    construction: str = ""                              # construction name (key into Model.constructions)
    zone: str = ""                                      # owning E+ Zone name
    boundary_object: str = ""                           # A7 partner surface name (interzone pair), else ""
    # --- schema-native adjacency FACTS (model/adjacency.py); zones.py turns them into a boundary ---
    is_adiabatic: Optional[bool] = None                 # nrg3:bdgBdrySurfIsAdiabatic (None = file is silent)
    adjacent_ids: list = field(default_factory=list)    # relatedTo/CityObjectRelation[adjacentTo] target gml:ids
    windows: list = field(default_factory=list)         # list[Window]
    construction_context_ids: list = field(default_factory=list)   # zone/building ids for construction fallback
    provenance: dict = field(default_factory=dict)      # field -> "what we did" (one line)


@dataclass
class Zone:
    """One E+ Zone (one per nrg3:ThermalZone)"""
    name: str
    infiltration_ach: Optional[float] = None   # nrg3:infiltrationRate in 1/h; None = file silent
    provenance: dict = field(default_factory=dict)


@dataclass
class WindowConstruction:
    """One glazing (WindowMaterial:SimpleGlazingSystem + Construction). `visible_transmittance`
    is OMITTED (None) when the CityGML gives no visible nrg3:transmittance (E+ field is optional)."""
    name: str
    u_factor: float
    shgc: float
    visible_transmittance: Optional[float] = None
    provenance: dict = field(default_factory=dict)


@dataclass
class Building:
    """One building -> one IDF: its zones + envelope surfaces (+ audit metadata).
    A building with no `surfaces` (no readable surface, or dropped by model/zones.py) stays
    here for the audit trail but is skipped by the writer; `provenance["skipped"]` says why."""
    id: str
    zones: list = field(default_factory=list)            # list[Zone]
    surfaces: list = field(default_factory=list)         # list[Surface]
    lod: Optional[int] = None                            # the ONE LoD the building is read in
    surface_path: str = ""                               # which SurfacePath produced the surfaces
    origin_offset: Optional[list] = None                 # site min-corner shift undone at recentre
    provenance: dict = field(default_factory=dict)


@dataclass
class Model:
    """The whole middle layer in ONE shape (no more trace/idf split): every building plus
    the constructions/materials they use. The writer reads the fields it needs and ignores
    `provenance`."""
    crs: dict
    buildings: list                                       # list[Building]
    constructions: dict = field(default_factory=dict)     # name -> Construction
    materials: dict = field(default_factory=dict)         # name -> Material
    window_constructions: dict = field(default_factory=dict)   # name -> WindowConstruction

    def building(self, building_id):
        """The Building with this id, or None."""
        for b in self.buildings:
            if b.id == building_id:
                return b
        return None

    def subset_for_building(self, building_id):
        """A new Model holding ONE building + only the constructions/materials/glazings it uses.

        The sets answer only "is this name used?"; the subset dicts are built by iterating
        the POOLS, whose insertion order is the GML discovery order. Iterating the sets
        instead made the same input produce a differently-ordered IDF/JSON on every run
        (Python reshuffles a set of strings per process)."""
        building = self.building(building_id)
        if building is None:
            raise KeyError(f"building '{building_id}' not found")
        construction_names = {s.construction for s in building.surfaces if s.construction}
        constructions_used = {name: c for name, c in self.constructions.items()
                              if name in construction_names}
        material_names = {m for c in constructions_used.values() for m in c.layers}
        materials_used = {name: m for name, m in self.materials.items()
                          if name in material_names}
        glazing_names = {w.construction for s in building.surfaces for w in s.windows if w.construction}
        glazings_used = {name: g for name, g in self.window_constructions.items()
                         if name in glazing_names}
        return Model(crs=self.crs, buildings=[building],
                     constructions=constructions_used, materials=materials_used,
                     window_constructions=glazings_used)


def to_jsonable(obj):
    """JSON-safe form: dataclass -> dict (dropping None fields), dict/list recurse, else
    as-is. Works as json.dump(..., default=to_jsonable) too."""
    if is_dataclass(obj):
        return {f.name: to_jsonable(getattr(obj, f.name))
                for f in fields(obj) if getattr(obj, f.name) is not None}
    if isinstance(obj, dict):
        return {key: to_jsonable(value) for key, value in obj.items()}
    if isinstance(obj, list):
        return [to_jsonable(value) for value in obj]
    return obj
