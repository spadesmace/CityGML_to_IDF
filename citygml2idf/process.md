# citygml2idf — Process Log

A dated record of every working session on the **CityGML 2.0 + Energy ADE 3.0 →
EnergyPlus IDF** converter: the decisions, what we built, a one-line description
of each code file, the EnergyPlus-rules status, and the next steps. **Append a new
dated entry every session** — this is the thesis-report source.

> The old `process_update.md` in this folder is the previous **CityJSON** module's
> history, kept for reference only. This `process.md` is the CityGML log.

---

## 2026-06-22 — Session 1 · Pivot to CityGML + parser foundation + geometry

### Why / decision
Switched the approach from **CityJSON** to **CityGML 2.0 + Energy ADE 3.0**:
CityGML is more accurate and far easier to validate (real XSD schemas exist). The
project AIM is unchanged — building data → EnergyPlus IDF. We copied the whole
`cityjson2idf/` module to `citygml2idf/` (original untouched) and swapped the
input to `sample_energyADE.gml`.

### What we did (process)
1. Copied `cityjson2idf` → `citygml2idf`; removed the CityJSON inputs; put
   `sample_energyADE.gml` in `input/`.
2. Chose the parsing library: **lxml + pyproj** (added `lxml` to requirements.txt).
3. Built `citygml/xml_io.py` — the only file that touches lxml. Proven on the
   sample: 3 buildings, LOD detection, 144 `gml:id`s indexed, xlink + posList work.
4. Added an **optional XSD validation gate** (Layer A) — best-effort: validates
   against `Energy_ADE_3.0_beta7.xsd`, warns and continues if it cannot (offline).
   The sample **PASSES** validation.
5. Agreed the **golden rule**: trust only structure + geometry + explicit xlinks;
   never names / comments / `libraryCode` strings / stated numbers.
6. Agreed the **file structure** (one duty per folder) and wrote
   `PARSING_OVERVIEW.md` (the plan) for review.
7. Built `geometry/` (pure math): `rings.py`, `crs.py`, `classify.py`. **Verified
   on real data** — B1 (LOD1, no labels) classified by normal (ground/roof/walls,
   areas 80/80/60/48); B2 (LOD2) areas read from labeled surfaces (L-footprint 88,
   wall1 84). Roles are derived from geometry when the file does not label them.

### Code map (what each file does, short)
| File | Does |
|---|---|
| `citygml/xml_io.py` | load the .gml; match elements by namespace URI; `gml:id`→element registry; resolve `xlink`; read `posList`; optional XSD gate |
| `geometry/rings.py` | per polygon: drop closing point, Newell normal, true 3D area, orient ring so its normal points outward |
| `geometry/crs.py` | read EPSG; reproject to metres if geographic (else no-op); recenter min-corner→origin, floor z=0 |
| `geometry/classify.py` | role from the outward normal (up→roof, down→ground, sideways→wall) — the LOD1 fallback |

### EnergyPlus rules (RULES_code.md) — geometry status
- **Followed:** G1 (X=E,Y=N,Z=up), G2 (SI metres), G3 (metric + recenter), G5
  (outward normal away from zone), G6 (zero-thickness planes), G12 (geometry is
  authoritative; stated attrs only cross-checked).
- **G4 winding:** outward/CCW done; "upper-left start" = a writer-time
  `GlobalGeometryRules` detail (later).
- **G7** (≥3 corners + coplanar): **deferred to `validate/semantic.py`**, policy =
  **WARN-and-keep** — we never drop geometry the CityGML gave us.
- **G8** (boundary conditions): next piece (`surface_types.py`).
- RULES_code.md itself still uses CityJSON wording (transform/semantics/EPSG:4979)
  → to be refreshed for CityGML when we build `surface_types.py`.

### Sample gotchas discovered (why SEMANTIC validation matters)
- B3 stated WWR `0.30` ≠ geometry `9/36 = 0.25` (0.367 with the door).
- A comment says "two thermal zones"; B3 actually has **4** (+1 in B2 = 5 total).
- `LIB_WindowConstruction` is referenced by no window → don't assume the link.
- `WIN-2PANE` has only one air-gap layer → don't invent glass panes from the name.

