"""The typed middle layer: Model -> Building -> Zone / Surface -> Window, plus Construction /
Material / WindowConstruction. Every object carries a flat `provenance` map (field -> one
readable line); the writer reads the data fields and ignores it.
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
    The writer reverses every construction to E+ outside->inside. `layers` empty = the
    construction carried nothing usable (the resolver then falls to the default)."""
    name: str
    layers: list = field(default_factory=list)          # material names, ADE inside->outside
    source: str = ""                                    # citygml_layers | citygml_uvalue | default
    source_context_id: Optional[str] = None             # owner (surface/zone/building) it resolved from
    provenance: dict = field(default_factory=dict)      # notes (uValue conversion, reversed_of, …)


@dataclass
class Window:
    """One window or skylight on an outside wall or roof (E+ FenestrationSurface:Detailed)."""
    source_id: str
    points: list                                        # outward-wound vertices, metres, lowered to the building's ground
    area: float = 0.0
    source: str = ""                                    # "explicit" (LoD3 polygon) | "wwr" (synthesized)
    construction: str = ""                              # glazing construction name (key into Model.window_constructions)
    wwr: Optional[float] = None                         # window-to-wall ratio, if synthesized
    provenance: dict = field(default_factory=dict)


@dataclass
class Surface:
    """One envelope face (E+ BuildingSurface:Detailed), filled in place stage by stage:
    building_surfaces (geometry, role, type), reader (points lowered to the ground, area), constructions
    (`construction`), adjacency (the facts below), zones (`zone`, `boundary`,
    `boundary_object`; a LoD1 slab drawn as Roof becomes Ceiling), openings (`windows`).
    `provenance` records one readable line per field."""
    source_id: str
    type_name: str = ""                                 # CityGML/ADE label, or "classified"
    role: str = ""                                      # surface_types role: wall, roof, ground, party_wall, intermediate_floor, ...
    surface_type: str = ""                              # E+ Surface_Type: Wall/Roof/Floor/Ceiling
    boundary: str = ""                                  # Outdoors | Ground | Surface | Adiabatic
    points: list = field(default_factory=list)          # outward-wound vertices, metres, lowered to the building's ground
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
    ground_height: Optional[float] = None                # the z the building was lowered by (lowest point -> 0)
    provenance: dict = field(default_factory=dict)


@dataclass
class Model:
    """The whole middle layer: every building plus the constructions / materials / glazings
    they use. The writer reads the fields it needs and ignores `provenance`."""
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
        """A new Model holding ONE building + only the constructions / materials / glazings it uses.

        The sets only answer "is this name used?"; each subset dict follows its POOL's order
        (the file's discovery order), so the same input always gives the same IDF and JSON.
        """
        building = self.building(building_id)
        if building is None:
            raise KeyError(f"building '{building_id}' not found")
        construction_names = {s.construction for s in building.surfaces if s.construction}
        constructions_used = {name: c for name, c in self.constructions.items()
                              if name in construction_names}
        material_names = set()
        for construction in constructions_used.values():
            material_names.update(construction.layers)
        materials_used = {name: m for name, m in self.materials.items()
                          if name in material_names}
        glazing_names = set()
        for surface in building.surfaces:
            for window in surface.windows:
                if window.construction:
                    glazing_names.add(window.construction)
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
