# RULES_code.md — the EnergyPlus rules our CityGML → IDF converter MUST obey

**Scope right now:** geometry, materials, constructions, **multizone/interzone** and
**windows** — the last two are now DECIDED (rules G12–G13 and section W below);
`model/zones.py` and `model/openings.py` are the next code. HVAC + schedules come
later, block by block. **Target:** EnergyPlus 23.1 (vendored IDD =
`templates/Energy+.idd`).

**Why this file exists:** a clean EnergyPlus run only proves the file is *technically*
valid — not that the meaning was mapped right. Each rule below = the EnergyPlus
requirement (with its source) + what our **CityGML** reader/writer must do about it.
We cross-check every rule against the sources, never code E+ rules from memory.

**Sources (authoritative):**
- E+ **Essentials** (overview): https://energyplus.readthedocs.io/en/stable/essentials/essentials.html
- E+ **Input/Output Reference**, v23.1 (BigLadder): https://bigladdersoftware.com/epx/docs/23-1/input-output-reference/
- The vendored **IDD** `templates/Energy+.idd` — the exact schema E+ 23.1 enforces (field names, `\key` choices, required fields). Quoted as `Object:Field`.
- **Energy ADE 3.0** specification **§4.3.1** (modelling `ThermalZone` objects per LoD) + **§4.3.2** (thermal-boundary classes; Fig 22–23; Table 1/2) and the XSDs — the source for the interzone (multizone) rules G12–G13.

---

## 0. Coordinates & units (the foundation for all geometry rules)

- **SI / metres.** Essentials: *"the numeric inputs are in SI units."*
- **Axes X=east, Y=north, Z=up, right-handed.** Essentials: *"The X-axis points
  east, the Y-axis points north, and the Z-axis points up."*
- **CityGML gives us a CRS, not assumptions.** Each geometry/envelope declares an
  `srsName` (e.g. `EPSG:25832` = UTM 32N, metres; or `EPSG:4979` = WGS84 lon/lat,
  degrees). **Read it; convert to metres; never assume.**
  - geographic (degrees) → **reproject** to a metric UTM zone (pyproj);
  - projected (metres, our sample) → **pass through**.
- **Recenter.** UTM coordinates are huge (northing ≈ 5.3e6). Shift the whole site
  so the model's min-corner → (0,0) and the floor → z=0. Required for numerical
  precision and is the `World` convention (a translation — it does not change
  areas, normals or winding).

---

## A. GEOMETRY RULES

### G1 — Metres, SI
Essentials: *"numeric inputs are in SI units."*
→ **Parser:** emit every vertex, length, thickness, area in metres (§0).

### G2 — Right-handed axes: X east, Y north, Z up
Essentials: *"X-axis points east, Y-axis north, Z-axis up."*
→ **Parser:** a projected CityGML `posList` is already (Easting=X, Northing=Y,
height=Z). For a geographic CRS, reproject lon→X, lat→Y; height stays Z.

### G3 — One coordinate system, model near the origin
`GlobalGeometryRules:Coordinate System` = `World` | `Relative` (IDD A3); World =
*"all coordinates … absolute for this facility."* It is a **required, unique** object.
→ **Parser:** emit `GlobalGeometryRules` with `Coordinate System = World`; recenter
so the model sits near (0,0,0) (§0). Origins stay (0,0,0).

### G4 — Vertices: counter-clockwise, viewed from OUTSIDE, starting upper-left
Essentials: *"start with the upper left corner (when viewed from 'outside' the
zone) … counter-clockwise."* IDD `GlobalGeometryRules`: `Starting Vertex Position`
(UpperLeftCorner/…) + `Vertex Entry Direction` (Counterclockwise/Clockwise).
→ **Parser:** orient each ring so its normal points outward (= CCW from outside),
and set `Vertex Entry Direction = Counterclockwise`. (Upper-left start: set
`Starting Vertex Position`, or rely on E+ tolerance — geometry/winding is what matters.)

### G5 — Outward normal points AWAY from the zone (per surface)
The CCW-from-outside rule exists so each surface normal faces the exterior (floor
normal down, roof up, wall sideways-out).
→ **Parser:** Newell normal; flip the ring if it points toward the zone interior
(`geometry.rings.orient_outward` vs the zone/solid centroid). We never trust the
exporter's winding.

