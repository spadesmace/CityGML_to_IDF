# CityGML 2.0 + Energy ADE 3.0 -> EnergyPlus Mapping

This file is the project support matrix. It answers:

```text
What source object can the parser read?
What does it mean?
Where does it go in the middle layer?
What EnergyPlus object is written?
Has this path been tested?
What is still missing?
```

Status meanings:

```text
[x] Verified        Tested through middle layer and/or IDF/EnergyPlus.
[~] Built, recheck  Code exists, but needs the new step-by-step audit.
[ ] Pending         Not implemented or not trusted yet.
[!] Decision needed The source object is known, but mapping meaning is not agreed.
[-] Out of scope    Intentionally ignored for the current pipeline stage.
```

Current validation order:

```text
1. Geometry
2. Construction + material
3. One-zone opaque IDF
4. One-zone windows
5. Multizone
6. HVAC / schedules / loads
7. Adjacent buildings / building groups
```

Reason: every later stage depends on the previous layer being trustworthy. Windows need correct parent surfaces and constructions. Multizone needs correct geometry, zone ownership, and constructions before shared boundaries can be trusted. HVAC should come after zones are stable. Adjacent-building logic is last because it changes the project scope from one IDF per building to possible grouped IDFs.

Roadmap notes:

```text
Geometry
  Goal: find EnergyPlus-ready surfaces from CityGML/Energy ADE.
  Handle semantic bldg:boundedBy surfaces first.
  Fall back to raw gml:Solid faces for LoD1.
  Handle coincidesWithLoD2Hull / coincidesWithLoD3Hull.
  Leave curve geometry and MultiSurface overlap policy as professor decisions.

Construction + material
  Goal: assign every surface a construction with traceable evidence.
  Resolve owner cascade: surface -> ThermalZone -> BuildingPart -> Building.
  Excel by libraryCode first.
  Then CityGML LayeredConstruction -> Layer -> Material.
  Then CityGML uValue -> Material:NoMass.
  Default only when no usable data exists.
  Track raw unit, converted value, EnergyPlus unit, and source.

One-zone opaque IDF
  Goal: prove geometry + construction + material without window or multizone noise.
  Use FORCE_SINGLE_ZONE=True and ENABLE_WINDOWS=False.
  Writer reads only the clean IDF middle layer.

Windows
  Goal: add openings only after opaque surfaces are trusted.
  Explicit LoD3 Window geometry first.
  LoD2 ratio fallback second.
  total/opaque area fallback third.
  Detailed WindowMaterial:Glazing / WindowMaterial:Gas later.

Multizone
  Goal: model multiple ThermalZone objects inside one Building.
  One nrg3:ThermalZone -> one EnergyPlus Zone.
  Shared zone surfaces must become reciprocal E+ Surface boundary pairs.
  Re-audit PartyWallSurface, IntermediateFloorSurface, AtticFloorSurface, BasementCeilingSurface.

HVAC / schedules / loads
  Goal: use Energy ADE occupancy, schedules, devices, resources after zone geometry is stable.
  Not started yet.

Adjacent buildings / building groups
  Goal: decide how to model buildings that touch each other.
  If one IDF per building: neighboring party walls probably become Adiabatic/OtherSide approximations.
  If grouped IDF: adjacent building surfaces can become real Surface boundary pairs.
  This is different from multizone inside one building and is not implemented yet.
```

---

## 1. Geometry And Surface Mapping

