"""
model/idf_model.py — the TYPED IDF view (writer contract).

The parser has two views of the same parse: a rich `trace` view (kept as a flexible
dict, for audit) and this `idf` view — the clean, EnergyPlus-ready contract that
write/writer.py consumes. It used to be a bare dict; these dataclasses give it named,
typed fields so the writer reads `surface.surface_type` instead of `surface["..."]`
and the exact shape is documented in ONE place.

Nothing here parses XML or touches EnergyPlus; it is pure data. `to_idf_middle_layer`
in reader.py builds these from the trace view; `to_jsonable()` serialises them back to
the SAME JSON shape the dict view produced (so middle_layer_idf_*.json is unchanged).
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Optional


@dataclass
class IdfWindow:
    """One fenestration opening on a wall (FenestrationSurface:Detailed)."""
    source_id: str
    points: list

    def to_jsonable(self):
        return {"source_id": self.source_id, "points": self.points}


@dataclass
class IdfSurface:
    """One BuildingSurface:Detailed: its role, boundary, construction, zone, geometry."""
    source_id: str
    surface_type: str          # E+ Surface_Type: Wall / Roof / Floor / Ceiling
    boundary: str              # Outside_Boundary_Condition: Outdoors / Ground / Surface / Adiabatic
    construction: str          # construction name (key into IdfModel.constructions)
    zone: str                  # owning E+ Zone name
    boundary_object: str       # A7 partner surface name for interzone pairs, else ""
    points: list               # outward-wound vertices, metres, recentred
    windows: list = field(default_factory=list)   # list[IdfWindow]

    def to_jsonable(self):
        out = {
            "source_id": self.source_id,
            "surface_type": self.surface_type,
            "boundary": self.boundary,
            "construction": self.construction,
            "zone": self.zone,
            "boundary_object": self.boundary_object,
            "points": self.points,
        }
        if self.windows:                                   # omitted when empty (as before)
            out["windows"] = [w.to_jsonable() for w in self.windows]
        return out


@dataclass
class IdfZone:
    """One E+ Zone (one per ThermalZone, or one implicit building zone)."""
    name: str
    volume: Optional[float]    # m3, or None -> EnergyPlus autocalculates

    def to_jsonable(self):
        return {"name": self.name, "volume": self.volume}


@dataclass
class IdfBuilding:
    """One building -> one IDF: its zones and its envelope surfaces."""
    id: str
    zones: list                # list[IdfZone]
    surfaces: list             # list[IdfSurface]

    def to_jsonable(self):
        return {
            "id": self.id,
            "zones": [z.to_jsonable() for z in self.zones],
            "surfaces": [s.to_jsonable() for s in self.surfaces],
        }


@dataclass
class IdfConstruction:
    """An E+ Construction: ordered material-layer names + the source layer order."""
    layers: list
    layer_order: Optional[str] = None   # "inside_to_outside" (ADE) etc.

    def to_jsonable(self):
        out = {"layers": self.layers}
        if self.layer_order is not None:
            out["layer_order"] = self.layer_order
        return out


@dataclass
class IdfMaterial:
    """One of the 3 E+ material objects, tagged by `eplus`; only the fields that
    object needs are set (the rest stay None and are dropped on serialisation)."""
    name: str
    eplus: str                 # "Material" | "Material:NoMass" | "Material:AirGap"
    roughness: Optional[str] = None
    thickness: Optional[float] = None
    conductivity: Optional[float] = None
    density: Optional[float] = None
    specific_heat: Optional[float] = None
    thermal_resistance: Optional[float] = None

    def to_jsonable(self):
        if self.eplus == "Material:AirGap":
            keys = ["name", "eplus", "thermal_resistance"]
        elif self.eplus == "Material:NoMass":
            keys = ["name", "eplus", "roughness", "thermal_resistance"]
        else:
            keys = ["name", "eplus", "roughness", "thickness", "conductivity",
                    "density", "specific_heat"]
        return {k: getattr(self, k) for k in keys}


@dataclass
class WindowConstruction:
    """The single default glazing (WindowMaterial:SimpleGlazingSystem + Construction)."""
    name: str
    u_factor: float
    shgc: float

    def to_jsonable(self):
        return {"name": self.name, "u_factor": self.u_factor, "shgc": self.shgc}


@dataclass
class IdfModel:
    """The whole clean writer view: buildings + the constructions/materials they use."""
    view: str
    crs: dict
    buildings: list                          # list[IdfBuilding]
    constructions: dict                      # name -> IdfConstruction
    materials: dict                          # name -> IdfMaterial
    window_construction: Optional[WindowConstruction]

    def building(self, building_id):
        """The IdfBuilding with this id, or None."""
        for b in self.buildings:
            if b.id == building_id:
                return b
        return None

    def subset_for_building(self, building_id):
        """A new IdfModel holding ONE building + only the constructions/materials it
        uses (mirrors run.py's per-building slice for the idf view)."""
        building = self.building(building_id)
        if building is None:
            raise KeyError(f"building '{building_id}' not found in idf view")
        construction_names = {s.construction for s in building.surfaces if s.construction}
        constructions_used = {name: self.constructions[name]
                              for name in construction_names if name in self.constructions}
        material_names = {m for c in constructions_used.values() for m in c.layers}
        materials_used = {name: self.materials[name]
                          for name in material_names if name in self.materials}
        return IdfModel(view=self.view, crs=self.crs, buildings=[building],
                        constructions=constructions_used, materials=materials_used,
                        window_construction=self.window_construction)

    def to_jsonable(self):
        """Serialise back to the SAME JSON shape the old dict view produced."""
        return {
            "view": self.view,
            "crs": self.crs,
            "buildings": [b.to_jsonable() for b in self.buildings],
            "constructions": {name: c.to_jsonable() for name, c in self.constructions.items()},
            "materials": {name: m.to_jsonable() for name, m in self.materials.items()},
            "window_construction": (self.window_construction.to_jsonable()
                                    if self.window_construction else None),
        }