### G6 — Surfaces have ZERO geometric thickness
`BuildingSurface:Detailed` is a polygon (vertices only); thickness lives in the
Construction/Material, not the geometry.
→ **Parser:** one `BuildingSurface:Detailed` per CityGML boundary surface, as a
single plane. CityGML `nrg3:bdgBdrySurfThickness` → informs materials, never vertices.

### G7 — A surface needs ≥3 coplanar vertices
`BuildingSurface:Detailed`: `Number of Vertices` `\minimum 3` (IDD N2); all corners
define one plane.
→ **Parser:** validate ≥3 corners + (near-)coplanarity; **warn, never drop** received
geometry (this is a semantic check, lives in `validate/semantic.py`).

### G8 — Every surface needs: Surface Type, Construction, Zone, Outside Boundary Condition, exposure
`BuildingSurface:Detailed` required fields (IDD): `Surface Type` (A2), `Construction
Name` (A3), `Zone Name` (A4), `Outside Boundary Condition` (A6), `Sun Exposure`
(A8), `Wind Exposure` (A9). **`Surface Type` has only 4 keys: `Wall` `Floor`
`Ceiling` `Roof`.** `Outside Boundary Condition` keys include `Outdoors` `Ground`
`Adiabatic` `Surface` `Zone` (+ Foundation/OtherSide/preprocessors).
→ **Parser:** `semantics/surface_types.py` maps each CityGML/ADE boundary class →
role → E+ `Surface_Type` + `Outside_Boundary_Condition`; sun/wind follow the BC
(only `Outdoors` is exposed). The many CityGML/ADE subtypes collapse onto the 4
Surface Types; they differ by the **boundary condition**.

### G9 — One Zone per ThermalZone
A `Zone` *"describes a group of rooms treated as a single thermal entity"*; ceiling
height / floor area / volume auto-calculate when the zone is fully enclosed.
→ **Parser:** one E+ `Zone` per `nrg3:ThermalZone`; attach its surfaces (resolved
via `thermalBoundary` xlinks). No `ThermalZone` in the file → ONE implicit zone =
the whole building. `Multiplier` always = 1.

### G10 — Sub-surfaces (windows/doors) reference a base surface, coplanar, area ≤ base *(deferred)*
`FenestrationSurface:Detailed`: `Building Surface Name` (the host wall), `Surface
Type` ∈ {`Window` `Door` `GlassDoor` `TubularDaylightDome` `TubularDaylightDiffuser`}.
→ **Parser (windows block):** CityGML `bldg:opening` → `Window`/`Door` →
`FenestrationSurface:Detailed` on its host wall, coplanar, area ≤ wall area.

### G11 — Geometry (vertices) is authoritative; stated attributes are only a cross-check
EnergyPlus derives azimuth, tilt, area and height **from the vertices** — it ignores
separately-stated values. So vertices are the single source of truth.
→ **Parser:** build from the reprojected vertices, never from
`nrg3:bdgBdrySurfAzimuth` / `bdgArea` / `bdgHeight`. Use those as an independent
**semantic cross-check** (compute from vertices, compare, warn on mismatch — a
~1° azimuth offset = UTM grid-north vs true-north, expected).

### G12 — Interior/shared surfaces: boundary decided by WHAT IS ON THE OTHER SIDE (zone count), not by the type name
IDD `BuildingSurface:Detailed`: `Outside Boundary Condition` (A6) + `Outside Boundary
Condition Object` (A7) — *"If `Surface`, name of corresponding surface in adjacent
zone … If `Zone`, name of corresponding zone and the program generates the interzone
surface."* `Adiabatic` = no other side (no conduction, but the layers still store/
release heat — thermal mass kept). Energy ADE 3.0 §4.3.2 models these as
`thermalBoundary` objects whose two `thermalBoundaryToThermalZone` links say which
zones a surface separates (Fig 22–23, Table 1/2).
→ **Parser (`model/zones.py`):** for every interior/shared boundary surface
(`nrg3:PartyWallSurface`, `IntermediateFloorSurface`, `AtticFloorSurface`,
`BasementCeilingSurface`, …) decide the boundary by **zone count**, not the type:
- separates **two modelled zones in the SAME building** → **interzone**, written as an
  **explicit reciprocal `Surface` PAIR** (IMPLEMENTED 2026-06-25): the face stays in zone A
  with `Outside Boundary Condition = Surface` → its twin; a reversed twin is added to zone B
  (reversed winding, Floor↔Ceiling flipped, **mirror construction** `<name>_Rev` when
  multi-layer), pointing back. The owner face is re-oriented outward from **its own zone**
  centroid so its Floor/Ceiling label is correct. Both zones end up fully enclosed with a
  real floor. *(The simpler interim `BC=Zone` — E+ auto-generates the partner — is the
  documented fallback; we use the explicit pair for correctness.)*