| CityGML / Energy ADE object | Means | Middle layer | EnergyPlus target | Status / evidence |
|---|---|---|---|---|
| `bldg:Building` | Main building object | `building.id`, surfaces, origin | One IDF file per building | [x] `output3` Alderaan: 22 IDFs |
| `bldg:BuildingPart` via `bldg:consistsOfBuildingPart` | Physical part of parent building | Included in parent building surface list | Same parent IDF building | [x] `building_surfaces._building_and_parts()` |
| `bldg:lod1Solid` / raw `gml:Polygon` faces | LoD1 raw solid shell, no thematic surface labels | `type_name="classified"`, role from normal | `BuildingSurface:Detailed` | [x] LoD1 fixtures + box buildings |
| `bldg:boundedBy` -> `WallSurface` | Exterior wall | `role=wall`, `surface_type=Wall`, `boundary=Outdoors` | `BuildingSurface:Detailed` | [x] Alderaan/output3 |
| `bldg:boundedBy` -> `RoofSurface` | Exterior roof | `role=roof`, `surface_type=Roof`, `boundary=Outdoors` | `BuildingSurface:Detailed` | [x] Alderaan/output3 |
| `bldg:boundedBy` -> `GroundSurface` | Ground-contact floor | `role=ground`, `surface_type=Floor`, `boundary=Ground` | `BuildingSurface:Detailed` | [x] Alderaan/output3 |
| 
rg3:ThermalZone` -> 
rg3:thermalBoundary` -> `bldg:_BoundarySurface` | Explicit thermal boundary surface | Surface owned by thermal zone | `BuildingSurface:Detailed` | [x] Alderaan/output3 for one-zone forced audit |
| 
rg3:coincidesWithLod2Hull=true` | Thermal zone equals LoD2 building hull | Use all building shell surfaces, not thermalBoundary list | `BuildingSurface:Detailed` | [x] Hull selection verified with Delft `CoincidesWithLoD2Hull` sample |
| 
rg3:coincidesWithLod3Hull=true` | Thermal zone equals LoD3 building hull/openings | Use building shell/openings instead of duplicate thermal objects | `BuildingSurface:Detailed` + `FenestrationSurface:Detailed` | [x] Target fixture validated; hull + explicit window verified |
| 
rg3:PartyWallSurface` | Party wall between buildings/zones | `role=party_wall`, `surface_type=Wall`, default `Adiabatic` | `BuildingSurface:Detailed` | [~] Built; multizone re-audit later |
| 
rg3:IntermediateFloorSurface` | Horizontal boundary between modelled zones | `FloorOrCeiling`, resolved by normal | `BuildingSurface:Detailed` | [~] Built; multizone re-audit later |
| 
rg3:AtticFloorSurface` | Boundary below unmodelled attic space | `FloorOrCeiling`, default `Adiabatic` | `BuildingSurface:Detailed` | [~] Built; needs targeted case |
| 
rg3:BasementCeilingSurface` | Boundary above unmodelled basement/garage | `FloorOrCeiling`, default `Adiabatic` | `BuildingSurface:Detailed` | [~] Built; needs targeted case |
| `gml:posList` + `srsName` | Coordinates in source CRS | Reproject if geographic, recenter per building | E+ world vertices | [x] Existing reader path |
| `gml:MultiSurface` with multiple `gml:surfaceMember` polygons | One semantic surface represented by several polygons | Split into separate part surfaces, preserving `source_gml_id` | Multiple `BuildingSurface:Detailed` objects | [~] Split tested; overlap/duplicate polygon policy still pending |

Current geometry scope note:

```text
For now, the audited geometry scope is gml:Solid and gml:MultiSurface / gml:Polygon.
Curve-based geometry is not part of the current parser trust target.
MultiSurface with multiple surfaceMember polygons is currently split into separate IDF surfaces,
but overlap/duplicate-area detection is not implemented. This policy needs professor confirmation.
```
### Known Surface Types Not Supported Yet

These are deliberately not active in `semantics/surface_types.py`. If a file uses them, the parser warns/skips instead of guessing.

| CityGML object | Possible meaning | Possible E+ target | Status |
|---|---|---|---|
| `bldg:OuterFloorSurface` | Floor exposed to outdoor air, e.g. overhang underside | `Floor`, `Outdoors` | [!] Decision needed |
| `bldg:OuterCeilingSurface` | Soffit exposed to outdoor air | likely `Roof` or `Ceiling`, `Outdoors` | [!] Decision needed |
| `bldg:FloorSurface` | Interior floor, not ground | `FloorOrCeiling`, `Adiabatic` or interzone | [!] Decision needed |
| `bldg:CeilingSurface` | Interior ceiling | `FloorOrCeiling`, `Adiabatic` or interzone | [!] Decision needed |
| `bldg:InteriorWallSurface` | Interior partition | `Wall`, `Adiabatic`, interzone, or internal mass | [!] Decision needed |
| `bldg:ClosureSurface` | Virtual closing face for open volume | likely skip, no heat transfer | [!] Decision needed |
| `bldg:Room` | CityGML interior room | E+ zone/space candidate | [ ] Not in current scope |
| `bldg:BuildingInstallation` | HVAC/installation geometry | E+ HVAC/equipment maybe | [-] Out of scope now |
| `bldg:IntBuildingInstallation` | Interior installation | E+ HVAC/equipment maybe | [-] Out of scope now |
| `bldg:BuildingFurniture` | Furniture | internal mass maybe | [-] Out of scope now |
| `bldg:Address` | Address metadata | none for IDF | [-] Out of scope now |

---

## 2. LoD Support Matrix

