"""
model/model.py — the single TYPED middle layer (dataclasses used everywhere).

We are migrating, one data type at a time, from the old dual view (a nested `trace`
dict + the separate idf_model.py dataclasses, bridged by a hand-written conversion layer)
to ONE set of dataclasses — the shape the reference repo (piotre13/CityGML2Eplus)'s
model.py uses. Each object carries its data PLUS a flat `provenance` map:

    provenance[field] = "one readable line — WHAT we did to this parameter"
    e.g. "citygml 40mm -> 0.040 m"   or   "default 900.0 J/kg-K (specificHeatCapacity not in CityGML)"

That replaces the old 6-key nested per-field trace dict: same audit intent (the professor's
"express what we did for each parameter"), one line instead of a tree.

`to_jsonable(obj)` is the ONE serializer — usable directly as `json.dump(..., default=to_jsonable)`.
It turns any dataclass into a dict (dropping None fields) and recurses dicts/lists.

This module now holds the WHOLE typed middle layer (Material, Construction, Window,
Surface, Zone, Building, WindowConstruction, Model). The old dual view — a nested trace
dict + a separate idf_model.py + a hand-written conversion layer — is gone: there is one
Model, and the writer reads the fields it needs and ignores `provenance`.
"""

from __future__ import annotations

from dataclasses import dataclass, field, fields, is_dataclass
from typing import Optional


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
    layer_order: str = "inside_to_outside"
    source: str = ""                                    # citygml_layers | citygml_uvalue | default | reversed
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
    `windows`, zones sets `zone`/`boundary`/`boundary_object` (+ the reciprocal twin).
    `provenance` folds the old geometry/semantic/construction/zone trace dicts into one
    readable line per field."""
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
    windows: list = field(default_factory=list)         # list[Window]
    construction_context_ids: list = field(default_factory=list)   # zone/building ids for construction fallback
    provenance: dict = field(default_factory=dict)      # field -> "what we did" (one line)


@dataclass
class Zone:
    """One E+ Zone (one per nrg3:ThermalZone, or one implicit building zone)."""
    name: str
    volume: Optional[float] = None                       # m3, or None -> EnergyPlus autocalculates
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
    A building with no `surfaces` (e.g. LoD0 footprint only) stays here for the audit
    trail but is skipped by the writer."""
    id: str
    zones: list = field(default_factory=list)            # list[Zone]
    surfaces: list = field(default_factory=list)         # list[Surface]
    lod: Optional[int] = None                            # highest LoD present (info only)
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
        """A new Model holding ONE building + only the constructions/materials/glazings it uses."""
        building = self.building(building_id)
        if building is None:
            raise KeyError(f"building '{building_id}' not found")
        construction_names = {s.construction for s in building.surfaces if s.construction}
        constructions_used = {name: self.constructions[name]
                              for name in construction_names if name in self.constructions}
        material_names = {m for c in constructions_used.values() for m in c.layers}
        materials_used = {name: self.materials[name]
                          for name in material_names if name in self.materials}
        glazing_names = {w.construction for s in building.surfaces for w in s.windows if w.construction}
        glazings_used = {name: self.window_constructions[name]
                         for name in glazing_names if name in self.window_constructions}
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