- faces **another building** (shell / party wall between buildings), OR the building
  is a **single zone**, OR the other zone is **not modelled** → **Adiabatic**.
- an explicit ADE `isAdiabatic` (or equivalent) flag → **Adiabatic wins**.
The **type still sets `Surface_Type`** (Wall, or Floor/Ceiling by the outward normal);
only the **boundary** depends on the zone count. Sun/Wind exposure = NoSun/NoWind for
both `Zone` and `Adiabatic` (only `Outdoors` is exposed, G8). *(Today `surface_types.py`
hard-codes these interior types to `Adiabatic`; G12 moves that decision into
`zones.py`, which knows the zone count. Until `zones.py` exists, Adiabatic stands.)*

### G13 — ThermalZone geometry follows the LoD (Energy ADE 3.0 §4.3.1)
ADE §4.3.1 says how a `ThermalZone`'s volume/surfaces are given at each LoD:
- **LoD1** — zone = a `Solid` (box), **no thematic boundary surfaces**. Multi-zone =
  several solids; an interzone surface is where **two solids' faces coincide**
  geometrically. → **Parser:** classify the solid's faces by normal (G-fallback);
  construction = one averaged/typical assembly per zone; coincident-face matching for
  interzone is `# deferred` (Adiabatic until then).
- **LoD2** — zone bounded by thematic `boundedBy` surfaces, **no holes** (windows are
  WWR ratios on the surface, not cut into the polygon — see W1).
- **LoD3** — surfaces may carry **holes that an opening fills** (explicit `bldg:Window`
  → `FenestrationSurface:Detailed`, W1).
- **`coincidesWithLoDxHull=TRUE`** (ADE §4.3.1, Table 2 cases 5.1/6.1) — a single
  `ThermalZone` whose boundary coincides with the building's LoDx hull **reuses the
  building's `boundedBy` thematic surfaces directly** (no separate thermal boundaries).
  → **`zones.py`:** that one zone **OWNS ALL** the building's `boundedBy` surfaces — do
  **not** trust the `thermalBoundary` list, which may be partial/absent. (This is **B2**:
  flag TRUE, yet `thermalBoundary` lists only 3 of its 8 surfaces → we must use all 8.)
- **LoD4** — interior-room volumes; **out of scope** for our surface-based model (skip).
→ **Parser:** `lod.py` already yields a uniform surface list per building; `zones.py`
groups those surfaces into zones via `nrg3:ThermalZone` + `thermalBoundary`, using the
LoD only to know *where the surfaces live* (hull vs per-zone solid), never to decide a
boundary condition (that is G12).

---

## B. MATERIAL RULES