| LoD / Pattern | Energy ADE rule | Parser behavior | Status / test |
|---|---|---|---|
| LoD0 | No geometrical representation of ThermalZones allowed | Detect as LoD0, warn, and skip thermal IDF surfaces; no extrusion/invention | [x] Policy verified with `test_lod0_policy_footprint_only` |
| LoD1 single-zone | One ThermalZone must exist; no thermalBoundary/openings; optional ThermalZone-level LayeredConstruction | Raw solid faces are classified by normal; construction comes from ThermalZone/Building context | [x] Three LoD1 fixtures |
| LoD1 multizone | Multiple ThermalZone solids; no thermalBoundary/openings; interzone faces are coincident solid faces | Needs solid parsing per ThermalZone and coincident-face matching | [ ] Pending |
| LoD2 one-zone | ThermalZone solid and/or thematic/thermal boundary surfaces; no explicit thermal openings | Use thermalBoundary if present, else boundedBy/hull; windows by ratios later | [~] Alderaan/output3; needs focused LoD2 checklist |
| LoD3 one-zone | Thermal boundaries and explicit Window/Door openings allowed | Geometry path built; windows path exists but next audit is pending | [~] Built, recheck after opaque audit |
| LoD4 | ThermalZones/openings cannot use LoD4 geometries in Energy ADE rules | Ignored for current surface-based IDF | [-] Out of scope |

---

## 3. Construction And Material Mapping

| Source object / field | Means | Middle layer | EnergyPlus target | Status / evidence |
|---|---|---|---|---|
| 
rg3:LayeredConstruction` | Construction assembly | `middle["constructions"][name]` | `Construction` | [x] Alderaan + LoD1 fixtures |
| `LayeredConstruction.libraryCode` | External lookup code | Excel key first | Excel layers/materials -> `Construction` | [x] `test_lod1_avg_construction` |
| `LayeredConstruction.layer` | Ordered layer list | `layers` in Energy ADE order | `Construction` layers, reversed by writer for E+ | [x] `test_lod1_inline_layers_construction` |
| 
rg3:Layer.thickness` | Layer thickness | converted to metres | `Material.Thickness` | [x] m/mm/cm conversion path |
| `Layer.material xlink` | Reusable material reference | material id/name | `Material` or `Material:AirGap` | [x] inline fixture |
| 
rg3:SolidMaterial` | Opaque material with mass | material dict | `Material` | [x] CityGML fallback |
| `SolidMaterial.thermalConductivity` | Conductivity | `conductivity` | `Material.Conductivity` W/m-K | [~] Unit tracing still needed |
| `SolidMaterial.density` | Density | `density` | `Material.Density` kg/m3 | [~] Unit tracing still needed |
| `SolidMaterial.specificHeatCapacity` | Specific heat | `specific_heat` | `Material.Specific Heat` J/kg-K | [~] Unit issue found in Alderaan |
| 
rg3:Gas` | Gas / air layer | material dict | `Material:AirGap` if R is m2-K/W | [!] Unit issue: Alderaan `J/K/mol` not directly usable |
| `LayeredConstruction.uValue` | Overall U-value of construction | creates one NoMass material with R=1/U | `Material:NoMass` + `Construction` | [x] `test_lod1_uvalue_construction` |
| 
rg3:ReverseLayeredConstruction` | Same construction but reversed layer order | reversed layers | `Construction` reversed for E+ | [~] Code path exists; needs targeted real sample check |
| Excel `constructions` sheet | External construction database | code -> material list | `Construction` | [x] Excel priority tested |
| Excel `materials` sheet | External material database | material fields | `Material`, `Material:NoMass`, `Material:AirGap` | [x] Excel priority tested |
| Missing construction everywhere | No usable data | `DEFAULT_CONSTRUCTION` | default `Material` + `Construction` | [x] `id_box_building_20` |

### Construction Cascade

For each parsed surface:

```text
1. Candidate owners:
   LoD2/LoD3 BoundarySurface first
   then ThermalZone
   then BuildingPart
   then Building

2. For the first usable LayeredConstruction:
   libraryCode in Excel -> use Excel
   else CityGML Layer -> Material -> use CityGML
   else CityGML uValue -> Material:NoMass with R = 1 / U
   else default