### Decisions locked
- `lod.py` = its own module (translator: LOD → uniform surface list).
- Semantic mismatch → **warn and trust geometry**.
- Interzone / shared surfaces → **Adiabatic** for now.
- Doors → opaque wall area for now (many buildings have none — fallback handles it).

### Next
- `semantics/surface_types.py` — full CityGML/ADE type → role → EnergyPlus
  `Surface_Type` + boundary condition, **built from the XSD** (covers types our 3
  buildings don't use). Refresh RULES_code G8/G13 wording for CityGML here.
- then `semantics/lod.py`, then `model/reader.py` → `output/middle_layer.json`.

---

## 2026-06-23 — Session 2 · semantics/surface_types, cleanup, Excel DB rebuilt

### What we did (process)
1. Built `semantics/surface_types.py` — the CityGML/ADE surface type → role → E+
   `Surface_Type` + boundary table. All 13 boundary classes listed; 7 active
   (Wall/Roof/Ground/PartyWall + Intermediate/Attic/Basement-Ceiling), 6 commented
   out + named (ClosureSurface, FloorSurface, OuterFloor/Ceiling, InteriorWall,
   CeilingSurface) so we return here to decide them. Verified against the EnergyPlus
   23.1 IDD: `Surface Type` ∈ {Floor,Wall,Ceiling,Roof}; full `Outside Boundary
   Condition` list kept as `EPLUS_BOUNDARY_CONDITIONS`.
2. Renamed vague defs for clarity: `qn→qualified_name`, `CityGMLDoc.resolve→
   resolve_xlink`, `area→polygon_area`, `rule_for→rule_for_type`, `sun_wind→
   sun_wind_exposure`.
3. Deleted the CityJSON leftovers `reader.py`/`constructions.py`/`run.py` (the new
   split replaces them). Kept `writer.py` as a broken eppy reference (delete when
   `write/writer.py` is built) and `idf_building_visualize.py` (reusable, no deps).
   `xml_io.py` moved into `citygml/` (user) — paths fixed via `_PKG`.
4. **Excel DB rebuilt** `input/construction_db.xlsx` from the user's
   `ASHRAE_2005_HOF_Materials.idf`: 5 real materials (M01 brick, I02 insulation,
   G01a gypsum, M11 lwt concrete, F16 acoustic tile) + 3 constructions keyed on our
   CityGML codes (`WALL-EXT-2015`, `ROOF-FLAT-2015`, `FLOOR-GND-2015`) + window
   `WIN-2PANE` (U 1.1, g 0.6). Old TABULA/CityJSON rows discarded.
5. **Edited the CityGML** (one building): added an inline `nrg3:layeredConstruction`
   to `B2_Wall1` with code `WALL-1960-IT` (NOT in Excel) → forces the inline
   fallback. Re-validated against the XSD: **PASSED** (147 gml:ids).

### The construction/material waterfall is now testable across all 3 branches
- **B3** wall `WALL-EXT-2015` (in Excel) → **EXCEL-FIRST**.
- **B2** wall `WALL-1960-IT` (not in Excel, has inline brick layer) → **INLINE FALLBACK**.
- **B1** no construction → **DEFAULT + warn**.

### EnergyPlus mapping confirmed (IDD-verified, for the writer)
- `BuildingSurface:Detailed` requires `Construction Name`; `Construction` = ordered
  material names outside→inside; `Material` requires Name, Roughness(6 choices),
  Thickness, Conductivity, Density, Specific Heat (absorptances default). Excel
  columns map DIRECT. `Gas`/air-gap → `Material:AirGap` (R-value).

### Build order agreed (envelope first, test after each block)
geometry → **constructions+materials** → test E+ run (NO windows) → then windows →
then HVAC. Each building's geometry + construction + material is written into
`middle_layer.json` (the firewall) before the writer builds the IDF.

### `semantics/lod.py` built + verified (geometry slice)
Per building → uniform surface list `{source_id, type_name, role, surface_type,
boundary, points}`. LOD2/3 = labeled `boundedBy` (role from type); LOD1 = solid
faces classified by outward normal. Reference-tolerant (inline OR xlink surfaces).
Verified areas on all 3 buildings (B1 box 80/80/60/48, B2 L-shape, B3 gabled incl.
pitched roofs 12·√29=64.6, gables 10). Interior interfaces resolve via normal:
BasementCeiling→Floor, Intermediate/Attic→Ceiling, all Adiabatic.

⚠️ BUG FOUND + FIXED (general, not data): `geometry/rings.drop_closing_point` used
`np.allclose` with its default RELATIVE tol (rtol=1e-5). On large UTM coords (our
northing 5.3e6) that tol is ~50 m, so it wrongly treated distinct corners as the
closing duplicate and collapsed polygons (b1_roof 80→40, a gable →0). Fixed to an
ABSOLUTE tol (`rtol=0, atol=1e-6`). This would hit ANY UTM CityGML — caught by the
area sanity-check, NOT by EnergyPlus (a triangle is still "valid"). Lesson logged:
semantic/number checks per step are essential; the CityGML was correct, the code
wasn't.

### `model/reader.py` built + verified — GEOMETRY MIDDLE LAYER done
Per building → `lod.surfaces_of_building` → reproject if geographic (no-op for our
UTM sample) → **recenter EACH building to its own origin** (min-corner→0,0; floor
z=0; one IDF per building) → `output/middle_layer.json`. Records per surface
{source_id, type_name, role, surface_type, boundary, points, area}; per building
{id, lod, origin_offset (site position), surfaces}; + crs metadata. Verified:
envelopes B1=376, B2=470, B3=1063 m²; b1_ground recentred to (0,0,0)…(10,8,0).

### Coordinate concepts pinned down (RULES_code §0)
We RECEIVE EPSG:25832 (UTM 32N) = already metres → no reproject, only recenter.
A WGS84/4979 (degrees) file would reproject to UTM first. Code reads `srsName` and
adapts; never assumes the CRS. E+ wants SI metres + X-east/Y-north/Z-up (Essentials).

### Docs rewritten this session
- **RULES_code.md** — fully rewritten from E+ sources (Essentials + IDD + BigLadder),
  CityGML-only (removed all CityJSON transform/semantics/+Energy- leftovers). Each
  geometry/material/construction rule cites its source; added §0 coordinates and §D
  minimal-IDF-for-a-run skeleton.
- **MAPPING.md** — created in the team format: Source(class·namespace) · Meaning ·
  E+ target · Type(DIRECT/CONVERTED/APPROX/DEFAULTED/UNSUPPORTED) · Verified. Settled
  geometry/material/construction rows ✓ vs IDD; open rows flagged for the teammate
  (interzone, undecided surface subtypes, layer direction, and windows — esp.
  **gValue ≠ SHGC until verified vs ADE Spec**). Rule: nothing mapped on the fly.

### `model/constructions.py` built + verified — the LIBRARIAN waterfall
Per surface: (1) `libraryCode` in Excel → build from Excel; (2) else drill the file's
own `LayeredConstruction/Layer/SolidMaterial|Gas`; (3) else DEFAULT + warn. Dedup.
Handles all 3 E+ material objects, chosen by SOURCE: `SolidMaterial`→`Material`,
`Gas`→`Material:AirGap`, Excel `material_type`→ also `Material:NoMass` (ADE has no
native NoMass). Verified: B3 wall `WALL-EXT-2015`→EXCEL (brick+AirGap+insul+gypsum),
B2 wall `WALL-1960-IT`→INLINE (file's brick), B1→DEFAULT; all 3 material objects emit.
Wired into `reader.py` → middle_layer.json now has `constructions` + `materials` +
each surface tagged `construction`. Archetype rung 2b (GeoJSON year/use→construction
brain) reserved as a COMMENT in constructions.py — EPC enrichment is much later.

### Excel rebuilt with all 3 material kinds
`material_type` column drives the E+ object: `Material` (brick/insulation/gypsum/
concrete/acoustic tile) + `Material:AirGap` (F04/F05 air spaces) + `Material:NoMass`
(carpet/cork). Used in the constructions (cavity wall, carpeted floor).

### `write/writer.py` built — FIRST END-TO-END E+ RUN ✅
Empty IDF, block by block (eppy): settings → Material/NoMass/AirGap → Construction →
Zone → BuildingSurface:Detailed (uses each surface's Surface_Type/boundary/construction
straight from the middle layer; sun/wind from boundary). **ONE zone per building for
now** (simplest rung; multi-zone via thermalBoundary = next). **Building_B1 runs CLEAN
in EnergyPlus 23.1: exit=0, 0 Severe/Fatal**, 1 benign warning. DXF + PNG produced.
Visualizer `idf_building_visualize.py` updated to the new middle-layer format (B1 = a
correct 10×8×6 box).

### IDF is complete + weather is MODULAR
`new_empty_idf(with_weather)` driven by `weather_available()` (= `WEATHER_EPW` set AND
file exists). WEATHER_EPW=None → design-day-only IDF: NO `RunPeriod`, NO result outputs
(verified absent), SimulationControl weather-run=No; run with `--design-day`. Uncomment
`WEATHER_EPW` (`templates/weather.epw`) → adds `RunPeriod` (fields verified vs IDD line
1391) + `Output:Table:SummaryReports`/`Output:Variable`/`Output:VariableDictionary` +
runs `--weather`. Design days + DXF + diagnostics are always present.

### Professor's modeling LADDER (simple→complex) — we are on rung 1
1B·1Z·noWindow (✅ B1) → 1B·2Z·noWindow → 1B·1Z·window → 1B·2Z·window → multi-building.
Each rung = enable one more module (zones.py, then openings.py). Our one file's 3
buildings span the ladder; per-building fallbacks pick the right path. Code modular by
design (one decision point per concern). Self-test: EP-Launch (input IDF, weather
`<none>` or weather.epw) + sharecad.org for the DXF.

### Next
- **B2** — run it (also 1 zone, no window) to confirm rung 1 on the L-shaped LOD2.
- `model/zones.py` — split a building into N zones via `nrg3:ThermalZone` + `thermalBoundary`
  (interzone surfaces = Adiabatic for now) → rung 2 (B3's 4 real zones).
- `model/openings.py` — windows (explicit `Window` geom → WWR → none); decide gValue↔SHGC.

---

## 2026-06-24 — Session 3 · DECIDED the multizone (interzone) + window logic; docs synced

### Why / decision
Before coding `model/zones.py` and `model/openings.py` we pinned down the two hardest
design questions against the sources, so the code has a rulebook to follow: how to
treat SHARED surfaces between zones (multizone/interzone) and how to place WINDOWS.
**No runtime code changed this session** — this is decisions + documentation (the
thesis-report record). Sources used: E+ IDD `BuildingSurface:Detailed` A6/A7 (Outside
Boundary Condition + Object); Energy ADE 3.0 spec **§4.3.1** (ThermalZone modelling per
LoD) + **§4.3.2** (thermal-boundary classes, Fig 22–23, Table 1/2).

### Multizone / interzone — DECIDED
- **One E+ `Zone` per `nrg3:ThermalZone`** (G9). No `ThermalZone` → one implicit zone =
  whole building.
- **An interior/shared surface's boundary is decided by WHAT IS ON THE OTHER SIDE =
  zone count, NOT the surface's type name:**
  - two modelled zones, **same building** → **interzone**, `Outside Boundary Condition =
    Zone` (E+ auto-generates the partner surface + reverses its layer order). *(interim
    method; explicit reciprocal `Surface` pair = later upgrade.)*
  - faces **another building** (shell / party wall between buildings), or the building is
    a **single zone**, or the other zone **isn't modelled** → **Adiabatic** (no
    conduction, still carries thermal mass).
  - explicit ADE `isAdiabatic` flag → **Adiabatic wins**.
- **Same rule for PartyWall / IntermediateFloor / AtticFloor / BasementCeiling:** the
  TYPE sets `Surface_Type` (Wall, or Floor/Ceiling by the outward normal); the ZONE COUNT
  sets the boundary. *(Correction made this session: a party wall between two zones of one
  building is interzone, NOT always Adiabatic — only a party wall against the shell /
  another building is Adiabatic.)*
- **Method:** `Zone` now (simplest; avoids reversed-construction bookkeeping). Modular —
  switching to `Surface` pairs later is local to `zones.py`.
- **LoD rules (§4.3.1):** LoD1 = solids, no thematic faces (interzone = geometrically
  coincident faces, **deferred**; averaged construction per zone); LoD2 = no holes; LoD3 =
  holes filled by openings; **`coincidesWithLoDxHull`** = a single zone reuses the
  building hull's `boundedBy` directly (**B2's case**); LoD4 = out of scope.

### Windows — DECIDED
- **One source per host wall, richest→poorest, never invent:** (1) explicit `bldg:Window`
  geometry → `FenestrationSurface:Detailed`; (2) WWR `nrg3:bdgBdrySurfOpeningToSurfaceRatio`;
  (3) WWR `(totalSurfaceArea − opaqueSurfaceArea) / totalSurfaceArea`; (4) none (opaque).
  A synthesized window = `WWR × wall area`, inset, coplanar, area ≤ wall.
- **Glazing material by the DATA present (never the `libraryCode` name):** glass panes +
  `nrg3:Gas` → `WindowMaterial:Glazing` + `WindowMaterial:Gas`; only U + g →
  `WindowMaterial:SimpleGlazingSystem`. **`gValue` ↔ `SHGC` is UNVERIFIED — confirm vs the
  ADE spec before mapping.**
- **Geometry wins over a stated WWR** (B3: stated 0.30 vs geometry 0.25 → trust geometry,
  warn). Doors → opaque wall for now.

### What we did (docs)
- **RULES_code.md** — added **G12** (interzone boundary by zone count, with the IDD A6/A7
  quote), **G13** (LoD-specific ThermalZone modelling, §4.3.1), and a new **section W
  (W1–W5)** for windows. Updated the scope line, added the Energy ADE §4.3.1–4.3.2 source,
  and refreshed the quick mapping table.
- **CLAUDE.md** — Subsystem 2 is now `citygml2idf` (the active module): real folder
  structure, golden rule, the two link mechanisms (CityGML parent-child vs ADE by-id), the
  modeling ladder, and the DECIDED multizone + window logic. Marked `cityjson2idf` as the
  superseded prior iteration; fixed commands (no `run.py`; `write/writer.py:main`
  orchestrates).

### Code state (unchanged)
`model/zones.py` and `model/openings.py` do **not exist yet** — these decisions are the
rulebook they will implement. `surface_types.py` still hard-codes the interior ADE types
to `Adiabatic`; **G12 moves that decision into `zones.py`** (which knows the zone count) —
until then Adiabatic stands. Only `Building_B1.idf` is built + confirmed clean; **B2 is the
same rung, still to confirm** (not overstated). **MAPPING.md** still shows the old
"Adiabatic now / Surface later" wording on the interzone + window rows → sync it to G12/W
when convenient (flagged, not yet edited).

### Next
- Build `model/zones.py` — group surfaces into zones via `nrg3:ThermalZone` +
  `thermalBoundary`; apply **G12** (interzone = `Zone`, else Adiabatic) → rung 2 (B3's 4 zones).
- Build `model/openings.py` — **W1–W5** (explicit Window → WWR → none); verify gValue↔SHGC first.
- Confirm **B2** runs clean (rung 1, L-shaped LoD2) via EP-Launch.
- Sync **MAPPING.md** interzone + window rows to the new rules.

## 2026-06-24 — Session 4 · Test harness (run.py) + windows (openings.py); Stages 1 & 2 ✅

### Why / decision
Implement the professor's **step-by-step testing method**: build + test ONE rung at a
time, and keep a SEPARATE, self-contained EnergyPlus output folder per test so each run
can be visualised and analysed independently. Then code the first deferred module,
**windows** (`model/openings.py`), and confirm the ladder up through Stage 2.

### What we did
- **`config.py`** — three TEST flags that only *gate* which path runs (the parser stays
  full + robust): `ENABLE_WINDOWS`, `FORCE_SINGLE_ZONE`, `DEFAULT_WWR`. Production =
  `True / False / None` (never invent a window, W1.4).
- **`run.py`** (recreated as the per-building harness) — `python -m citygml2idf.run
  [BuildingId]`. Each test lands in its OWN folder `output/runs/<id>__<zone>_<win>/`
  (e.g. `Building_B1__1Z_Win`) holding the **IDF + per-building `middle_layer_<id>.json`
  + ALL EnergyPlus output** (`.err`, `.dxf`, `.eio`, …). The `<zone>_<win>` tag comes from
  the flags, so different stages never overwrite each other. `run_energyplus` gained an
  `out_dir` argument so E+ writes into that folder.
- **`model/openings.py`** (NEW) — the **W1 cascade**, gated by `ENABLE_WINDOWS`:
  explicit `bldg:Window` geometry → `openingToSurfaceRatio` → `(total−opaque)/total` →
  `DEFAULT_WWR` (test-only) → opaque. `synthesize_window` makes a coplanar window of
  area = WWR × wall by scaling the wall ring about its centre by √WWR. Glazing = one
  default `SimpleGlazingSystem` from the Excel `windows` sheet (U ← u_value, SHGC ←
  g_value — **g↔SHGC still UNVERIFIED**, W3). Wired into `reader.py` (after constructions)
  and `writer.py` (`WindowMaterial:SimpleGlazingSystem` + `Construction` +
  `FenestrationSurface:Detailed`, IDD-verified: ≤4 vertices).
- **`constructions.py`** — added `u_value`/`g_value` to `COLUMN_MAP` (the windows sheet
  was unreadable → had been falling back to default glazing; now uses real WIN-2PANE).

### Tested (each its own kept folder)
- **Stage 1 ✅ (1B·1Z·no window):** B1 + B2 — `exit=0`, 0 Severe/Fatal.
- **Stage 2 ✅ (1B·1Z·window):** B1 with `DEFAULT_WWR=0.3` — `exit=0`, 0 Severe, 4
  synthesized windows, real **WIN-2PANE** glazing (U=1.1, SHGC=0.6). Explicit path
  verified on **B3**: emits its **2 real `bldg:Window`** polygons (geometry 9 m² wins over
  stated WWR 0.30; nothing invented elsewhere). B3's lone Severe is a *zone-enclosure*
  error from collapsing its 4 zones into 1 — **not** a window bug → fixed by Stage 3.

### Code state
`model/zones.py` still does **not exist** — `FORCE_SINGLE_ZONE` is displayed/tagged but the
writer is currently *always* single-zone until `zones.py` lands. `openings.py` is done and
verified. B3 cannot run clean as a single zone (it is genuinely 4 zones).

### Next
- Build `model/zones.py` — one E+ `Zone` per `nrg3:ThermalZone`; **G12** interzone (`BC=Zone`)
  vs Adiabatic by zone count; **G13** `coincidesWithLoDxHull`. Then Stage 3 (B3, 4 zones).
- Stage 4 (B3 multizone + windows), Stage 5 (all three buildings).
- Sync **MAPPING.md** window + interzone rows.

## 2026-06-25 — Session 5 · Parser audit (data-driven vs LOD) + multizone `zones.py`; Stage 3 ✅

### Why / decision
Before coding zones, the student asked the key architecture question: **is the parser
data-driven or LOD-driven?** We audited the actual extraction code and confirmed:
extraction is **data-driven + presence-based** — geometry branches on *"are labeled
`bldg:boundedBy` surfaces present?"* ([lod.py:83]) not on the LOD integer (`detect_lod` is
recorded for info only); construction/material/window all follow ID/reference → resolve →
graceful-missing. BUT we found a real GAP: the **primary Energy ADE object**
(`nrg3:ThermalZone` / `ThermalBoundary`) was **not parsed at all** — we read ADE attributes
that happen to sit on the bldg surface. **Decision (student): ADE object PRIMARY** — walk
`nrg3:ThermalZone`, with the bldg geometry as the shape it links to.

Inspecting the sample proved the structure: `nrg3:thermalBoundary` **xlinks straight to the
bldg surface id**; a surface referenced by **two** zones = interzone *by count* (G12),
regardless of the type name (`B3_PartyWall` is shared by Ground+Upper → interzone, not
adiabatic). B2's zone has `coincidesWithLod2Hull=true` → owns the whole shell (G13). Zones
carry `nrg3:volume` (B2 = 680 m³) → E+ Zone Volume.

### What we did
- **`model/zones.py`** (NEW) — ADE-object-primary, presence-driven. One E+ `Zone` per
  `nrg3:ThermalZone` (or one implicit zone when none / `FORCE_SINGLE_ZONE`). A zone owns a
  surface via its `thermalBoundary` xlink, or the whole shell if `coincidesWithHull` (G13).
  Boundary by **zone count** (G12). Wired into `reader.py` after openings; `writer.add_building`
  refactored to emit **one Zone per `building['zones']`** and place each surface in
  `surface['zone']` with its decided boundary (full readable names; per-`def` comments cite
  G12/G13/ADE §4.3.1-2).
- **Interzone = explicit reciprocal `Surface` PAIR** (the student chose the robust upgrade
  over interim `BC=Zone`): the shared face stays in zone A (`BC=Surface`→twin); a reversed
  twin is added to zone B (reversed winding, Floor↔Ceiling flipped, mirror construction
  `<name>_Rev` when multi-layer). The owner face is **re-oriented outward from its own zone**
  centroid so Floor/Ceiling is correct (basement's top = Ceiling, ground's bottom = Floor).

### Tested (Stage 3, its own kept folder)
- **Stage 3 ✅ (1B·multizone·noWindow):** B3 = **4 zones**, 4 interzone pairs (25 surfaces),
  `exit=0`, **0 Severe**, in `output/runs/Building_B3__MZ_noWin/`. Explicit pairs cut warnings
  **7 → 3**; the floor/ceiling, volume-mismatch and "no floor in Ground" warnings are gone.
  Remaining 3 = 2× "not fully enclosed" (Ground/Upper — the sample's geometrically
  inconsistent PartyWall, faithfully kept, never dropped) + 1× no-outputs (design-day).
  Verified the reciprocal pair in the IDF (both sides `BC=Surface`, Ceiling↔Floor).

### Docs
RULES_code §F Stage 3 ✅; **G12** updated (explicit Surface pair now IMPLEMENTED, interim
`BC=Zone` = documented fallback). run.py stale "zones not built" note removed.

### Stages 4 & 5 ✅ (same session — no new code, just flags)
- **Stage 4 ✅ (1B·multizone·window):** B3 `MZ_Win` — 4 zones + 4 interzone pairs + 2 real
  windows, `exit=0`, 0 Severe. Zones and windows compose cleanly.
- **Stage 5 ✅ (multi-building):** `python -m citygml2idf.run` (no arg) — **B1 + B2 + B3 all
  run CLEAN** (0 Severe each), one IDF + own folder each. **The professor's full ladder is
  climbed (1B1Z → 1B2Z → window → multizone → multi-building).**

### Next
- Sync **MAPPING.md** zone/interzone + window rows to G12/G13/W (docs only).
- Loads/HVAC: `nrg3:volume`/`area`, `infiltrationRate`, `isHeated/isCooled`, usage zones are
  parsed-but-unused → `ZoneInfiltration`, ideal-loads, schedules (next modelling layer).
- Open data note: the sample PartyWall is referenced by two stacked zones (nonsensical) →
  the 2 residual enclosure warnings; real data would make it a true between-buildings wall.

## 2026-06-25 — Session 6 · Teaching pass + schema-checked construction paths; classify rewrite; docs de-staled

### Why / decision
A deep teaching/review pass with the student on the geometry + construction layers, ending
in concrete, verified test data. **No parser logic changed** — only docs, comments, and the
sample `.gml` test fixtures. Everything below was checked against the **actual XSD**
(`validation_file/Energy_ADE_3.0_beta7.xsd`) + the **real GML**, not from memory.

### Schema finding that corrected a wrong assumption
Investigated "construction attached to a `nrg3:ThermalBoundary` object" (proposed "Pattern B").
**There is NO `nrg3:ThermalBoundary` element in Energy ADE 3.0 beta7.** Confirmed in the XSD:
`ThermalZone.thermalBoundary` is typed **`bldg:BoundarySurfacePropertyType`** (line 1563,
relation = composition) — a thermal boundary IS a `bldg` boundary surface; and
`layeredConstruction` is a **`_GenericApplicationPropertyOfCityObject`** (line 1087) that hangs
on the surface (the CityObject). So construction attaches to the surface (inline OR `xlink`),
never to a separate boundary object. The parser already handles both → **no "Pattern B" fix
needed** (that was an Energy ADE 2.0 idea). The GML confirms it: `nrg3:thermalBoundary` xlinks
from the ThermalZone to bldg surface ids (the zone-ownership link `zones.py` already reads;
B3 → 4 zones). Two distinct links, kept separate: **thermalBoundary = zone↔surface ownership;
layeredConstruction = surface→physics.**

### Material "bug" resolved (it wasn't one)
Walked the two-level model on real numbers (construction → layers → materials). Confirmed the
waterfall already matches the intended rule: **code in Excel → take everything from Excel
(layers + materials), no CityGML; code not in Excel → drill the file's own layers; nothing →
default**. The only "material → default" case is an *Excel-internal inconsistency* (a
construction lists a material missing from the materials sheet) → correct behaviour is keep
default **+ loud warning** (per the rule "Excel is authoritative when matched"); never pull
from the GML (Excel names ≠ gml ids). No id-mapping, no code change.

### Test data edited (sample `.gml` only — to exercise every branch on purpose)
- **B2 made fully Excel-backed** (zero defaults): `B2_GroundSurface`→`FLOOR-GND-2015`,
  `B2_Wall1..6`→`WALL-EXT-2015`, `B2_RoofSurface`→`ROOF-FLAT-2015` (all by `libraryCode`).
- **Shared construction by reference:** `B2_Wall2` + `B2_Wall3` carry **only**
  `<nrg3:layeredConstruction xlink:href="#B2_Con_Wall1"/>` → parser follows the xlink and
  resolves them to `WALL-EXT-2015` (proves shared/dedup reference resolution, the realistic
  "construction library" pattern).
- **File-waterfall demo restored** on `B3_WallGroundEast`: inline construction with
  `libraryCode=WALL-1960-IT` (NOT in Excel) + a brick `SolidMaterial` → resolves `source=citygml`.
- Net: all three branches now demonstrated live — **excel** (FLOOR-GND/WALL-EXT/ROOF-FLAT),
  **citygml waterfall** (WALL-1960-IT), **default** (B1 + remaining B3). Verified via
  `python -m citygml2idf.model.constructions` and per-building middle-layer inspection.

### Code/docs touched (no behaviour change)
- **`geometry/classify.py`** rewritten as explicit mathematical programming: `tilt_degrees`
  (`arccos(nz)`), `azimuth_degrees` (`atan2(nx,ny)`, debug-only), `_clamped_nz`, plus a
  teaching docstring (X=E/Y=N/Z=up, `nz=cos(tilt)`, 60°=`cos⁻¹`0.5, outward precondition) and a
  `_demo()`. Behaviour identical; `classify_by_normal` signature + `HORIZONTAL_NZ` preserved.
- **`semantics/surface_types.py`** comments de-staled: the `Adiabatic` on the ADE interior
  types is the **default**; `zones.py` overrides to `Surface`+partner when two zones share a
  face (G12 IMPLEMENTED) — was still described as "interim / later upgrade".
- **CLAUDE.md** de-staled: `run.py` exists (per-building orchestrator); `zones.py`/`openings.py`
  are built; writer emits one Zone per `nrg3:ThermalZone` (gated by `FORCE_SINGLE_ZONE`);
  interzone = explicit Surface pair (implemented).

### Next
- Verify B2 end-to-end to IDF (`python -m citygml2idf.run Building_B2`) + inspect IDF/DXF together.
- Sync **MAPPING.md** construction/interzone/window rows to the implemented behaviour.
- Future rung (unbuilt): archetype construction from `yearOfConstruction`+`function` (+EPC) for
  bare LOD1 files with no construction (constructions.py 2b).