### M1 — Three opaque material kinds, chosen by what data exists
IDD: `Material` (full mass), `Material:NoMass` (*"only … thermal resistance … such
as insulation"* — R only), `Material:AirGap` (*"an air gap … fixed resistance …
cannot be used for windows"* — R only).
→ **Parser:** `nrg3:SolidMaterial` with conductivity+density+specific-heat+thickness
→ `Material`; a layer with only an R-value → `Material:NoMass`; `nrg3:Gas` / air
cavity with `rValue` → `Material:AirGap`.

### M2 — Material required fields + SI ranges
IDD `Material`: `Name`, `Roughness` (choice: VeryRough/Rough/MediumRough/
MediumSmooth/Smooth/VerySmooth), `Thickness` (m, >0), `Conductivity` (W/m-K, >0),
`Density` (kg/m³, >0), `Specific Heat` (J/kg-K, ≥100). Thermal/Solar/Visible
Absorptance are optional (default 0.9 / 0.7 / 0.7).
→ **Parser:** Energy ADE units are the SAME SI (W/K/m ≡ W/m-K, J/kg/K ≡ J/kg-K) —
DIRECT, no conversion. Fill missing optional fields with defaults; never emit a
`Material` missing a required field — default it (+ warn) or downgrade to `NoMass`.

### M3 — Windows use `WindowMaterial:*`, not opaque materials *(deferred)*
`WindowMaterial:Glazing` + `WindowMaterial:Gas` (detailed panes) or
`WindowMaterial:SimpleGlazingSystem` (U + SHGC only).
→ **Parser (windows block):** opaque material logic is NOT reused for glazing.
`gValue` ≠ SHGC until verified.

---

## C. CONSTRUCTION RULES

### C1 — A Construction is an ORDERED layer list, OUTSIDE → INSIDE
IDD `Construction`: `Outside Layer`, `Layer 2`, `Layer 3`, … (material names in
order, outside to inside).
→ **Parser:** emit layers outside→inside. Excel `layer_order` 1 = outside; CityGML
`nrg3:Layer` document order = outside→inside. Never silently reverse.

### C2 — ONE construction per surface; many materials per construction
`BuildingSurface:Detailed.Construction Name` is a single reference; a `Construction`
itself stacks many material layers.
→ **Parser:** each surface gets exactly one construction reference. **1 surface → 1
construction → N material layers.**

### C3 — Surface references a Construction by unique name
Each surface names exactly one `Construction`; construction names must be unique.
→ **Parser:** keep CityGML construction ids/codes as the unique names (writer-neutral
in the middle layer).

### C4 — Same construction reused → defined ONCE
A construction used on many surfaces is one object referenced many times.
→ **Parser:** dedup — one `Construction` (+ its `Material`s) written once, referenced N times.

### C5 — Construction must resolve to real materials (Excel-FIRST waterfall)
Every layer name in a `Construction` must point to a defined `Material`/`WindowMaterial`.
→ **Parser waterfall:** (1) construction's `libraryCode` is in
`input/construction_db.xlsx` → build from the **Excel**; (2) code missing/unknown →
drill the file's own `nrg3:LayeredConstruction → Layer → SolidMaterial/Gas`; (3)
nothing usable → generic **default + warning**. Never emit a Construction referencing
an undefined material. The Excel is a swappable placeholder (replace the file, change
no code; all its shape lives in `COLUMN_MAP`/`SHEET_NAMES`).

### C6 — Simple glazing when only U & SHGC are known *(deferred)*
`WindowMaterial:SimpleGlazingSystem` — *"If all you have is the U-Factor and Solar
Heat Gain Coefficient (SHGC)."*
→ **Parser (windows block):** a window construction carrying only `uValue`/`gValue`
→ one `SimpleGlazingSystem`; detailed pane+gas layers → `Glazing`+`Gas`.

### C7 — LoD1: an averaged construction attached to the THERMAL ZONE (whole hull)
Energy ADE §4.3.1 (Table 2, Case 1.1/1.2): at LoD1 there are no thematic surfaces, so a
`LayeredConstruction` is associated with the **`ThermalZone`** — one *averaged* set of
physics (a single U/g for the whole hull), applied to **every** surface of that zone.
→ **Parser:** add a **zone-level source** to the C5 waterfall, above the generic default:
surface's own construction → file's inline layers → **zone's `LayeredConstruction`
(LoD1 averaged)** → default. A U-only averaged value → one `Material:NoMass` (R ≈ 1/U)
reused by all the zone's surfaces. *(Our B1 carries none → `#` the code for now, but the
rule stands for any spec-compliant LoD1 file.)*

---

## W. WINDOW RULES (decided — `model/openings.py` is the next code)

These supersede the *(deferred)* notes in G10 / M3 / C6: the rules are now fixed; only
the code is pending. A window is **never invented** — it is emitted only when the
CityGML gives us a source, picked richest→poorest.

### W1 — Window source: one per host wall, richest→poorest fallback
→ **Parser:** for each exterior `WallSurface`, pick the FIRST source that exists:
1. **Explicit geometry** — a `bldg:Window` polygon (LoD3, via `bldg:opening`) →
   `FenestrationSurface:Detailed`, `Surface Type = Window`, on its host wall.
2. **WWR** — `nrg3:bdgBdrySurfOpeningToSurfaceRatio` (window-to-wall ratio).
3. **WWR from areas** — `(totalSurfaceArea − opaqueSurfaceArea) / totalSurfaceArea`.
4. **None** — no source → **opaque wall** (no fenestration). Most buildings hit this.

**Source of W1.4 (this is NOT a quoted E+/ADE clause):**
- *"no source → opaque"* follows the **Energy ADE data model** (§4.3.1, *implied*): at
  LoD3 an opening exists only if modelled; at LoD2 `openingToSurfaceRatio`/areas are
  optional, so when absent `totalSurfaceArea = opaqueSurfaceArea` ⇒ no opening.