```

Excel lookup policy to implement/check:

```text
Best robust policy: match (codeSpace, libraryCode) when Excel provides both.
Fallback to libraryCode-only matching when Excel has no codeSpace column/value.
Current parser reads and traces codeSpace, but Excel matching policy still needs final audit.
```
Important LoD1 rule:

```text
Raw gml:Polygon solid faces are geometry only.
They do not own layeredConstruction.
For LoD1, construction comes from ThermalZone / Building context.
```

---

## 4. Window Mapping

| Source object / field | Means | Middle layer | EnergyPlus target | Status |
|---|---|---|---|---|
| `bldg:Window` with `lod3MultiSurface` | Explicit LoD3 window geometry | `surface["windows"]` with points | `FenestrationSurface:Detailed` | [~] Built, needs new one-zone audit |
| `bldg:Door` | Door opening | currently ignored as opaque | none | [~] Deliberate approximation |
| 
rg3:bdgBdrySurfOpeningToSurfaceRatio` | Window-to-wall ratio | synthesized window | `FenestrationSurface:Detailed` | [~] Built, needs new one-zone audit |
| `bdgBdrySurfTotalSurfaceArea` + `bdgBdrySurfOpaqueSurfaceArea` | Derive opening ratio | synthesized window | `FenestrationSurface:Detailed` | [~] Built, needs new one-zone audit |
| Excel `windows.u_value` | Window U-factor | default glazing construction | `WindowMaterial:SimpleGlazingSystem.UFactor` | [~] Built |
| Excel `windows.g_value` | Solar gain factor, ADE `gValue` for glazing incl. frame | default glazing construction | `Solar Heat Gain Coefficient` | [x] Map to SHGC for `SimpleGlazingSystem`, range (0, 1) |
| Detailed Energy ADE glazing/gas layer data | Detailed window construction | not yet represented | `WindowMaterial:Glazing`, `WindowMaterial:Gas` | [ ] Pending |

Production rule:

```text
Do not invent windows.
DEFAULT_WWR is test-only and should be None for real parsing.
```

---

## 5. Zone And Multizone Mapping