- *"a window is **never invented**"* is **our GOLDEN RULE** (project principle — trust
  only data the file contains), **not** an EnergyPlus or Energy ADE rule. EnergyPlus
  says nothing here. This is exactly why `DEFAULT_WWR` (§F) is **test-only**: forcing a
  window where the file gives none would violate this rule.

### W2 — A synthesized window (from a WWR) is inset, coplanar, area = WWR × wall
IDD `FenestrationSurface:Detailed`: `Building Surface Name` (host wall), vertices
coplanar with and inside the host; area ≤ host area (G10).
→ **Parser:** when the source is a ratio (W1.2/W1.3), build a rectangle of
area = `WWR × wall_area`, centred and inset on the host wall, sharing its plane.
NOTE (ADE §4.3.1): an **explicit** LoD3 opening's geometry "might not be coplanar with
the thematic surface it belongs to" — but E+ requires a sub-surface coplanar with its
base, so **project the opening onto the host-wall plane** (or warn + skip) before emitting.

### W3 — Glazing material chosen by the DATA present, never the libraryCode name
IDD: `WindowMaterial:Glazing` + `WindowMaterial:Gas` (detailed panes) **or**
`WindowMaterial:SimpleGlazingSystem` (U + SHGC only) — see C6/M3.
→ **Parser:** real glass panes + `nrg3:Gas` layers → `Glazing` + `Gas`; only a U-value
and g-value → one `SimpleGlazingSystem` (`U-Factor` ← `uValue`). **`gValue` ↔ `SHGC`
is UNVERIFIED — confirm against the Energy ADE spec/UML before mapping; do NOT assume
because the names look alike.** Opaque-material logic (M1/M2) is never reused for glass.

### W4 — Geometry wins over stated WWR
→ **Parser:** if an explicit `bldg:Window` (W1.1) and a stated `…OpeningToSurfaceRatio`
disagree, **trust the geometry**, warn (B3: stated 0.30 vs geometry 0.25). G11 applies
to fenestration too.

### W5 — Doors → opaque for now
→ **Parser:** `bldg:Door` openings are folded into the opaque wall area for now (a
later block can promote them to `FenestrationSurface:Detailed` `Surface Type = Door`).

---

## E. Minimal IDF objects for a valid run (geometry + construction + material, NO HVAC)
The writer builds these into an EMPTY IDF, block by block:
- `Version` (23.1)
- `Building`, `GlobalGeometryRules` (World, Counterclockwise), `Timestep`
- `SimulationControl` + `RunPeriod` (or `SizingPeriod:DesignDay`), `Site:Location`
- one `Zone` per ThermalZone (Multiplier 1)
- one `BuildingSurface:Detailed` per boundary surface (Surface Type, Construction,
  Zone, Outside BC, Sun/Wind)
- each referenced `Construction` (outside→inside) + its `Material` / `Material:AirGap`
- `Output:*` (optional) — e.g. `Output:Surfaces:List`, `Output:Surfaces:Drawing,DXF`
Zones run "free-floating" (no HVAC) — fine for checking geometry/construction; verify
no `** Severe`/`** Fatal` in `eplusout.err`.

---

## F. Testing architecture (step-by-step; save every run to trace bugs)

Professor's method: build + test ONE capability at a time and **save each run's output**,
so a bug is localised — never build everything then test. The parser stays FULL/robust;
three flags in `config.py` only **gate which path runs** for a given test stage:

| Flag | Production | When toggled |
|---|---|---|
| `ENABLE_WINDOWS` | `True` | `False` → `openings.py` skipped, every wall opaque |
| `FORCE_SINGLE_ZONE` | `False` | `True` → ignore `thermalBoundary`, merge the building into ONE hull zone |
| `DEFAULT_WWR` | `None` | float → **test-only** forced WWR when a wall has no window source (else opaque, W1.4) |

**Per-building isolation:** `reader.py` writes `output/middle_layer_<BuildingId>.json`
(one per building); `run.py <BuildingId>` builds + simulates only that building, leaving
its run in `output/idf/run_<BuildingId>/` (`eplusout.err`, `.dxf`). After each stage:
run E+, scan `eplusout.err` for `** Severe`/`** Fatal`, and view the DXF.

**Stages, in order — mark ✅ when its run is clean:**
1. ✅ **1B · 1Z · no window** — `FORCE_SINGLE_ZONE=True, ENABLE_WINDOWS=False` — **B1 + B2 run CLEAN** (exit=0, 0 Severe/Fatal) via `run.py`, each isolated in `output/runs/<id>__1Z_noWin/` (IDF + middle layer + all E+ output). *(2026-06-23)*
2. ✅ **1B · 1Z · window** — `FORCE_SINGLE_ZONE=True, ENABLE_WINDOWS=True` — **B1 with `DEFAULT_WWR=0.3` runs CLEAN** (exit=0, 0 Severe; 4 synthesized windows, real WIN-2PANE glazing) in `output/runs/Building_B1__1Z_Win/`. Explicit-window path also verified: **B3 emits its 2 real `bldg:Window` polygons** (geometry 9 m² wins over stated WWR 0.30; no invented windows elsewhere). B3's single Severe is a *zone-enclosure* error (4 zones collapsed to 1) → deferred to Stage 3. *(2026-06-24, `openings.py`)*
3. ✅ **1B · multizone · no window** — `FORCE_SINGLE_ZONE=False, ENABLE_WINDOWS=False` — **B3 (4 zones) runs CLEAN** (exit=0, 0 Severe) in `output/runs/Building_B3__MZ_noWin/`. `zones.py` walks `nrg3:ThermalZone` (ADE object primary); 4 shared surfaces become **explicit reciprocal Surface pairs** (reversed twin, Floor↔Ceiling flipped, owner re-oriented to its own zone). `PartyWall` correctly interzone by **zone count** (G12), not its name. Residual 2 warnings = the sample's geometrically inconsistent PartyWall (5th wall on a 4-wall box, faithfully kept) + 1 = no-outputs (design-day). *(2026-06-25, `zones.py`)*
4. ✅ **1B · multizone · window** — `FORCE_SINGLE_ZONE=False, ENABLE_WINDOWS=True` — **B3 runs CLEAN** (exit=0, 0 Severe; 4 zones + 4 interzone pairs + 2 real windows) in `output/runs/Building_B3__MZ_Win/`. Zones and windows compose with no new code. *(2026-06-25)*
5. ✅ **multi-building** — `python -m citygml2idf.run` (no arg) → **B1 + B2 + B3 all run CLEAN** (exit=0, 0 Severe each), one IDF + own folder each under `output/runs/<id>__MZ_Win/`. *(2026-06-25)*

**Build order to unlock the stages:** `config.py` → `openings.py` (unlocks 2) → `zones.py`
(unlocks 3) → both together (4) → run-all (5).

---

## Quick mapping table (CityGML / Energy ADE → EnergyPlus)

| CityGML / Energy ADE | EnergyPlus | Rule |
|---|---|---|
| `posList` vertices (CRS from `srsName`) | reprojected, recentred metric vertices | G1–G3 |
| boundary ring | one `BuildingSurface:Detailed` | G4–G7 |
| `bldg:WallSurface` / `RoofSurface` | Wall / Roof, `Outdoors` | G8 |
| `bldg:GroundSurface` | Floor, `Ground` | G8 |
| `nrg3:PartyWallSurface` / interior ADE surfaces | Wall/Floor/Ceiling; `Adiabatic` (shell / 1-zone) or `Zone` (interzone: 2 zones, same building) | G8, **G12** |
| `nrg3:ThermalZone` (geometry varies by LoD) | one `Zone` | G9, **G13** |
| `bldg:Window` (explicit) → else `…OpeningToSurfaceRatio` → else area-WWR | `FenestrationSurface:Detailed` (Window) | G10, **W1–W2** |
| `bldg:Door` *(later)* | opaque wall for now | **W5** |
| `nrg3:SolidMaterial` | `Material` | M1, M2 |
| layer R-value only | `Material:NoMass` | M1 |
| `nrg3:Gas` / air cavity `rValue` | `Material:AirGap` | M1 |
| `nrg3:LayeredConstruction` (id/`libraryCode`) | `Construction` (outside→inside) | C1–C5 |
| window `uValue`/`gValue` | `WindowMaterial:SimpleGlazingSystem` (g↔SHGC unverified) | C6, **W3** |
| window glass panes + `nrg3:Gas` | `WindowMaterial:Glazing` + `WindowMaterial:Gas` | M3, **W3** |