| Source object / relation | Means | Middle layer | EnergyPlus target | Status |
|---|---|---|---|---|
| 
rg3:ThermalZone` | Thermal zone | `building["zones"]` | `Zone` | [~] Built; re-audit after opaque path |
| `ThermalZone.volume` | Zone volume | `zone["volume"]` | `Zone.Volume` or autocalculate | [~] Built |
| `ThermalZone.thermalBoundary` | Boundary surfaces owned by zone | surface `zone` assignment | `BuildingSurface:Detailed.Zone_Name` | [~] Built |
| Surface owned by two ThermalZones | Interzone boundary | original + reversed partner surface | `Outside Boundary Condition=Surface` pair | [~] Built; re-audit later |
| `PartyWallSurface` between buildings | Adjacent building / party wall | default `Adiabatic` unless two modelled zones own it | `BuildingSurface:Detailed` | [~] Built; needs policy check |
| `IntermediateFloorSurface` | Floor/ceiling between zones | pair if shared by two zones | `Surface` pair | [~] Built |
| `AtticFloorSurface` | Boundary to unmodelled attic | default adiabatic | `BuildingSurface:Detailed` | [~] Needs case |
| `BasementCeilingSurface` | Boundary to unmodelled basement/garage | default adiabatic | `BuildingSurface:Detailed` | [~] Needs case |
| LoD1 multizone solids | Zones defined by solids, no thermalBoundary | not yet matched | `Surface` pairs by coincident faces | [ ] Pending |

---

## 6. Current Test Checklist

### Geometry

```text
[x] LoD1 raw solid -> classified Wall/Roof/Floor faces
[x] LoD2/LoD3 thermalBoundary extraction on Alderaan
[x] Building + nested BuildingParts included in parent IDF
[x] coincidesWithLoD2Hull hull selection: thermalBoundary skipped, bldg:boundedBy used
[x] coincidesWithLoD3Hull hull/opening selection: thermalBoundary skipped, bldg:boundedBy/opening used
[x] LoD metadata detects surface-level lod2/lod3MultiSurface, not only building-level solids
[x] MultiSurface with multiple polygons in one BoundarySurface splits into part surfaces
[ ] MultiSurface overlap/duplicate-area validation: not implemented; ask professor policy first
[x] Interior rings/holes policy: parent uses exterior ring; openings become fenestration
[x] LoD0 policy: detect, warn, skip thermal surfaces; no approximation/extrusion
[ ] Unsupported CityGML surface classes: OuterFloorSurface, InteriorWallSurface, ClosureSurface, etc.
[ ] Complex GML geometry/curves are not fully handled
[ ] Window assignment to split MultiSurface parts still needs later check
```

### Construction + Material

```text
[x] Excel by LayeredConstruction.libraryCode
[x] CityGML inline Layer -> SolidMaterial
[x] CityGML uValue -> Material:NoMass
[x] Default only when no usable construction exists
[x] Energy ADE inside-to-outside stored in middle layer
[x] Writer reverses layers for EnergyPlus outside-to-inside
[x] Alderaan library inventory: MaterialLibrary / LayeredConstructionLibrary / ReverseLayeredConstruction structure parsed
[~] ReverseLayeredConstruction applied to a building surface targeted check
[x] Explain every DEFAULT_CONSTRUCTION with trace reason
[x] Raw value/unit/source tracing for Excel and CityGML material fields
[x] Validate/convert thickness to m
[x] Validate/convert conductivity to W/m-K
[x] Validate/convert density to kg/m3
[x] Validate/convert specificHeat to J/kg-K, with EnergyPlus minimum 100 J/kg-K
[x] Validate/convert uValue to W/m2-K before R = 1/U
[x] Fix Gas.rValue handling when unit is not m2-K/W
[~] Validate Excel required columns and units: trace assumes E+ units; strict validation pending
[ ] Check EnergyPlus maximum construction layer count
[ ] Check Material:AirGap layer-position policy with EnergyPlus/professor
[ ] Decide libraryCode matching: current code matches libraryCode text only; codeSpace is traced
```

### One-Zone Opaque IDF

```text
[x] output3 generated for Alderaan with FORCE_SINGLE_ZONE=True, ENABLE_WINDOWS=False
[x] id_box_building_20 EnergyPlus: rc=0, Severe=0, Fatal=0
[x] test_lod1_inline_building EnergyPlus: rc=0, Severe=0, Fatal=0
[x] test_lod1_uvalue_building EnergyPlus: rc=0, Severe=0, Fatal=0
[x] test_multisurface_building EnergyPlus: rc=0, Severe=0, Fatal=0
[x] id_building_1 EnergyPlus: rc=0, Severe=0, Fatal=0
[ ] Full output3 EnergyPlus batch run
```

### Windows

```text
[~] Explicit LoD3 Window geometry path exists
[~] WWR ratio path exists
[~] total/opaque area ratio path exists
[ ] Re-run one-zone + windows audit after opaque path is trusted
[ ] Detailed glazing/gas materials
[x] ADE gValue maps to EnergyPlus SimpleGlazingSystem SHGC for simple window construction
```

### Multizone

```text
[~] ThermalZone ownership path exists
[~] LoD2/LoD3 thermalBoundary zone ownership exists
[~] EnergyPlus reciprocal Surface pairs exist
[ ] Re-audit PartyWallSurface / IntermediateFloorSurface / AtticFloorSurface / BasementCeilingSurface
[ ] LoD1 multizone: ThermalZone solids + coincident-face matching
[ ] Multibuilding adjacency / party wall policy
```

---

## 7. Output Evidence

```text
citygml2idf/output3/geometry_construction_material/alderaan_geometry_summary.json
citygml2idf/output3/geometry_construction_material/alderaan_middle_layer_opaque_only.json
citygml2idf/output3/geometry_construction_material/alderaan_construction_material_trace.json

citygml2idf/output3/geometry_construction_material/test_lod1_avg_construction_trace.json
citygml2idf/output3/geometry_construction_material/test_lod1_inline_layers_construction_trace.json
citygml2idf/output3/geometry_construction_material/test_lod1_uvalue_construction_trace.json
citygml2idf/test_outputs/output04_alderaan_material_layered_library_inventory/library_inventory.json
citygml2idf/output/runs/id_building_1__1Z_noWin/middle_layer_trace_id_building_1.json
citygml2idf/output/runs/id_building_1__1Z_noWin/middle_layer_idf_id_building_1.json

citygml2idf/output/runs/test_lod3_coincides_building__1Z_noWin/
citygml2idf/output/runs/test_lod3_coincides_building__1Z_Win/
citygml2idf/output/runs/test_multisurface_building__1Z_noWin/
```

Fixture files:

```text
citygml2idf/input/test_lod1_avg_construction.gml
citygml2idf/input/test_lod1_inline_layers_construction.gml
citygml2idf/input/test_lod1_uvalue_construction.gml
citygml2idf/input/test_lod3_coincides_hull.gml
citygml2idf/input/test_multisurface_multiple_polygons.gml
citygml2idf/input/test_lod0_policy_footprint_only.gml
citygml2idf/validation_file/Alderaan_Energy_ADE_Material_Layered_Construction_Libraries.gml
```
