# Session Handoff: CityGML/Energy ADE to IDF Parser

Date: 2026-06-26

## 2026-07-07 (cont. 4) — libraryCode/codeSpace REMOVED: construction resolution is now pure xlink/gml:id (like the prof) (READ THIS FIRST if resuming)

Studied the prof's `constructions.py`: he resolves construction AND material by **xlink/gml:id
only** (`id_index.get(constr_id)` / `id_index.get(mat_id)`), NO libraryCode/codeSpace anywhere;
his archetype is keyed by building **function/vintage/weight**, not by code. We had an EXTRA
`(codeSpace, code)` in-file-library lookup on the construction path only (not materials/windows —
inconsistent). Verified it was **dormant** on Alderaan (every surface xlinks straight to a
construction that already carries its layers/uValue, so the code-library drill-in never won; the
only thing `code` did was NAME constructions). Decision (with user): remove ALL code/codeSpace
logic to match the prof and make construction/material/window uniformly xlink/gml:id.

### DONE (all in `model/constructions.py` + `model/citygml_read.py`)
- **Removed** `_index_file_library`, `_library_member_for_code`, `_element_has_layers`,
  `_construction_code_info`, `_construction_code`, and the `(codeSpace, code)` drill-in branch in
  `_resolve_surface`; dropped the `file_library` arg through `resolve_all`/`_resolve_surface`;
  dropped the Tier-3 code-warn loop and the `libraryCode`/`libraryCodeSpace` trace fields.
- **`_construction_name(doc, constr_el)`** now returns the **gml:id** (was code-first). So
  constructions/glazings are named by gml:id (`id_layered_construction_ground_1`,
  `id_layered_construction_glazing_5`) instead of `layered_constr_library_code_X`.
- **`window_glazing`** updated to the new `_construction_name` signature (no code).
- **Removed `_child_code`** (the gml:CodeType/codeSpace reader) from `citygml_read.py` — now unused.
- Waterfall is now: **T1 inline layers -> T2 uValue->NoMass -> T4 default** (T3 archetype still
  deferred). Materials + windows already resolved by gml:id only, so the whole path is uniform now.
- Docs: `CLAUDE.md` construction-resolution bullet + golden-rule line; this entry.

### VERIFIED (`PYTHONHASHSEED=0`, one sample as asked)
- **`id_building_2`** (richest: 3 layered constructions + glazing + materials + 4 windows) —
  exit=0, 0 severe. Constructions now named by gml:id, **layers intact** (5 each,
  `source=citygml_layers`); glazing `id_layered_construction_glazing_5` U=1.9 SHGC=0.7; surface
  provenance clean (`citygml_layers from construction 'id_layered_construction_ground_1'`).
- **Case 2.1** — exit=0, 0 severe (still builds; construction resolution unaffected).
- `py_compile` clean; no code refs to any removed symbol (only docstrings note "no libraryCode").

### NOTE
- **Byte-identity intentionally broken** for window-bearing buildings: construction NAMES changed
  from codes to gml:ids (functionally identical IDF, different text). Case 2.1 no longer needs to
  be byte-compared for this change; correctness = exit=0 + right layers + gml:id names.
- If the real archetype JSON ever needs a code key, it is keyed by building function/year/weight
  (bldg:function / bldg:yearOfConstruction / nrg3:bdgConstructionWeight), NOT libraryCode — so this
  removal does not block it.

## 2026-07-07 (cont. 3) — CRS REPROJECTION REMOVED (assume metric, like the prof)

Studied the prof's repo (`piotre13/CityGML2Eplus`) CRS handling: **he does NONE** — no
`pyproj`/`srsName`/EPSG/reprojection; he assumes metric input and only computes a min-corner
origin + translates. Verified our reprojection was **already inert** on real data: Alderaan is
EPSG:28992 (projected/metres) so `build_transformer` returned None → `reproject` was a no-op.
Also, only surfaces went through `reproject`, not explicit LoD3 windows — a latent asymmetry
(harmless while reprojection is inert, broken only for geographic input).

**Decision (with user):** drop CRS reprojection, assume metric like the prof. This is inert on
all realistic CityGML (building geometry is authored in a projected CRS) AND removes the
surface/window asymmetry for free (both are now raw coords + the same recentre offset).

### DONE
- **`geometry/crs.py` DELETED entirely** (and its `pyproj` import gone). Removed
  `is_geographic`/`pick_utm_epsg`/`build_transformer`/`reproject`/`recenter`. Its two surviving
  functions moved to where they're used: **`min_corner` -> `geometry/rings.py`** (geometry math,
  the recenter origin) and **`parse_epsg` -> `model/reader.py` as `_parse_epsg`** (audit-only EPSG
  record; the sole caller). `reader` now imports only `rings`, no `crs`.
- **`model/reader.py`** step 2: removed the `sample_lonlat` scan + `build_transformer` +
  `reproject` loop → plain float-cast of `s.points`. `model.crs` now records
  `{srsName, epsg, units:"assumed_metric"}` (was `reprojected`). Recenter (step 3) unchanged.
- **`model/openings.py`** — NO code change (explicit windows already used raw coords + offset);
  only the docstring note updated (windows/surfaces now provably consistent).
- Docstrings: `building_surfaces.py`, `geometry/__init__.py`. **`CLAUDE.md`** deps line (dropped
  `pyproj` + the already-dead `matplotlib`) + architecture `crs.py` description.

### VERIFIED (`PYTHONHASHSEED=0`)
- **Case 2.1** — IDF **byte-identical** to baseline (reprojection was inert, so removal is a no-op).
- **`id_building_2`** — exit=0, 0 severe; `crs` record = `units:assumed_metric`; window vertex
  metric/recentred (e.g. `[10.0, 5.0, 12.879]`), consistent with surfaces.
- `py_compile` clean; no `pyproj`/`reproject`/`build_transformer` code refs remain (docstrings only).

### NOTE
- `parse_epsg` grabs the LAST number in a compound srsName (Alderaan → 5109, the vertical CRS,
  not 28992). Harmless now (epsg is audit-only, never used to transform). Fix only if we ever
  reintroduce CRS logic.
- Trade-off accepted: a geographic-CRS input would now be used as-is (wrong) — but Energy ADE
  building models don't use geographic CRS. To re-add support later, reprojection must be applied
  to BOTH surfaces AND explicit windows (the old asymmetry).

## 2026-07-07 (cont. 2) — WINDOW GLAZING WIRED (per-window) + >4-vertex window simplify_to_quad

Finished the two parked window threads. Grounded in the schema chain
(`surface → bldg:opening → bldg:Window → lod3MultiSurface geometry + nrg3:layeredConstruction glazing`)
and the prof's repo (`piotre13/CityGML2Eplus`): `parse_gml.py` reads each Window's own
`nrg3:layeredConstruction` with `resolve_construction(is_glazing=True)`; `geometry.py`
`simplify_to_quad` reduces a >4-vertex opening to its in-plane bounding rectangle;
`idf_writer.py` emits per-window `Construction_Name` + `WindowMaterial:SimpleGlazingSystem`.

### DONE (verified — see below)
- **`geometry/rings.py` `simplify_to_quad(points)`** — E+ caps `FenestrationSurface:Detailed`
  at **4 vertices** (a real E+ limit, unlike the eppy quirk on wall surfaces). Reduce a
  pentagon/hexagon window to its 4-corner **in-plane bounding rectangle**: Newell normal →
  orthonormal (u,v) basis IN the plane → project to 2D → axis-aligned bbox → 4 corners back
  to 3D, wound to preserve the outward normal. Coplanar with + bounded by the original;
  ≤4 verts pass through unchanged. Mirrors the prof's `simplify_to_quad`.
- **Per-window glazing** — `model/constructions.py` new public `window_glazing(doc, window_el)`:
  reads the Window's OWN `nrg3:layeredConstruction` and runs it through the existing
  `_glazing_from_citygml` (uValue→U-Factor, gValue / FIRST solar transmittance→SHGC, visible
  transmittance→Visible Transmittance, omitted when absent) → a `WindowConstruction`.
- **`model/model.py`** — `Window` gains `construction` (glazing name); `WindowConstruction`
  gains `visible_transmittance` + `provenance`; **`Model.window_construction` (single) →
  `Model.window_constructions` (dict name→WindowConstruction)**; `subset_for_building` slices
  the glazings the building's windows use.
- **`model/openings.py`** — `explicit_windows` now: `simplify_to_quad` the ring, resolve the
  window's glazing via `constructions.window_glazing` (or `default_window_construction()` when
  the window has none), register it in `window_constructions` (dedupe by name), set
  `Window.construction`. WWR-synthesized windows use the default glazing. `resolve_windows`
  fills `model.window_constructions`.
- **`write/writer.py`** — `add_window_constructions` emits EVERY glazing (SimpleGlazingSystem +
  Construction), writing `Visible_Transmittance` (IDD N3) ONLY when present; `add_windows` uses
  each `window.construction`. `run.py`/`writer.main` pass `model.window_constructions`.

### VERIFIED (`PYTHONHASHSEED=0`)
- **Case 2.1** (no windows) — IDF still **byte-identical** to baseline (regression guard).
- **`id_building_2`** (4 windows) — exit=0, 0 severe; windows now reference the REAL glazing
  `layered_constr_library_code_5`: `SimpleGlazingSystem` U=**1.9** (was default 2.8), SHGC=**0.7**
  (first of two solar τ, warn), **no** Visible Transmittance line (correctly omitted). *(IDF
  intentionally changed — more correct — so no longer byte-identical, as expected for this feature.)*
- **`id_building_11`** (multizone, has a **5-vertex** pentagon window) — **NOW BUILDS** (was the
  parked `BadEPFieldError: Vertex_5` crash), exit=0, 0 severe, 8 windows; pentagon → quad
  (area 27.03→31.03, the in-plane bbox). Remaining 63 warnings are pre-existing sample-geometry
  issues (unenclosed zone, collinear vertices, entered-volume≠calculated), not window-related.
- Full Alderaan parse sweep (`openings` demo): every explicit window resolves glazing
  `layered_constr_library_code_5`; LoD1 boxes = 0 windows. No crashes.
- `py_compile` clean; `simplify_to_quad` unit-checked (pentagon→4 corners; ≤4 unchanged).

### LEFT (window follow-ups, lower priority)
- **Detailed panes** (`WindowMaterial:Glazing` + per-side emissivity/reflectance, `glazing_5`
  carries them) — still DEFERRED (Rung A); SimpleGlazingSystem is the current path.
- **`glazingRatio`** (0.95 on the glazing construction) → geometry rung for LoD1/2 — still parked.
- Author dedicated window sample cases (full-data glazing incl. visible; WWR-only).
- Then: archetype JSON wiring (last), remaining Table-2 cases.

## 2026-07-07 (cont.) — DATACLASS REFACTOR COMPLETE: dual view collapsed to ONE `model.Model`

Finished the migration the previous entry set up. `Surface`, `Zone`, `Building`,
`WindowConstruction`, `Model` were added to `model/model.py`; the parser builds them
directly; **the whole trace/idf dual view + `idf_model.py` + the conversion layer are
GONE**. There is now ONE typed middle layer, and the two per-building JSONs merged into one.

### What changed (each verified — see VERIFICATION)
- **`model/model.py`** — added `Surface` (the spine: source_id, source_gml_id, type_name,
  role, surface_type, boundary, points, area, construction, zone, boundary_object, windows,
  construction_context_ids, surface_part_index/count, `provenance`), `Zone`, `Building`
  (id, zones, surfaces, lod, surface_path, origin_offset, provenance), `WindowConstruction`,
  and `Model` (crs, buildings, constructions, materials, window_construction) with
  `.building(id)` + `.subset_for_building(id)`.
- **`semantics/building_surfaces.py`** — `process_surfaces` now returns `Surface` objects
  (was dicts); `semantic_trace` folded into `provenance` (role/surface_type/boundary lines).
- **`model/reader.py`** — `build_middle_layer(doc)` builds `Building`/`Surface`, recentres,
  then enriches ONE `Model` (constructions → openings → zones). `geometry_trace` → flat
  `provenance["points"]/["area"]`. **Deleted** `build_trace_middle_layer`,
  `to_idf_middle_layer`, `_surface_for_idf`, `_building_for_idf`,
  `_window_construction_for_idf`, `build_both_middle_layers`, `build_idf_middle_layer`.
  Surfaceless (LoD0) buildings stay in the Model but are warned + skipped by the writer.
- **`model/constructions.py`** — `resolve_all`/`_resolve_surface` use attribute access;
  `construction_trace` dict replaced by one line `_construction_provenance_line` →
  `Surface.provenance["construction"]`. `middle.buildings`/`.constructions`/`.materials`.
- **`model/openings.py`** — attribute access; `default_window_construction()` now returns a
  `WindowConstruction` (was a dict); sets `middle.window_construction`.
- **`model/zones.py`** — attribute access; `make_partner` builds a `Surface` (was a dict);
  `_single_zone`/`assign_zones` build `Zone` objects into `building.zones`; `zone_trace` →
  `Surface.provenance["zone"]` / `Zone.provenance`.
- **`write/writer.py`** — imports `Zone` (was `IdfZone`), calls `build_middle_layer`; `main`
  skips surfaceless buildings.
- **`run.py`** — one `Model` via `build_middle_layer`; dumps ONE `middle_layer_<id>.json`
  (was `middle_layer_trace_<id>.json` + `middle_layer_idf_<id>.json`); deleted
  `single_building_middle_layer`/`_building_by_id`.
- **`model/idf_model.py` DELETED.**
- **Docs**: `CLAUDE.md` architecture section rewritten (one model, no dual view); this entry.

### VERIFICATION (all green, `PYTHONHASHSEED=0`)
- Baselines captured from the previous commit-state working tree BEFORE editing (scratchpad).
- **Case 2.1** (`input/cases/case2.1_lod2_1zone_nowin_synth.gml`) — IDF **byte-identical**, exit=0, OK.
- **Alderaan `id_building_2`** (SolidMaterial+AirGap+layered+4 windows) — IDF **byte-identical**, exit=0, OK.
- Verified after BOTH Phase A (Surface only, conversion layer kept) AND Phase B (full collapse).
- `py_compile` clean on all changed modules; module self-tests (`reader`/`zones`/`openings`) run.
- The one JSON is well-formed; `provenance` reads cleanly (e.g. surface: role/surface_type/
  boundary/points/area/construction/zone lines; zone: name/volume/ownership lines).

### NOT verified end-to-end (pre-existing, NOT a regression)
- **`make_partner` / interzone Surface pairs are UNEXERCISED by the samples**: 0 Alderaan
  buildings produce interzone pairs (the known source_id-matching gap — Gap #1). The change
  there is a mechanical dict→`Surface` translation (py_compile-clean, same fields).
- **`id_building_11` (multizone+windows) still fails** with eppy `BadEPFieldError:
  Vertex_5_Xcoordinate` — a **>4-vertex WINDOW** hitting E+'s 4-vertex fenestration cap.
  **Confirmed identical failure on the committed code (git stash test)** → pre-existing parked
  limitation (2026-07-04: needs `simplify_to_quad` in openings), not caused by this refactor.

### LEFT (unchanged from below)
- **Glazing wiring** (Rung B, Step 2+): `_glazing_from_citygml` is built but NOT wired; every
  window still gets the single default `FALLBACK_WINDOW`. Now that `WindowConstruction` lives
  in `model.py`, add `visible_transmittance`, per-window resolution in `openings.py`, and
  writer emission. Then the >4-vertex-window `simplify_to_quad` so multizone+window buildings build.
- Author the remaining Table-2 cases; archetype JSON wiring is last.

## 2026-07-07 — Middle-layer refactor to ONE dataclass model (`model.py`) + window-glazing status (superseded by the entry above)

Two in-flight threads. This entry is written so a NEW chat can continue both.

### AIM (why we are doing this)
Collapse the heavy **dual-view middle layer** — a nested `trace` dict PLUS separate `idf_model.py`
dataclasses, bridged by a hand-written conversion layer — into **ONE set of dataclasses** in a new
`citygml2idf/model/model.py` (the shape the prof's repo uses). Goals: modularity + readability, one
shape per concept, far less nesting. **Tracking is KEPT but FLAT**: each object carries a
`provenance` dict (`field -> "one readable line: what we did"`) instead of a 6-key nested trace dict —
serves the professor's "express what we did for each parameter" ask, but readable.

### THE PATTERN (how each type is migrated — repeat for every type)
1. Add the dataclass to `model.py` (with a `provenance: dict` field).
2. The PARSER builds the dataclass directly; nested trace dict -> flat provenance strings.
3. Consumers use ATTRIBUTE access (`.x`, not `["x"]` / `.get("x")`).
4. DELETE the `idf_model.py` `IdfX` class + its `to_jsonable()` + the reader `_x_for_idf` converter.
5. Serialization: `model.py` has ONE `to_jsonable(obj)` (dataclass -> dict, dropping None, recurses).
   Used as `json.dump(..., default=to_jsonable)` at every trace-dump site (reader.py, run.py).

### VERIFICATION — MANDATORY EACH STEP (nothing may change the IDF)
The pipeline is **non-deterministic run-to-run** (materials/constructions emitted in set-iteration
order + Python per-process hash randomization), so byte-diff only works with a **pinned hash seed**:
```
export PYTHONHASHSEED=0
PYTHONPATH=. python -m citygml2idf.run "citygml2idf/input/cases/case2.1_lod2_1zone_nowin_synth.gml"
PYTHONPATH=. python -m citygml2idf.run --building id_building_2 "citygml2idf/validation_file/Alderaan_Energy_ADE_All.gml"
diff citygml2idf/output/runs/<id>/<id>.idf  <baseline>/<id>.idf     # MUST be byte-identical
```
Two verification buildings (chosen to cover the material/construction/window kinds):
- **Case 2.1** (`input/cases/case2.1_lod2_1zone_nowin_synth.gml`) — NoMass (uValue) path, no windows.
- **Alderaan `id_building_2`** — SolidMaterial + AirGap + layered constructions + **4 windows**.
Each step: `py_compile` clean, regenerate both with `PYTHONHASHSEED=0`, IDFs **byte-identical** vs a
baseline, E+ **exit=0, 0 Severe**. (Baselines were kept in `/tmp/baseline`, which is EPHEMERAL —
a new chat should re-capture them from a clean checkout of the last commit, OR `git stash` the
refactor, regenerate, unstash.) The trace JSON *does* change shape (flatter) — that is intended,
not a regression; only the `.idf` must match.

### DONE this session (each verified byte-identical + E+ exit=0)
- **`model.py` created**: `Material`, `Construction`, `Window` dataclasses + the `to_jsonable` helper.
- **Material**: `materials.py` builds `Material` (flat provenance); `constructions.py` NoMass +
  `DEFAULT_MATERIAL` are `Material`; attribute access. Removed `IdfMaterial` + `_material_for_idf`.
- **Construction**: `constructions.py` `_from_citygml`/`_resolve_surface` return `Construction`;
  `zones.py` reversed interzone twin builds `Construction`; removed `IdfConstruction`,
  `_construction_for_idf`, `_with_context`.
- **Window**: `openings.py` builds `Window` (flat provenance; dropped `_window_synthesis_trace`,
  dict key `"from"`->`source`, `"trace"`->`provenance`); `reader._surface_for_idf` uses `Window`
  directly (no more `IdfWindow` + deepcopy); removed `IdfWindow`.
- Serialization wired: `reader.py` + `run.py` `json.dump(..., default=to_jsonable)`. (`units.py`
  pandas was already dropped earlier this session.)

### LEFT — NEXT STEP is the SPINE (biggest + riskiest): `Surface` (+ `Zone`, `Building`, `WindowConstruction`)
- **`Surface`** is the working structure EVERY parser stage MUTATES, so it touches ~86 real access
  sites across 5 modules (grep counts: `zones.py` 44, `reader.py` 29, `openings.py` 8,
  `constructions.py` 5, `building_surfaces.py` 2). Flow:
  - `semantics/building_surfaces.py` `process_surfaces` CREATES the dict (`surfaces.append({...})`:
    keys `source_id, source_gml_id, type_name, role, surface_type, boundary, points,
    construction_context_ids, semantic_trace`).
  - `reader.py` `build_trace_middle_layer` sets `s["points"]` (reproject + recenter), `s["area"]`,
    `s["geometry_trace"]`.
  - `constructions.py` reads `s["source_gml_id"]/s["source_id"]/s.get("construction_context_ids")`;
    sets `s["construction"]`, `s["construction_trace"]`.
  - `openings.py` reads `surface.get("role"/"boundary"/"surface_part_count"/"surface_part_index"/
    "source_gml_id"/"source_id"/"points")`; sets `surface["windows"]` (now a list of `Window`).
  - `zones.py` reads/sets many keys; `make_partner` BUILDS a partner surface DICT (must become a
    `Surface`); sets `surface["zone"]`, `surface["boundary"]`, `surface["boundary_object"]`.
  - `reader.py` `_surface_for_idf` builds `IdfSurface` from the dict.
  - `idf_building_visualize.py` reads the **to_jsonable dict** (via `IdfBuilding.to_jsonable`), NOT the
    dataclass — so it is UNAFFECTED as long as the JSON shape is preserved.
  RISK: a `Surface` dataclass needs all clean fields (`source_id, source_gml_id, surface_type,
  boundary, role, points, area, type_name, construction, zone, boundary_object,
  surface_part_count, surface_part_index, construction_context_ids`) + fold the trace fields
  (`geometry_trace, semantic_trace, construction_trace`) into `provenance`. Do it carefully,
  attribute-by-attribute; verify byte-identical after.
- **`Zone`** (small): `building["zones"]` dicts (`name, volume`) -> `Zone`; remove `IdfZone`.
- **`Building`** (small): reader `_building_for_idf` -> `Building` (`id, zones, surfaces`); remove `IdfBuilding`.
- **`WindowConstruction`** (glazing, small): `idf_model.py` dataclass (`name, u_factor, shgc`) ->
  move to `model.py`; add `visible_transmittance` when the glazing thread lands (below).
- **FINALLY** delete the whole conversion layer (`to_idf_middle_layer`, `_surface_for_idf`,
  `_building_for_idf`, `_window_construction_for_idf`) and collapse the DUAL VIEW to ONE model. The
  two JSON dumps (`middle_layer_idf_*.json` + `middle_layer_trace_*.json`) merge into ONE
  `middle_layer_*.json` (writer reads the fields it needs, ignores `provenance`). `IdfModel` ->
  `Model` in `model.py`; `idf_model.py` disappears.

### PARALLEL THREAD — WINDOW GLAZING (Rung B, simple) — resolver BUILT, NOT yet WIRED to windows
Independent of the dataclass refactor (this is the window PHYSICS). Status:
- **DONE**: `_glazing_from_citygml` in `constructions.py` (the glazing "kind", like the prof's
  `is_glazing`): `nrg3:uValue` -> U-Factor; `nrg3:gValue` else **FIRST** solar
  `nrg3:transmittance.fraction` -> SHGC (warn on duplicate solar); **visible**
  `nrg3:transmittance` -> Visible Transmittance (OMIT when absent). Clamps SHGC/VT to open (0,1).
  `_glazing_transmittances` is the ONE place `nrg3:transmittance` is parsed (solar AND visible).
  Verified on Alderaan `glazing_5`: U=1.9, SHGC=0.7 (first solar tau, 2 present -> warn), Visible=omitted.
- **DECISIONS** (with prof + user): per-window resolution; SHGC from solar transmittance directly
  (approx, SHGC >= tau); **SimpleGlazingSystem now, detailed `WindowMaterial:Glazing` DEFERRED**
  (Rung A). Schema fact: `Transmittance` has NO inside/outside (only `Reflectance`/`Emissivity` do),
  so the two solar tau in `glazing_5` are ambiguous sample data -> first-wins + warn. `glazingRatio`
  -> geometry (parked). Window PROCESS = detailed(has layers) -> simple(uValue) -> default, mirroring
  the opaque waterfall. E+ target IDF datasets are in `validation_file/Window*.idf` (gitignored by
  the blanket `*.idf` rule).
- **NOT DONE** — the wiring, Step 2+ of the window plan:
  1. `openings.py`: each `bldg:Window` reads its OWN `nrg3:layeredConstruction`, calls
     `_glazing_from_citygml`, attaches a per-window glazing construction (dedupe by name).
  2. `WindowConstruction` gains `visible_transmittance`; each window carries its construction name.
  3. `writer.py`: emit ALL window glazings (write `Visible Transmittance` ONLY when present) +
     per-window `Construction_Name`.
  4. Author 2 sample cases: full-data glazing (uValue+gValue+visible) and Alderaan-pattern
     (uValue + solar tau only). Run, prove exit=0.
  Currently every window still gets ONE default `FALLBACK_WINDOW` glazing
  (`openings.default_window_construction`).

### CONTEXT a new chat needs
- **Excel fully removed** earlier this session; construction resolution is the RAW CONVERTER
  (T1 detailed layers -> T2 `uValue`->NoMass -> T4 default); archetype fallback deferred to a JSON
  stub (`model/archetypes.py` + `input/archetypes.json`, UNWIRED, keyed by function/year/weight).
- **Layer order**: middle layer stores ADE inside->outside; `writer._energyplus_layers` reverses to
  E+ outside->inside (verified on `id_building_2`). `layer_order` lives on `Construction`.
- **Last commit `6fd8033`** ("Remove Excel; raw-converter constructions + JSON archetype stub +
  simple glazing (Rung B)") is BEFORE this dataclass refactor — the whole refactor (Material +
  Construction + Window) is currently UNCOMMITTED in the working tree.
- Golden rule + schema-first still apply (CLAUDE.md). Schema source: `validation_file/CityGml_ADE_SChema/`.
  EnergyPlus rules: vendored `templates/Energy+.idd` + BigLadder v23.1.

### RESUME INSTRUCTIONS for the new chat
1. Re-capture `PYTHONHASHSEED=0` baselines for Case 2.1 + `id_building_2` (from the current working
   tree — the refactor so far is verified good).
2. Continue the dataclass refactor: migrate **`Surface`** (spine, careful, attribute access across
   the 5 modules) -> verify byte-identical + exit=0 -> then `Zone`/`Building`/`WindowConstruction`
   -> then DELETE the conversion layer and collapse to one `Model`/one JSON.
3. Separately, finish the **glazing wiring** (Step 2+ above) when ready.

## 2026-07-06 — Excel REMOVED entirely; construction resolution is now a pure RAW CONVERTER (+ deferred JSON archetype stub)

Studied the prof's repo (`piotre13/CityGML2Eplus`) and his latest meeting notes: build a **raw
converter first** (expects detailed layers OR an averaged value straight from the CityGML,
**ignores archetype codes**), and add the archetype/DB fallback **at the very end** — as a
**JSON** table (not Excel), read generically so the real data (TABULA / UBEM-CARDs) drops in
later with **no code change** ("just change the name"). Key realisation: an archetype is keyed
by building **function + year + weight**, NOT by `libraryCode` — so our old `(codeSpace,code) →
Excel` rung mis-modelled it AND duplicated Tier-1's in-file library. His own repo confirms this:
`data/archetypes.csv` keyed `function,vintage_min,vintage_max,weight → u_wall/u_roof/u_ground/
u_window/g_window`, explicitly a "TODO placeholder, replace with real data".

**Schema-confirmed the archetype key fields exist** in our XSD: `bldg:function` / `bldg:usage`,
`bldg:yearOfConstruction`, and `nrg3:bdgConstructionWeight` (codelist `ConstructionWeightValue`
= veryLight/light/medium/heavy/unknown — exact match to the prof's `weight` column).

**Removed ALL Excel** (no `pandas`/`openpyxl`/`.xlsx` anywhere now):
- **`model/catalogue.py` DELETED.** Its Excel half (`load_database`, `_load_database_or_empty`,
  `_excel_match`, `SHEET_NAMES`, `COLUMN_MAP`, `DEFAULT_DB`) was removed; its 3 remaining
  **pure-CityGML** helpers (`_element_has_layers`, `_index_file_library`,
  `_library_member_for_code` — the in-file `LayeredConstructionLibrary` resolver, Tier 1) were
  **folded into `model/constructions.py`** (small section under the imports).
- **`model/materials.py`** — deleted `_material_from_excel` / `_resolve_excel_field`.
- **`model/constructions.py`** — deleted `_from_excel` + the whole Tier-3 Excel block; waterfall
  is now the RAW CONVERTER: **T1 detailed layers → T2 `uValue`→NoMass → T4 default** (no db arg).
- **`model/openings.py`** — default glazing comes from the code constant `FALLBACK_WINDOW`, not
  the Excel `windows` sheet (`default_window_construction()` no longer reads a workbook).
- **`model/units.py`** — dropped the `pandas` import (`_trace_value` now uses `math.isnan`).
- **`input/construction_db.xlsx` DELETED** (fabricated placeholder data the prof said not to
  invent).

**Built the JSON archetype STAGE** (swap-ready, INERT — the prof's "parse json, read key/value"):
- **`model/archetypes.py`** — small stdlib-`json` loader: `load_archetypes(path)` → `{key:
  {params}}` (drops `_`-doc keys; missing/empty/broken → `{}`), `lookup(table, key)`. Documented,
  demoable (`python -m citygml2idf.model.archetypes`), but **NOT wired** into the waterfall (raw
  converter first; slots between T2 and T4 later).
- **`input/archetypes.json`** — EMPTY placeholder (only a `_README` describing the shape). Tier
  stays inert; live pipeline is the raw converter.

**Why this is simpler than Excel** (and stays simpler when the real JSON arrives): stdlib `json`
vs `pandas`+`openpyxl`; a plain `key → values` dict vs 3 sheets + `SHEET_NAMES`/`COLUMN_MAP`
schema + `(codeSpace,code)` collision rules; one isolated module vs a Tier-3 block woven into the
resolver; swap = drop a file + change a path vs rebuild a workbook to an exact sheet/column shape.

**Verified (all green):**
- `py_compile` clean on every changed module; no `pandas`/`xlsx`/`catalogue` refs remain.
- Case 2.1 → constructions via **Tier 2** (uValue→NoMass R=1/U); full `run.py` end-to-end **exit=0, OK**.
- `Alderaan_Energy_ADE_All.gml` → **identical** to before: 7 constructions / 19 materials, 6 from
  `CITYGML_LAYERS` + 1 default. `layered_constr_library_code_2` now resolves from **CityGML
  layers, not Excel** — proof the Excel tier was never winning on real data (golden rule).
- Archetype stage loads and reports inert (0 rows).

**Docs updated:** `CLAUDE.md` construction-resolution bullet + deps line; this entry.

**NEXT:** (1) wire a weather `.epw` in `write/writer.py` (`WEATHER_EPW`) → **free-float** run
(no HVAC, track Zone Mean Air Temperature) — the prof's near-term objective; (2) the
most-detailed→least-detailed **parameter-ladder** writeup (opaque now, glazing later) to map
with the prof; (3) THEN the parked window g/u/visible glazing logic (per-window resolution,
`gValue`→ solar-transmittance fallback→ default, optional visible transmittance — scoped
2026-07-06 earlier this session). Archetype JSON wiring is LAST.

## 2026-07-05 — Material handling: per-field defaulting + full per-field trace (prof-aligned)

Studied the prof's `constructions.py` / `model.py` / `idf_writer.py` and adopted his cleaner logic while
KEEPING (and upgrading) our audit trail. The rule: **keep every real value the file provides, default
ONLY the field that is missing, and trace every parameter.** All in `model/materials.py` (+ a units tweak
+ a writer warmup bump).

- **`nrg:SolidMaterial` → ALWAYS a full E+ `Material`**, PER-FIELD defaulting (`_solid_material` +
  `_resolve_field`): a SolidMaterial missing one number still becomes a real Material with its other real
  values. Removed the old "missing mass → NoMass" and "missing conductivity → whole DEFAULT" branches.
  Realistic per-field defaults (k=1.0, ρ=1000, cp=900, t=0.10), tunable in one place.
- **`nrg:Gas` → ALWAYS `Material:AirGap`** (`_airgap_material`): real `nrg:rValue` kept; defaults to
  **0.18** (ISO 6946 still-air gap) when missing/unusable (previously a bad rValue fell to default opaque).
  `gas_type` recorded for the trace.
- **`Material:NoMass` ONLY from a uValue-only construction** (R = 1/U, `constructions._from_citygml`) —
  matches the prof and the spec. `if layers → layered; elif uValue → NoMass; else default`.
- **specificHeat** (`units.py`): now also ×1000 when the value is `< 10` (a mislabeled kJ/(kg·K)), like the
  prof, then enforces the E+ floor (100). This rescues Alderaan's `cp = 0.9` → **900** (it was wrongly
  floored to 100 before).
- **PER-FIELD TRACE** (the audit ask): every field records `raw (+uom) → value (+unit)`, `source`
  (`citygml` / `excel` / `default`), and a `reason` when defaulted. BOTH `_material_from_citygml` and
  `_material_from_excel` now use the same `trace` shape via `_resolve_field` / `_resolve_excel_field`
  (modular, no repetition). Replaced the old `raw_citygml` / `converted` / `raw_excel` shapes.
- **`write/writer.py`**: `Maximum_Number_of_Warmup_Days` 25 → 50 — real thermal mass (proper cp)
  converges slower; without this `id_building_2` hit a warmup non-convergence **Severe** (E+ still
  "Completed Successfully"; it was numerical, not an invalid IDF).
- **Verified:** Alderaan SolidMaterials → full `Material` (real k/ρ/t, cp rescued to 900); `Gas` →
  `AirGap`; the trace shows `source` + conversion + reason per field (e.g. gas rValue `8.314 J/K/mol`
  → `0.18` `source:default`); `id_building_2` E+ `exit=0/OK`; Case 2.1 unchanged (NoMass, `exit=0`);
  Excel material trace confirmed per-field.
- **NOTE:** this intentionally changed Alderaan's material numbers (cp 100→900, gas layers → AirGap) —
  they are more correct now.

## 2026-07-05 — Pipeline simplified to PRESENCE-BASED (stages removed) + per-case testing

**Decision (with the prof's method in mind):** test the pipeline **one Energy ADE Table-2 case at a
time** — each a **self-contained single-file GML** in `citygml2idf/input/cases/`, run through `run.py`,
then inspect the middle layer + IDF + EnergyPlus result. This replaces the old "one big Alderaan file +
config stage flags" testing.

**Removed the test-stage scaffolding** (with per-case files, the *file* is the scenario, so the flags
were pure confusion — they produced the misleading `__MZ_Win` folder tag):
- **Deleted `config.py`** (its only content was the 3 flags `ENABLE_WINDOWS` / `FORCE_SINGLE_ZONE` /
  `DEFAULT_WWR`).
- **`run.py`** — removed `STAGES` / `apply_stage` / `flag_tag` / `--stage` / `--default-wwr` and the
  `STAGE flags:` print. Output folder is now just **`output/runs/<BuildingId>/`** (no stage suffix).
- **`zones.py`** — always reads the file's `nrg3:ThermalZone`s (dropped the `FORCE_SINGLE_ZONE` branch).
- **`openings.py`** — only emits a window when the file provides a source (dropped the `ENABLE_WINDOWS`
  gate and the `DEFAULT_WWR` fabrication branch).
- The pipeline now does ONE thing: **read a file → one IDF per building → run E+**, purely
  presence-based (matches the prof + our golden rule). Verified behaviour-preserving: Case 2.1 (no
  windows in file) → 0 windows; Alderaan `id_building_2` (windows in file) → 4 windows; both `exit=0`.
- **Run command now:** `python -m citygml2idf.run <path.gml>` (optionally `--building <id>`).

**The 7 Table-2 cases, recommended order (one new capability per step):**
`2.1` LoD2·1z·no-win → `5.1` LoD2·1z·coincidesHull → `3.1` LoD2·mz → `6.1` LoD3·1z·win·coincidesHull →
`4.1` LoD3·mz·win → `1.1` LoD1·1z → `1.2` LoD1·mz.

**Sample-authoring rule:** each case = a **self-contained single file** (every reference resolves inside
it; within-file xlinks are fine, like Alderaan). **No trimming** of the multi-building Alderaan (that
breaks shared library xlinks). **Cross-file xlink** (a library in a separate file) is a separate later
item — needs a multi-file id index (`build_id_index`), not one of the 7 cases.

**DONE — Case 2.1:** `input/cases/case_2_1_lod2_1zone.gml` (10×10×3 box, one thermal zone, six
`thermalBoundary` surfaces, `uValue` constructions via within-file xlink, no windows).
**XSD-validated: PASSED** against `validation_file/CityGml_ADE_SChema/`. Parses to LoD2 / 6 surfaces /
320 m²; E+ `exit=0`, 0 Severe (2 benign warnings: design-day-only run + `Material:NoMass` = no thermal
mass, inherent to the uValue path).

**MISSING / next:** author + validate + run cases `5.1, 3.1, 6.1, 4.1, 1.1, 1.2` (one at a time); add a
`MAPPING.md` case-coverage table (per case: what we read → what E+ object → status); cross-file xlink
(`build_id_index`); LoD1 `glazingRatio` window rung. NOTE: `xml_io.DEFAULT_INPUT` still points at the
deleted `sample_energyADE.gml` — harmless as long as a path is always passed to `run.py`.

## 2026-07-04 — surface_types.py: schema-grounded coverage expansion

Handled several previously-commented boundary-surface types, EACH decided from the XSD/spec
(`validation_file/.../building.xsd` + CityGML 2.0 OGC 12-019), never guessed on the fly.

- **OuterFloorSurface / OuterCeilingSurface** (CityGML 2.0, LoD2-4) — ACTIVATED. The E+ `Surface_Type`
  follows the OUTWARD NORMAL (same rule as `classify.py`), which **inverts** the CityGML name (the name
  is the outdoor space's view, the E+ type is the enclosed zone's view):
  - `OuterFloorSurface`  — spec: normal **UP** (a loggia floor)      → exposed **TOP** of the zone below → **Roof**, Outdoors.
  - `OuterCeilingSurface`— spec: normal **DOWN** (a soffit/overhang) → exposed **FLOOR** of the zone above → **Floor**, Outdoors.
  - The old suggestion-comments had these **backwards** — the spec fixed them. (Exactly why we ground in the schema.)
- **LoD4 room-INTERIOR trio** (`FloorSurface`, `CeilingSurface`, `InteriorWallSurface`) — ACTIVATED as
  generic-adiabatic, the same treatment as the ADE interfaces (`FloorOrCeiling`/`Wall` + `Adiabatic`
  default; `zones.py` overrides to `Surface` when two modelled zones share the face).
- **Unknown / unmapped labeled type** — no longer DROPPED. `building_surfaces.process_surfaces` now keeps
  it and **classifies it by the outward normal** (like the LoD1 path) instead of skipping (our old
  behaviour) or blind-guessing "wall" (the prof's default). Honours BOTH golden-rule halves: never drop
  geometry, never guess by name. `zones.py` still fixes interzone boundaries.
- **ClosureSurface** — DEFERRED, in an explicit `surface_types.SKIP_TYPES` (deliberately dropped, NOT
  geometry-classified). WHY not emitted: E+ `BuildingSurface:Detailed` REQUIRES a `Construction_Name`
  (IDD field A3), but a ClosureSurface is VIRTUAL (no material), so emitting it would force INVENTING a
  dummy construction — a golden-rule violation. Revisit only if a real file's zone won't close without it
  (then decide a default adiabatic construction).

Prof comparison (`piotre13/CityGML2Eplus` `parse_gml.py`): his `mapping` has 8 types, collapses all
interior surfaces to one adiabatic bucket, maps `ClosureSurface`→adiabatic (kept), and defaults unknown
→ `wall`. We now cover MORE (the ADE interfaces + Outer*), and handle unknowns by GEOMETRY (stronger than
his blind "wall").

**Alderaan inventory** (what the sample actually contains): `WallSurface` 94, `RoofSurface` 48,
`PartyWallSurface` 24, `GroundSurface` 23, `IntermediateFloorSurface` 2, `BasementCeilingSurface` 1 — all
already covered; the newly-activated types do NOT appear, so activating them is pure future-proofing.
**Verified:** py_compile OK; Alderaan envelope byte-identical; a synthetic test confirms unmapped→kept
(classified roof by geometry) and `ClosureSurface`→skipped.

## 2026-07-04 — Readability refactor (eppy KEPT) + the >4-vertex wall fix (`_vertex_fields`)

Goal this session: make the code **readable without downgrading** coverage/correctness. Decision up
front: **keep eppy** (its IDD validation is our safety net — do NOT switch to raw-text IDF writing),
keep the two-view middle layer (trace dict + idf), keep all coverage. Every change below was verified
behaviour-preserving (byte-/object-identical IDFs).

**Readability, step by step (each verified against the pre-change output):**
- **Split `model/constructions.py`** (one ~770-line file) into single-responsibility modules:
  `units.py` (value coercion + unit conversion), `citygml_read.py` (typed GML child readers),
  `materials.py` (the 3 E+ material builders + `DEFAULT_MATERIAL`), `catalogue.py` (Excel DB + in-file
  library + `(codeSpace,code)` matching). `constructions.py` is now the thin resolver + the 4-tier
  waterfall, and **re-exports** the names `openings.py`/`zones.py`/`reader.py` import, so those are
  untouched. Verified: construction/material dump byte-identical (only a cosmetic warn wording changed).
- **Typed the IDF middle layer** (the writer contract): new `model/idf_model.py` with dataclasses
  `IdfModel / IdfBuilding / IdfZone / IdfSurface / IdfWindow / IdfConstruction / IdfMaterial /
  WindowConstruction`, each with `to_jsonable()` that reproduces the OLD JSON exactly, plus
  `IdfModel.subset_for_building()`. `reader.to_idf_middle_layer` now builds these; `writer.py` reads
  `surface.surface_type` instead of `surface["surface_type"]`; `run.py` uses the typed view (the
  visualizer still gets a dict via `to_jsonable()`). **Trace view stays a dict.** Verified: IDF objects
  identical, idf JSON semantically identical, full `run.py` end-to-end `exit=0`.
- **Named the 3 surface-source paths** (`semantics/building_surfaces.py`). Split the tangled
  `surfaces_of_building` into: a `SurfacePath` Enum (`ENERGY_ADE_BOUNDARIES` / `CITYGML_BUILDING_SHELL`
  / `RAW_SOLID_FALLBACK` / `NONE`), `select_surface_path()` (the most-detailed-first cascade, one clean
  early-return each), and a PURE `process_surfaces()` (orient + classify, no XML). Mirrors the prof's
  rich/poor/coincides naming — *coincides folds into SHELL, it is not a 4th path*. The chosen path is
  now recorded per building in the **trace** (`building['surface_path']`) for audit. Verified: same
  envelope areas, idf view semantically identical, all 22 IDFs object-identical.
- **LoD0 / empty-building fix.** Before, a building with no usable envelope produced a Zone with **no
  surfaces → EnergyPlus Severe**. Now `select_surface_path` returns `NONE`, the building is **kept in
  the trace** (with `surface_path='none'` + a warning) but **dropped from the idf view**
  (`reader.to_idf_middle_layer` skips surface-less buildings), so the writer never emits a broken IDF.
  "Read it for the audit, skip building it." (Alderaan has none, so behaviour there is unchanged.)

**Coverage fix — `write/writer.py` `_vertex_fields` (WHY it exists — remember this):**
- **Problem.** A wall/roof/floor can have MORE than 4 corners (L-shaped / angled → 5, 6, …). EnergyPlus
  ALLOWS this: `BuildingSurface:Detailed` is `\extensible:3` in `Energy+.idd` (up to 120 vertices;
  BigLadder I/O Reference v23.1 confirms — "shown with 120 vertex coordinates, extensible, duplicate the
  last x,y,z set"). But our writer created the surface then added vertices ONE AT A TIME via
  `setattr(obj, "Vertex_5_Xcoordinate", …)`, and **eppy** only materialises ~4 vertex fields on a fresh
  object → `BadEPFieldError: Vertex_5` → the building produced NO IDF. This is an **eppy quirk, not an E+
  limit**, and it blocked **10 of 22** Alderaan buildings (the complex LoD3 ones).
- **Fix.** `_vertex_fields(points)` builds ALL vertex coordinates into a kwargs dict and passes them to
  `newidfobject(...)` **at creation** (not setattr afterwards). eppy then sizes the object correctly, so
  any N ≤ 120 vertices build. **Keeps eppy + its IDD validation — no raw-text rewrite.** (This is the one
  trap the prof's raw-text writer sidesteps for free; we get the same result while keeping validation.)
- **Verified.** No-window stages now build **22/22** (was 12/22). EnergyPlus runs a 5-vertex-wall
  building `exit=0`, 0 severe. The 12 previously-building IDFs are byte-unchanged. The generated IDF is
  the standard `Number of Vertices, then N × (x,y,z)` layout — identical to what raw-text would emit.

**Parked — WINDOWS (`model/openings.py` NOT yet improved):**
- `FenestrationSurface:Detailed` (windows) is capped at **4 vertices by EnergyPlus itself** — a REAL E+
  rule, not an eppy quirk. Some LoD3 Alderaan windows have 5 vertices → the *with-window* stages still
  fail on those (walls are fixed).
- **TODO when we start the windows work:** add **quad simplification** in `openings.py` — reduce any
  >4-vertex opening to a 4-corner quad (the prof's `simplify_to_quad`), THEN the with-window stages reach
  22/22. Fold this into the parked windows work (LoD1 `glazingRatio` rung + `gValue↔SHGC` study). Do NOT
  do it before we actually start on windows.

## 2026-07-03 — Construction/material resolution: the 4-TIER waterfall (meeting decision)

After the professor meeting, construction & material resolution is a strict **most-detailed-first
waterfall**; the external code/Excel is the LAST fallback, never first:

- **TIER 1 — CityGML DETAILED layers.** The construction's own inline `nrg:layer`, OR an in-file
  `LayeredConstructionLibrary` member (reached by xlink OR by the `(codeSpace, code)` pair).
- **TIER 2 — CityGML AVERAGED value.** No layers, only `nrg:uValue` → `Material:NoMass` (R = 1/U).
  The typical LoD1 hull case (the "single averaged U/g for the whole hull" picture).
- **TIER 3 — EXTERNAL Excel/DB code.** `(codeSpace, code)` → `construction_db.xlsx`. This is the
  PLACEHOLDER for the archetype (TABULA / UBEM-CARDs) database. LAST fallback, only when the CityGML
  gave nothing. Raw data always beats a code. **The archetype logic itself is DEFERRED** ("build the
  raw converter first; add archetypes last"). When built it is keyed by a CityGML building field
  (`bldg:yearOfConstruction` + `bldg:function/usage`, + `nrg3:bdgType`) — first confirm which ADE field
  carries the archetype. We do NOT invent the numbers; the DB is TABULA/UBEM-CARDs (teammate builds it).
- **TIER 4 — DEFAULT** construction.

**Done this session (`model/constructions.py`, `input/construction_db.xlsx`):**
- **Reordered** `_resolve_surface` from Excel-FIRST to the tier order above (Excel is now Tier 3; two
  passes — all owners' CityGML data first, then Excel). Fixes a real bug: Excel-first was *overriding*
  Alderaan `wall_2`'s real inline layers with our Excel placeholder — exactly what the prof said not to
  do. `code_2` now resolves from the file's own layers (Tier 1).
- Excel matching keyed by the `(codeSpace, code)` PAIR (from the ADE schema) with a **required**
  `code_space` column; every row now declares a codeSpace (no confusing blanks). The Excel is a
  swappable placeholder (`SHEET_NAMES`/`COLUMN_MAP`), kept but dormant for files that carry their own
  data. **No config flag** — a file with its own CityGML data never reaches Tier 3.

**Related decisions parked (same meeting):**
- **Windows LoD1** — read `glazingRatio` (+ `gValue`) as the Tier-2 glazing rung (not yet built);
  `gValue↔SHGC` to be studied WITH the prof. LoD2 (WWR/areas) + LoD3 (explicit) already work.
- **Neighbourhood/adjacency** — NOT our step. Trust the CityGML surface types (party wall → Adiabatic)
  + `bdgBdrySurfIsAdiabatic`; teammate Ali enriches the CityGML upstream.
- **BuildingParts** — prof wants SEPARATE IDFs named `partA_/partB_<building>` (parts can differ in
  construction/HVAC). We currently MERGE parts into one IDF — deferred; reconcile later.
- **Multi-polygon surface split** — disabled; we assume single-polygon surfaces (like Alderaan).
- **Geometry** — outward normal is convex-only (centroid heuristic); concave (L/U) flips inner walls
  (known gap — see COVERAGE.md).

Reference repos from the prof: `piotre13/CityGML2Eplus` (simpler reference; its construction fallback is
already layered → U-value → archetype, adjacency is a decoupled preprocessor) and `piotre13/Eplus_graph`
(IDF object-relations visualizer).

## Current Goal

We are improving the `citygml2idf` pipeline so it can parse valid CityGML 2.0 plus Energy ADE 3.0 files in a robust, schema-first way, then write EnergyPlus IDF without splitting the code into separate "test" and "real" pipelines.

Current focus:

1. Geometry
2. Construction and material
3. Windows/openings
4. Multizone thermal-zone logic

The user has official TU Delft Energy ADE sample files and XSD files in `citygml2idf/validation_file/`. These are the source of truth together with the UML/specification PDFs.

## Main Design Principle Agreed

The parser should be schema-first, not LoD-first.

Correct mental model:

```text
Building
  -> ThermalZone
      -> thermalBoundary
          -> BoundarySurface
              -> geometry child, for example lod3MultiSurface or lod2MultiSurface
              -> opening
              -> layeredConstruction
```

This means:

1. Follow the schema relationship first.
2. Resolve inline or byReference objects.
3. Read whatever explicit data exists.
4. If missing, follow related/reference objects when the schema allows it.
5. If still missing, use calculated fallback.
6. Last resort: project default.

LoD is only a geometry selector inside an already-resolved object. It should not drive the whole parser.

## Step 1 Done: Relationship Resolver

### File changed

`citygml2idf/citygml/xml_io.py`

### What was added

Added `CityGMLDoc.property_object(property_el)`.

Purpose:

```text
<someProperty>
  <TargetObject .../>
</someProperty>
```

and:

```text
<someProperty xlink:href="#target_id"/>
```

are both valid CityGML/ADE property patterns. The parser now has one shared helper for both.

### Why

The XSD says many properties can carry either:

1. an inline object, or
2. an `xlink:href` reference.

Examples:

- `nrg3:thermalBoundary`
- `bldg:boundedBy`
- `bldg:opening`
- `nrg3:layeredConstruction`
- `nrg3:material`

Before this, parts of the parser handled xlinks manually and missed inline official ADE patterns.

### Files updated to use it

- `citygml2idf/semantics/building_surfaces.py`
- `citygml2idf/model/zones.py`
- `citygml2idf/model/constructions.py`
- `citygml2idf/model/openings.py`

## Step 2 Done: Geometry Source Selection

### File changed

`citygml2idf/semantics/building_surfaces.py`

### What changed

`surfaces_of_building()` now uses this source priority:

```text
1. Energy ADE ThermalZone -> thermalBoundary -> BoundarySurface
2. Building shell bldg:boundedBy -> BoundarySurface
3. Solid fallback
```

### Why

Official Alderaan Energy ADE samples often use this pattern:

```xml
<nrg3:ThermalZone gml:id="id_thermal_zone_1">
  <nrg3:thermalBoundary>
    <bldg:WallSurface gml:id="id_thermal_zone_1_wallsurface_1">
      ...
    </bldg:WallSurface>
  </nrg3:thermalBoundary>
</nrg3:ThermalZone>
```

Our old geometry reader mainly used:

```xml
<bldg:boundedBy>
  <bldg:WallSurface .../>
</bldg:boundedBy>
```

That worked for our custom sample, but it missed the official Energy ADE thermal-boundary geometry.

### Important Energy ADE rule included

If a thermal zone says:

```xml
<nrg3:coincidesWithLod2Hull>true</nrg3:coincidesWithLod2Hull>
```

or:

```xml
<nrg3:coincidesWithLod3Hull>true</nrg3:coincidesWithLod3Hull>
```

then separate thermal boundaries are not required. In that special case, the parser falls back to the building shell surfaces.

### Geometry LoD refinement

Boundary surfaces now read geometry children in this order:

```python
for n in (3, 2):
```

This means LoD3 first, then LoD2.

Why:

- Energy ADE thermal boundaries can use LoD2 or LoD3 thematic surface geometry.
- LoD4 thermal boundaries/openings are not allowed by the specification.
- LoD1 uses solid geometry, not thematic boundary surfaces.

## Step 2 Extra Fix: Referenced Geometry

### File changed

`citygml2idf/citygml/xml_io.py`

### What changed

`read_pos_list()` now follows:

```xml
<gml:surfaceMember xlink:href="#some_polygon"/>
```

if the `MultiSurface` does not contain an inline `gml:posList`.

### Why

Official ADE samples often store LoD2 geometry this way:

```xml
<bldg:lod2MultiSurface>
  <gml:MultiSurface>
    <gml:surfaceMember xlink:href="#id_building_1_polygon_5"/>
  </gml:MultiSurface>
</bldg:lod2MultiSurface>
```

Without this fix, the parser could resolve the surface object but fail to get its polygon coordinates.

## Step 3 Started: Openings and Windows

### File changed

`citygml2idf/model/openings.py`

### Current window waterfall

For each exterior wall BoundarySurface:

```text
1. Explicit bldg:Window geometry, LoD3 only
2. nrg3:bdgBdrySurfOpeningToSurfaceRatio
3. (bdgBdrySurfTotalSurfaceArea - bdgBdrySurfOpaqueSurfaceArea) / total
4. config.DEFAULT_WWR, test-only
5. None -> opaque wall
```

### Exact code locations

- `resolve_windows()` loops every exterior wall surface.
- `windows_for_wall()` applies the waterfall.
- `explicit_windows()` reads `bldg:opening`.
- `window_ring()` reads only `lod3MultiSurface`.
- `window_to_wall_ratio_from_attributes()` reads ratio and total/opaque area.
- `synthesize_window()` creates a fallback test window from WWR.

### Refinements made

`explicit_windows()` now uses immediate schema children:

```python
doc.children(wall_element, "bldg", "opening")
```

instead of broad descendants.

It resolves inline/xlink opening objects with:

```python
doc.property_object(opening_element)
```

`window_ring()` now reads only:

```python
bldg:lod3MultiSurface
```

and ignores LoD2/LoD4 explicit window geometry.

### Why

Energy ADE specification says:

- LoD2 thermal openings are not explicitly modelled as window geometry.
- LoD2 should use ratios/areas.
- LoD3 thermal openings can be explicit `bldg:Window` or `bldg:Door`.
- LoD4 thermal openings are not allowed.

## Earlier Pipeline/Test Support Added

### File changed

`citygml2idf/run.py`

Added stage-based CLI controls:

```text
--stage 1z-nowin
--stage 1z-win
--stage mz-nowin
--stage mz-win
--stage real
--default-wwr
--building
```

Purpose:

Run the same real parser with controlled gates, not a separate testing parser.

Professor's requested test cases:

1. One building, one zone, no window
2. One building, one zone, with window
3. One building, multizone, with window
4. One building, multizone, without window
5. Real parser: multibuilding, multizone

### File changed

`citygml2idf/idf_building_visualize.py`

Added/updated preview plotting for IDF/middle-layer outputs:

- zones colored separately
- windows shown in blue
- interzone pair outlines shown
- labels/legend included

Purpose:

Make geometry, multizone, and window results visually traceable.

### Files changed

`citygml2idf/config.py`

`citygml2idf/write/writer.py`

Updated comments/docstrings to reflect the current interzone EnergyPlus logic:

- multizone uses explicit reciprocal `Surface` pairs
- not `Outside Boundary Condition = Zone`

## EnergyPlus Boundary Discussion

EnergyPlus `BuildingSurface:Detailed` allows:

```text
Outside Boundary Condition = Surface
Outside Boundary Condition Object = name of the matching surface
```

So a line like this is valid in concept:

```idf
Surface,
    B3_BasementCeiling_pair,
```

The object name is not from a fixed keyword list. It must be the name of another `BuildingSurface:Detailed` object in the same IDF. The keyword restriction applies to `Outside Boundary Condition`, not to the object name.

## Validation and Checks Already Run

### Earlier EnergyPlus staged checks

These staged runs completed without Severe/Fatal errors:

```text
Building_B1__1Z_noWin
Building_B1__1Z_Win_DWWR30
Building_B3__MZ_noWin
Building_B3__MZ_Win
```

Known warnings for B3:

- some sample zones are not fully enclosed
- this is due to sample/test geometry, not necessarily the parser

### Official Alderaan parser probes

After the thermal-boundary geometry change, the official Building Physics sample produced thermal-zone surface IDs like:

```text
id_thermal_zone_1_groundsurface_1
id_thermal_zone_1_roofsurface_1
id_thermal_zone_1_wallsurface_1
```

This confirmed that geometry now follows:

```text
ThermalZone -> thermalBoundary -> BoundarySurface
```

instead of only the building shell.

### Current validation limitation

Python syntax checks were not run after the last small refinement because:

- normal `python` failed with a Windows logon-session error
- `py` launcher is not installed
- escalated Python execution was not approved at that moment

Next time, run:

```powershell
python -m py_compile citygml2idf\citygml\xml_io.py citygml2idf\semantics\building_surfaces.py citygml2idf\model\openings.py citygml2idf\model\zones.py citygml2idf\model\constructions.py
```

Then run a small parser probe on:

```text
citygml2idf/validation_file/Alderaan_Energy_ADE_Core_Building_physics.gml
```

## Where We Are Now

Completed:

1. Understood inline vs byReference.
2. Added shared relationship resolver.
3. Adjusted zone boundary ID parsing to use the resolver.
4. Adjusted construction helper to use the resolver.
5. Adjusted geometry extraction to prefer Energy ADE thermal boundaries when present.
6. Added referenced `gml:surfaceMember` geometry support.
7. Refined boundary-surface geometry selection to LoD3 then LoD2.
8. Refined explicit window parsing to schema child `bldg:opening`, inline/xlink, LoD3 only.
9. Kept the parser schema-first, with LoD only as a geometry selector.

Current stage:

```text
Geometry/opening parser refinement is mostly complete, but needs syntax/runtime verification after the last edits.
```

## Important Known Gaps

### 1. Multizone shared surfaces by geometry

Current multizone logic pairs interzone surfaces by shared `source_id`.

This works when:

```text
Zone A -> thermalBoundary #same_surface
Zone B -> thermalBoundary #same_surface
```

But valid real ADE can duplicate the same physical face with different IDs:

```text
Zone A -> z1_ceiling_1
Zone B -> z2_floor_1
```

These may have the same polygon geometry but different IDs. The current code would treat them as two separate exterior/adiabatic faces unless another relation links them.

Needed later:

```text
Interzone matching priority:
1. Same source_id
2. Explicit RelationToCityObject or other ADE relation if present
3. Geometry match with tolerance
```

### 2. RelationToCityObject fallback

Energy ADE allows thermal boundaries/openings to relate to corresponding normal building thematic surfaces/openings.

We do not yet use this relation.

Needed later:

If a thermal boundary lacks some data, follow the relation to the corresponding building surface/opening and try there before using defaults.

### 3. Window hole validation

Energy ADE says LoD3 thermal openings should fill the hole in the thermal boundary.

Current parser:

- reads explicit LoD3 window geometry
- ignores parent wall interior rings
- does not validate coplanarity or hole filling

This is acceptable for initial IDF writing, but not full validation.

### 4. Geographic CRS for explicit windows

Earlier review found that explicit windows are recentred but may not be reprojected if the source CRS is geographic.

Needed later:

Apply the same CRS transform path to window points as to surface points.

### 5. EnergyPlus vertex limits

EnergyPlus fenestration polygons can have practical restrictions. Current code does not split complex window polygons.

Needed later:

Validate/simplify/split windows if EnergyPlus rejects them.

### 6. Construction/material priority

Still needs the next step.

Target waterfall:

```text
1. If construction/material libraryCode exists in Excel/database, use Excel values.
2. Else parse Energy ADE LayeredConstruction/Layer/Material values from CityGML.
3. Else use project fallback/default construction/material.
```

Need to check against:

```text
citygml2idf/validation_file/Alderaan_Energy_ADE_Material_Layered_Construction_Libraries.gml
```

and XSD:

```text
Energy_ADE_3.0_beta7.xsd
```

Relevant schema chain:

```text
LayeredConstructionLibrary
  -> libraryMember
      -> LayeredConstruction
          -> layer
              -> Layer
                  -> thickness
                  -> material
                      -> SolidMaterial or Gas
```

### 7. Detailed window material writing

Current writer uses a default/simple glazing route.

Future target:

If detailed window data exists, write EnergyPlus objects such as:

```text
WindowMaterial:Glazing
WindowMaterial:Gas
Construction
```

instead of only `WindowMaterial:SimpleGlazingSystem`.

## Recommended Next Session Start

Start with verification:

```powershell
python -m py_compile citygml2idf\citygml\xml_io.py citygml2idf\semantics\building_surfaces.py citygml2idf\model\openings.py citygml2idf\model\zones.py citygml2idf\model\constructions.py
```

Then run parser probes:

```powershell
python -c "from citygml2idf.citygml import xml_io; from citygml2idf.model.reader import build_middle_layer; doc=xml_io.CityGMLDoc('citygml2idf/validation_file/Alderaan_Energy_ADE_Core_Building_physics.gml'); m=build_middle_layer(doc); print([(b['id'], len(b['surfaces']), len(b.get('zones', [])), sum(len(s.get('windows', [])) for s in b['surfaces'])) for b in m['buildings'][:3]])"
```

Then continue with:

```text
Step 3: construction/material parser audit and fix
```

Focus files:

```text
citygml2idf/model/constructions.py
citygml2idf/validation_file/Alderaan_Energy_ADE_Material_Layered_Construction_Libraries.gml
citygml2idf/validation_file/Energy_ADE_3.0_beta7.xsd
```

Main question for the next step:

```text
Does constructions.py really implement Excel-first, then Energy ADE waterfall, then project default, following LayeredConstruction/Layer/Material schema?
```

## Update 2026-06-27: Geometry And Next Order

### Agreed Work Order

The robust parser should be hardened in this order:

```text
1. Geometry
2. Construction/material
3. Zones and multizone ownership
4. Windows/openings
5. Writer/IDF EnergyPlus validation
```

Reason:

```text
Geometry is the base object graph.
Construction/material attaches to surfaces/zones/windows.
Zone/multizone logic needs stable surface ownership.
Windows need stable host surfaces and construction/material support.
The writer should be validated after the middle layer is semantically reliable.
```

So we should not jump directly to multizone/window writer details until geometry and construction/material are checked against the schema and official samples.

### New Validation Folder

The schema source was moved to:

```text
citygml2idf/validation_file/CityGml_ADE_SChema/
```

It contains:

```text
Energy_ADE_3.0_beta7.xsd
building.xsd
cityGMLBase.xsd
cityObjectGroup.xsd
xAL.xsd
gml3.1.1base/
codelists/
```

`citygml2idf/citygml/xml_io.py` was updated so validation uses:

```text
validation_file/CityGml_ADE_SChema/Energy_ADE_3.0_beta7.xsd
```

and resolves imports/includes from:

```text
CityGml_ADE_SChema/
CityGml_ADE_SChema/codelists/
CityGml_ADE_SChema/gml3.1.1base/
```

After adding the missing `dictionary.xsd`, this passed:

```text
Alderaan_Energy_ADE_All.gml
XSD validation: PASSED
```

### Geometry Logic Confirmed

The geometry parser now follows this schema-first source priority:

```text
1. ThermalZone -> thermalBoundary -> BoundarySurface
2. If coincidesWithLod2Hull/coincidesWithLod3Hull is true, use Building -> boundedBy shell
3. If no thematic surfaces exist, use selected LoD solid/multisurface fallback
```

This matches the Energy ADE specification:

```text
Normal LoD2/LoD3 case:
  thermal boundaries are explicit thematic surfaces.

Special LoD2/LoD3 hull case:
  no thermal boundaries are required; use building thematic shell surfaces.

LoD1:
  thermal zones may have solid geometry; no thermal boundaries/openings.
```

### BuildingPart Strategy

We chose Option A:

```text
Treat Building + BuildingParts as one IDF building.
```

In practice:

```text
BuildingPart surfaces/zones are included in the parent Building output.
```

This is documented in `citygml2idf/semantics/building_surfaces.py`.

### Geometry Fixes Completed

#### 1. Validation Path

File:

```text
citygml2idf/citygml/xml_io.py
```

Updated validation constants:

```text
VALIDATION_ROOT
VALIDATION_SCHEMA_DIR
ENERGY_XSD
```

to use the new schema folder.

#### 2. LoD1 Solid Fallback Scope

File:

```text
citygml2idf/semantics/building_surfaces.py
```

Problem:

```text
_solid_faces() collected every descendant gml:surfaceMember.
For LoD1 box buildings, this mixed lod0FootPrint polygons with lod1Solid faces.
```

Fix:

```text
_solid_faces(doc, building, lod)
```

now reads only selected geometry containers:

```text
bldg:lod1Solid / bldg:lod1MultiSurface
bldg:lod2Solid / bldg:lod2MultiSurface
bldg:lod3Solid / bldg:lod3MultiSurface
```

on the parent Building and its BuildingParts.

Probe result after fix:

```text
id_box_building_20: LOD1, surfaces=6
first=['id_lod1_Polygon_1', ..., 'id_lod1_Polygon_6']
```

So the LoD0 footprint is no longer mixed into LoD1 EnergyPlus surfaces.

### Geometry Probe Results

For:

```text
Alderaan_Energy_ADE_All.gml
```

normal explicit thermal-boundary geometry was used:

```text
id_building_1: LOD3, surfaces=7, thermal_id_surfaces=7
id_building_9-10: LOD3, surfaces=16, thermal_id_surfaces=16
id_building_11: LOD3, surfaces=13, thermal_id_surfaces=13
```

For:

```text
Alderaan_Energy_ADE_Core_Building_physics_CoincidesWithLoD2Hull.gml
```

building shell geometry was used, as required:

```text
id_building_1: LOD2, surfaces=7, thermal_id_surfaces=0
id_building_9-10: LOD2, surfaces=16, thermal_id_surfaces=0
```

Interpretation:

```text
thermal_id_surfaces > 0
  means ThermalZone -> thermalBoundary surfaces drive geometry.

thermal_id_surfaces = 0 with coincidesWithLod2Hull true
  means Building -> boundedBy shell surfaces drive geometry.
```

### Zone And Multizone Concepts To Use Later

Energy ADE boundary classes:

```text
PartyWallSurface
IntermediateFloorSurface
AtticFloorSurface
BasementCeilingSurface
```

Meaning:

```text
PartyWallSurface:
  vertical boundary between adjacent buildings or adjacent thermal zones.

IntermediateFloorSurface:
  horizontal boundary between two modelled thermal zones.

AtticFloorSurface:
  horizontal boundary below an unmodelled attic/empty space.

BasementCeilingSurface:
  horizontal boundary above an unmodelled basement/garage/empty space.
```

EnergyPlus conversion idea:

```text
If two modelled zones share the same physical boundary:
  Outside Boundary Condition = Surface
  create reciprocal paired surfaces.

If only one modelled zone owns the boundary:
  keep its mapped default boundary, usually Outdoors/Ground/Adiabatic depending on type.
```

Known future multizone gap:

```text
Current code pairs interzone surfaces by same source_id.
Valid ADE may duplicate the same physical face with different IDs.
Later we need pairing by:
  1. same source_id
  2. explicit RelationToCityObject if present
  3. geometry match with tolerance
```

### Remaining Geometry Limitations

Do not claim "any valid CityGML geometry" yet.

Still limited:

```text
1. MultiSurface with multiple polygons under one BoundarySurface is now split
   into part surfaces, but overlap/duplicate-area validation is still pending.
2. gml:pos and gml:coordinates are not fully handled; posList is the main path.
3. Curves/non-planar/complex GML geometry are not fully handled.
4. Interior rings/holes are ignored, though windows are written separately.
5. LoD0 is not converted to EnergyPlus surfaces, which is acceptable for our energy model path.
```

Current accurate status:

```text
Geometry is robust for the main official Alderaan Energy ADE patterns and our chosen Building+BuildingParts-as-one-IDF strategy.
```

### Next Step

Continue with construction/material, not zones/windows yet.

Next files:

```text
citygml2idf/model/constructions.py
citygml2idf/validation_file/Alderaan_Energy_ADE_Material_Layered_Construction_Libraries.gml
citygml2idf/validation_file/CityGml_ADE_SChema/Energy_ADE_3.0_beta7.xsd
```

Main schema chain to verify:

```text
LayeredConstructionLibrary
  -> libraryMember
      -> LayeredConstruction
          -> layer
              -> Layer
                  -> thickness
                  -> material
                      -> SolidMaterial or Gas
```

Main implementation question:

```text
Does constructions.py implement:
  Excel/database by libraryCode first,
  then Energy ADE values,
  then project defaults?
```

## Update 2026-06-27: Construction And Material Step

### Schema Rules Used

Source XSD:

```text
citygml2idf/validation_file/CityGml_ADE_SChema/Energy_ADE_3.0_beta7.xsd
```

Relevant XSD chain:

```text
MaterialLibrary
  -> libraryMember
      -> AbstractMaterial
          -> Gas or SolidMaterial

LayeredConstructionLibrary
  -> libraryMember
      -> LayeredConstruction or ReverseLayeredConstruction

LayeredConstruction
  -> libraryCode [0..1]
  -> uValue [0..1]
  -> layer [0..* ordered]
      -> Layer
          -> thickness
          -> material
              -> AbstractMaterial property, usually xlink to Gas/SolidMaterial

ReverseLayeredConstruction
  -> baseLayeredConstruction
      -> LayeredConstruction property
```

Important XSD line areas:

```text
LayeredConstructionLibraryType: libraryMember
LayerType: thickness + material
LayeredConstructionType: libraryCode, uValue, layer
MaterialLibraryType: libraryMember
ReverseLayeredConstructionType: baseLayeredConstruction
SolidMaterialType / GasType: material physical values
```

Official sample used:

```text
citygml2idf/validation_file/Alderaan_Energy_ADE_Material_Layered_Construction_Libraries.gml
citygml2idf/validation_file/Alderaan_Energy_ADE_All.gml
```

### Changes Made

#### 1. Same-document bare XLinks

File:

```text
citygml2idf/citygml/xml_io.py
```

Changed:

```text
CityGMLDoc.resolve_xlink()
```

Before:

```text
Only xlink:href="#id" resolved locally.
```

Now:

```text
xlink:href="#id" resolves locally.
xlink:href="id" also resolves locally if that gml:id exists in the same document.
```

Why:

The official Alderaan sample uses bare local references in construction/material places, for example:

```xml
<nrg3:material xlink:href="id_solid_material_1"/>
```

and:

```xml
<nrg3:layeredConstruction xlink:href="id_reverse_layered_construction_ground_1"/>
```

The parser should treat these as same-document references, not external links.

#### 2. Ordered Layer Parsing

File:

```text
citygml2idf/model/constructions.py
```

Changed:

```text
_from_citygml()
```

Before:

```text
Used all descendant nrg3:Layer elements.
```

Now:

```text
Uses direct ordered nrg3:layer property children of the current LayeredConstruction.
Each layer property is resolved with property_object(), so inline and xlink forms both work.
```

Why:

The XSD defines:

```text
LayeredConstruction -> layer [0..* ordered]
```

Layer order matters for EnergyPlus construction layers and for Energy ADE reverse constructions.

#### 3. Thickness Unit Conversion

File:

```text
citygml2idf/model/constructions.py
```

Added:

```text
_child_measure()
_length_to_meters()
```

Now supported:

```text
m  -> metres
mm -> metres
cm -> metres
unknown -> warning, assume metres
```

Why:

Official Alderaan layers use values such as:

```xml
<nrg3:thickness uom="mm">10</nrg3:thickness>
```

EnergyPlus `Material` expects thickness in metres, so this must become:

```text
0.01
```

#### 4. Layer-specific EnergyPlus Material Names

File:

```text
citygml2idf/model/constructions.py
```

Changed:

```text
_material_from_citygml()
```

Now CityGML material objects become EnergyPlus material names like:

```text
id_layer_6_id_solid_material_6
id_layer_8_id_gas_1
```

Why:

Energy ADE separates:

```text
Layer.thickness
Material.physical properties
```

but EnergyPlus `Material` stores thickness inside the material object. If the same `SolidMaterial` is reused in two layers with different thicknesses, EnergyPlus needs two different material objects.

#### 5. ReverseLayeredConstruction

File:

```text
citygml2idf/model/constructions.py
```

Added support for:

```text
ReverseLayeredConstruction -> baseLayeredConstruction
```

Behavior:

```text
resolve base LayeredConstruction
parse its layers
reverse the layer order
use the reverse construction id as the construction name
```

Example verified:

```text
id_reverse_layered_construction_ground_1
  base id_layered_construction_ground_1
  layers reversed from layer 5 to layer 1
```

#### 6. uValue-only Construction Fallback

File:

```text
citygml2idf/model/constructions.py
```

Added:

```text
If a LayeredConstruction has no layers but has uValue,
create an EnergyPlus Material:NoMass using R = 1 / U.
```

Example verified:

```text
id_layered_construction_glazing_5
uValue = 1.9
R = 0.5263157894736842
```

Note:

This is a construction fallback. Detailed window material writing is still a later window step.

#### 7. Excel Missing Does Not Break CityGML Fallback

File:

```text
citygml2idf/model/constructions.py
```

Changed:

```text
resolve_all()
```

Before:

```text
If the Excel file was missing/unreadable, construction parsing could fail before CityGML fallback.
```

Now:

```text
If Excel cannot load, warn once and continue with empty Excel maps.
Then CityGML construction/material parsing still runs.
```

### Construction Priority Now Implemented

For each parsed surface:

```text
1. Find nrg3:layeredConstruction on the surface.
2. Resolve inline or xlink construction object.
3. Read construction libraryCode.
4. If libraryCode exists in Excel constructions sheet, use Excel layers/materials.
5. Else parse CityGML:
     LayeredConstruction layers, or
     LayeredConstruction uValue, or
     ReverseLayeredConstruction base reversed.
6. Else use project default construction/material.
```

### Validation/Probe Results

Syntax check:

```text
python -m py_compile citygml2idf\citygml\xml_io.py citygml2idf\model\constructions.py
PASSED
```

XSD validation:

```text
Alderaan_Energy_ADE_Material_Layered_Construction_Libraries.gml
XSD validation: PASSED

Alderaan_Energy_ADE_All.gml
XSD validation: PASSED
```

Material/construction library probe:

```text
Gas: 2
SolidMaterial: 16
LayeredConstruction: 5
ReverseLayeredConstruction: 2
```

Examples verified:

```text
id_layered_construction_wall_2
  source citygml
  thickness 10 mm -> 0.01 m
  gas layer -> Material:AirGap

id_layered_construction_glazing_5
  source citygml
  no layers, uValue 1.9 -> Material:NoMass R=0.5263157894736842

id_reverse_layered_construction_ground_1
  source citygml
  base id_layered_construction_ground_1
  layers reversed
```

Full Alderaan middle-layer probe:

```text
buildings: 22
surfaces: 165
constructions: 7
materials: 19
construction sources:
  citygml: 6
  default: 1
```

Interpretation:

```text
CityGML construction fallback works on the official full sample.
One default construction remains for geometry-only surfaces without construction data.
```

### Update After Layer-Order Discussion

We found the key Energy ADE specification text:

```text
LayeredConstruction contains thermal/optical properties for the construction
as a whole and optionally an ordered set of Layer objects.

Layers are ordered from the inside of a room towards the outside.

Conventionally, the order of the layers follows the direction of the normal
vector of the surface they refer to.

ReverseLayeredConstruction represents the same construction with the order of
layers inverted.
```

Interpretation agreed:

```text
XSD gives the structure/order of XML children.
Energy ADE specification gives semantic meaning to that order.
EnergyPlus requires Construction layers in outside-to-inside order.
Therefore the middle layer stores ADE order, and the IDF writer converts to
EnergyPlus order.
```

EnergyPlus rule used:

```text
Construction starts with Outside Layer and subsequent layers continue inward.
Material thickness is in metres.
Material conductivity is W/m-K.
Material density is kg/m3.
Material specific heat is J/kg-K and must be >= 100.
Material:AirGap thermal resistance is m2-K/W.
```

Reference:

```text
https://bigladdersoftware.com/epx/docs/23-1/input-output-reference/group-surface-construction-elements.html
```

### Additional Changes Made After Layer-Order Discussion

#### 8. Middle Layer Stores ADE Layer Order

Files:

```text
citygml2idf/model/constructions.py
citygml2idf/model/zones.py
citygml2idf/write/writer.py
```

Decision:

```text
Excel and CityGML both store/parse layer order as Energy ADE order:
inside -> outside.
```

Every resolved construction now carries:

```json
"layer_order": "inside_to_outside"
```

This applies to:

```text
Excel constructions
CityGML LayeredConstruction
CityGML ReverseLayeredConstruction after reversing its base
uValue-only fallback construction
default construction
interzone reversed construction created in zones.py
```

#### 9. Writer Converts ADE Order to EnergyPlus Order

File:

```text
citygml2idf/write/writer.py
```

Added:

```text
_energyplus_layers(construction)
```

Behavior:

```text
middle layer:
  layers = inside -> outside

IDF writer:
  Construction.Outside_Layer = outside layer
  so it reverses the middle-layer list before writing EnergyPlus.
```

This keeps parsing modular:

```text
Parser/middle layer = Energy ADE semantic model.
Writer = EnergyPlus-specific conversion.
```

#### 10. Excel Workbook Updated for One Alderaan Code

File changed:

```text
citygml2idf/input/construction_db.xlsx
```

Backup created:

```text
citygml2idf/input/construction_db.before_alderaan_excel_test.xlsx
```

Added Excel construction code matching the Alderaan GML:

```text
layered_constr_library_code_2
```

This code is found in Alderaan here:

```text
Alderaan_Energy_ADE_All.gml
LayeredConstruction id_layered_construction_wall_2
libraryCode layered_constr_library_code_2
```

Added Excel material rows, in Energy ADE order:

```text
EXCEL_ADE_Wall_L1_Plaster_10mm
EXCEL_ADE_Wall_L2_Brick_300mm
EXCEL_ADE_Wall_L3_AirGap_30mm
EXCEL_ADE_Wall_L4_Insulation_80mm
EXCEL_ADE_Wall_L5_Render_20mm
```

Purpose:

```text
Prove parser priority:
  if CityGML construction libraryCode exists in Excel -> use Excel
  otherwise -> use CityGML LayeredConstruction/Layer/Material fallback
```

#### 11. EnergyPlus Unit Guards Added

File:

```text
citygml2idf/model/constructions.py
```

Added:

```text
_specific_heat_to_j_per_kg_k()
_gas_resistance_for_energyplus()
```

Behavior:

```text
specificHeatCapacity:
  J/kg-K stays as-is
  kJ/kg-K converts to J/kg-K
  if value < 100, warn and use default 1000 J/kg-K

Gas rValue:
  only use directly if unit looks like m2-K/W
  otherwise warn and use 0.15 m2-K/W
```

Reason:

Official Alderaan values are schema-valid but not always EnergyPlus-valid, for example:

```xml
<nrg3:specificHeatCapacity uom="J/(kg*K)">0.9</nrg3:specificHeatCapacity>
```

EnergyPlus would reject or warn on values below its minimum.

#### 12. Construction Resolution Cache

File:

```text
citygml2idf/model/constructions.py
```

Change:

```text
resolve_all()
```

now reuses a resolved construction when many surfaces reference the same construction name.

Reason:

Avoid parsing the same construction repeatedly and avoid repeating identical unit warnings
for every wall/roof/ground surface.

### Alderaan Output2 Trace Generated

Generated folder:

```text
citygml2idf/output2/
```

Files:

```text
citygml2idf/output2/alderaan_first3_middle_layer.json
citygml2idf/output2/alderaan_first3_construction_trace.json
```

These were generated from:

```text
citygml2idf/validation_file/Alderaan_Energy_ADE_All.gml
```

for the first three buildings only:

```text
id_building_1
id_building_2
id_building_3
```

Result:

```text
used constructions:
  layered_constr_library_code_1: source=citygml, order=inside_to_outside, layers=5
  layered_constr_library_code_2: source=excel,  order=inside_to_outside, layers=5
  layered_constr_library_code_3: source=citygml, order=inside_to_outside, layers=5

surface construction sources:
  citygml: 9 surfaces
  excel: 14 surfaces
```

Interpretation:

```text
Wall construction code layered_constr_library_code_2 is now read from Excel.
Ground construction code layered_constr_library_code_1 is not in Excel, so it falls back to CityGML.
Roof construction code layered_constr_library_code_3 is not in Excel, so it falls back to CityGML.
```

Where to inspect:

```text
citygml2idf/output2/alderaan_first3_middle_layer.json
  -> parser/middle-layer result

citygml2idf/output2/alderaan_first3_construction_trace.json
  -> explicit trace showing:
       GML construction library
       surface -> construction mapping
       construction source
       middle_layers_inside_to_outside
       idf_layers_outside_to_inside
```

Important examples in trace:

```text
layered_constr_library_code_2:
  middle_layers_inside_to_outside:
    EXCEL_ADE_Wall_L1_Plaster_10mm
    EXCEL_ADE_Wall_L2_Brick_300mm
    EXCEL_ADE_Wall_L3_AirGap_30mm
    EXCEL_ADE_Wall_L4_Insulation_80mm
    EXCEL_ADE_Wall_L5_Render_20mm

  idf_layers_outside_to_inside:
    EXCEL_ADE_Wall_L5_Render_20mm
    EXCEL_ADE_Wall_L4_Insulation_80mm
    EXCEL_ADE_Wall_L3_AirGap_30mm
    EXCEL_ADE_Wall_L2_Brick_300mm
    EXCEL_ADE_Wall_L1_Plaster_10mm
```

### Current Status

Geometry:

```text
Main official Alderaan patterns are handled:
  ThermalZone -> thermalBoundary -> BoundarySurface
  coincidesWithLod2Hull/coincidesWithLod3Hull -> use building shell
  Building + BuildingParts treated as one IDF building
  LoD1 solid fallback no longer mixes LoD0 footprint geometry
  gml:surfaceMember xlink references resolved
```

Construction/material:

```text
Parser now follows:
  surface -> nrg3:layeredConstruction -> libraryCode
  Excel by libraryCode first
  CityGML LayeredConstruction/Layer/Material fallback
  ReverseLayeredConstruction support
  uValue-only fallback
  default fallback

Middle layer now stores ADE layer order.
Writer converts to EnergyPlus layer order.
Excel test proves source priority.
```

### Remaining Checks / Next Session

Do not claim the whole project is complete yet.

Geometry still needs later checks:

```text
1. Multiple polygons in one BoundarySurface / MultiSurface.
2. Interior rings/holes are ignored; windows are handled separately.
3. Complex GML geometry forms beyond posList are limited.
4. Geographic CRS handling for explicit windows still needs review.
```

Construction/material still needs later checks:

```text
1. LoD1 ThermalZone-level averaged construction:
   Energy ADE allows LayeredConstruction associated to ThermalZone.
   Current resolver mainly attaches construction per parsed surface.

2. RelationToCityObject fallback:
   If a thermal boundary lacks construction but corresponding building shell
   surface has it, we do not yet follow RelationToCityObject.

3. Detailed window materials:
   Current window writer still uses SimpleGlazingSystem.
   Later target is WindowMaterial:Glazing / WindowMaterial:Gas when detailed
   ADE data is available.

4. More unit conversions:
   Thickness and specific heat/gas-rValue guards exist.
   Other units should be checked before trusting real physical simulation.

5. IDF/EnergyPlus validation after construction changes:
   Need run IDF writer/EnergyPlus for a controlled sample after we agree the
   middle layer is correct.
```

Recommended next start:

```text
1. Read this SESSION_HANDOFF.md.
2. Open output2/alderaan_first3_construction_trace.json.
3. Compare:
     Alderaan_Energy_ADE_All.gml construction library
     construction_db.xlsx Excel override
     middle layer source tags
     writer EnergyPlus layer reversal
4. Then move to zones/multizone ownership, or first run IDF validation for
   geometry + construction/material only.
```

## Next Session Starting Point: Finish Geometry + Construction/Material First

This is the exact order agreed before moving further:

```text
1. Geometry
   Parse surfaces correctly, handle LoD2/LoD3, coincidesWithLoD2Hull,
   BuildingParts, XLinks, and write valid BuildingSurface:Detailed.

2. Construction + Material
   Resolve LayeredConstruction, ReverseLayeredConstruction, Layer,
   SolidMaterial, Gas, Excel priority, CityGML fallback, defaults,
   unit conversion, and EnergyPlus layer order.

3. Test IDF with only these
   One building, one zone, no windows first.
   The IDF should contain only geometry, materials, constructions, zones,
   and opaque surfaces.

4. Zone / Multizone
   Then audit thermal zones, interzone surfaces, PartyWallSurface,
   IntermediateFloorSurface, AtticFloorSurface, BasementCeilingSurface,
   and EnergyPlus boundary pairing.

5. Windows
   Last: explicit LoD3 windows, ratio fallback, detailed glazing/gas
   materials, and writer support for FenestrationSurface:Detailed.
```

Current audit estimate:

```text
Geometry + construction + material are about 65-70% audited.
Do not move to multizone/window work until the remaining items below are
checked and a clean opaque-only IDF is produced and run.
```

What is already in good shape:

```text
XLink / inline resolver.
Building + BuildingPart grouping.
ThermalBoundary vs coincidesWithLoD2Hull geometry path.
LoD2/LoD3 surface extraction.
LayeredConstruction parsing.
Layer order from Energy ADE: inside-to-outside.
Writer reverses to EnergyPlus outside-to-inside.
Excel-priority test exists.
CityGML fallback exists.
Basic EnergyPlus material objects are written.
```

What remains before trusting geometry + construction/material IDF physics:

```text
Validate units for thermalConductivity, density, uValue, rValue.
Fix gas handling: do not silently use 0.15 when rValue is not m2-K/W.
Preserve raw CityGML material data in middle layer/trace even when Excel wins.
Check ReverseLayeredConstruction with a real sample.
Generate a clean opaque-only IDF from Alderaan geometry/construction/material
and run EnergyPlus.
Inspect IDF material/construction order manually against source GML.
Update trace output so every material says:
  source
  raw_uom
  converted_value
  eplus_unit
  fallback_used
```

Important material/unit note from the last discussion:

```text
EnergyPlus Material:
  Thickness: m
  Conductivity: W/m-K
  Density: kg/m3
  Specific Heat: J/kg-K
  Roughness: keyword
  Thermal/Solar/Visible Absorptance: fractions

EnergyPlus Material:NoMass:
  Thermal Resistance: m2-K/W
  Roughness and absorptance fields.

EnergyPlus Material:AirGap:
  Thermal Resistance: m2-K/W.

Energy ADE Gas.rValue is only gml:MeasureType in the schema.
In Alderaan, gas_code_1 has rValue=8.314 with uom="J/K/mol".
That is not directly usable as EnergyPlus Material:AirGap thermal resistance.
The parser must preserve the raw value and mark it not convertible, then use
Excel or an explicit fallback for IDF generation.
```

## 2026-06-28 Checkpoint: Geometry + Construction/Material

Current agreed scope:

```text
Keep testing geometry + construction + material only.
Use one forced IDF zone and no windows for this audit.
Do not move to multizone/window logic until material units are fixed/traced.
```

Parser changes now in place:

```text
semantics/lod.py was renamed to semantics/building_surfaces.py because it is not
the main parser logic by LoD. It collects envelope surfaces from valid schema
relationships and uses LoD only to choose the geometry child.

reader.py now imports building_surfaces.

Building + nested BuildingParts are treated as one IDF building:
  Building -> consistsOfBuildingPart -> BuildingPart geometry/surfaces are included
  under the parent Building output, not emitted as separate buildings.

Each parsed surface now carries construction_context_ids:
  surface itself first
  ThermalZone if there is one clear owning zone
  BuildingPart/Building holder
  parent Building

constructions.py now resolves construction candidates in this order:
  surface layeredConstruction
  context layeredConstruction from ThermalZone / BuildingPart / Building
  Excel by libraryCode
  CityGML LayeredConstruction/Layer/Material fallback
  DEFAULT_CONSTRUCTION
```

Fresh Alderaan opaque-only output:

```text
Input:
  citygml2idf/validation_file/Alderaan_Energy_ADE_All.gml

Flags:
  FORCE_SINGLE_ZONE=True
  ENABLE_WINDOWS=False
  DEFAULT_WWR=None

Output folder:
  citygml2idf/output3/geometry_construction_material

Generated:
  buildings: 22
  buildings_with_surfaces: 22
  surfaces: 165
  windows: 0
  constructions: 7
  materials: 19
  idfs: 22
```

Important observations:

```text
id_building_1 is rich ADE LoD2/thermal-boundary geometry:
  7 surfaces
  construction_context_ids include id_thermal_zone_1 and id_building_1
  wall construction layered_constr_library_code_2 is resolved from Excel
  roof/ground constructions fall back to CityGML

id_box_building_20 is bare LoD1 solid geometry:
  6 classified surfaces
  construction_context_ids only includes id_box_building_20
  no reachable layeredConstruction/libraryCode exists in the GML
  DEFAULT_CONSTRUCTION is therefore correct

If a future LoD1/LoD1.2 building has a layeredConstruction/libraryCode on its
surface, ThermalZone, BuildingPart, or Building, the parser can now use that code
and resolve it through Excel first.
```

Still not acceptable for final construction/material trust:

```text
Gas.rValue with uom="J/K/mol" is still warned and falls back to 0.15 for IDF.
This must be changed so the raw value/uom are preserved in the middle layer/trace,
and the fallback is explicit.

Alderaan SolidMaterial specificHeatCapacity values are 0.9 with uom="J/(kg*K)".
EnergyPlus Material requires J/kg-K and value >= 100. The parser currently warns
and uses 1000. This needs a decision: sample data may be semantically bad, but
the parser must trace raw value, raw unit, converted value, E+ unit, and fallback.

A full EnergyPlus batch over all output3 IDFs has not yet been run after this checkpoint.
```

EnergyPlus spot-check after generating output3:

```text
id_box_building_20.idf:
  rc=0
  Severe=0
  Fatal=0

id_building_1.idf:
  rc=0
  Fatal=0
  Severe=1
  Severe was warmup convergence for the forced single zone, not an IDF object
  schema/material/construction syntax error.
```

Synthetic LoD1 averaged-construction fixture:

```text
Fixture:
  citygml2idf/input/test_lod1_avg_construction.gml

Purpose:
  Prove the Energy ADE LoD1 case where a single ThermalZone carries one
  averaged layeredConstruction for the whole LoD1 solid hull.

Why synthetic:
  Alderaan_Energy_ADE_All.gml has rich LoD2/thermal-boundary buildings with
  construction on the boundary surfaces, and bare LoD1 box buildings with no
  thermalZone/layeredConstruction. It does not contain the exact LoD1 averaged
  construction pattern.

Observed parser result:
  1 building
  6 raw classified LoD1 solid faces
  every face has construction_context_ids:
    test_lod1_zone
    test_lod1_avg_building
  construction layered_constr_library_code_2 resolved from Excel
  source_context_id = test_lod1_zone

Trace:
  citygml2idf/output3/geometry_construction_material/test_lod1_avg_trace.json
  citygml2idf/output3/geometry_construction_material/test_lod1_avg_middle_layer.json

IDF:
  citygml2idf/output3/geometry_construction_material/idf/test_lod1_avg_building.idf

EnergyPlus result:
  rc=0
  Fatal=0
  Severe=1 warmup convergence only, not IDF schema/object error.

Limitation:
  This validates single-zone LoD1 averaged construction fallback. It does not
  validate LoD1 multizone solid parsing or coincident-face interzone matching.
```

Expanded LoD1 construction fixtures:

```text
Case C - Excel code only:
  citygml2idf/input/test_lod1_avg_construction.gml
  ThermalZone -> layeredConstruction xlink -> LayeredConstruction
  LayeredConstruction has libraryCode=layered_constr_library_code_2
  Excel contains that code, so construction source=excel
  Trace:
    citygml2idf/output3/geometry_construction_material/test_lod1_avg_construction_trace.json

Case A - CityGML inline layers/materials:
  citygml2idf/input/test_lod1_inline_layers_construction.gml
  ThermalZone -> layeredConstruction xlink -> LayeredConstruction
  LayeredConstruction has inline ordered Layer objects
  each Layer has thickness and material xlink to SolidMaterial
  construction source=citygml
  IDF EnergyPlus check: rc=0, Severe=0, Fatal=0
  Trace:
    citygml2idf/output3/geometry_construction_material/test_lod1_inline_layers_construction_trace.json

Case B - CityGML averaged uValue only:
  citygml2idf/input/test_lod1_uvalue_construction.gml
  ThermalZone -> layeredConstruction xlink -> LayeredConstruction
  LayeredConstruction has uValue=0.50 and no layers
  parser creates Material:NoMass with thermal_resistance=1/uValue=2.0
  construction source=citygml
  IDF EnergyPlus check: rc=0, Severe=0, Fatal=0
  Trace:
    citygml2idf/output3/geometry_construction_material/test_lod1_uvalue_construction_trace.json

All three fixtures produce 6 LoD1 solid faces. Every face has the same
ThermalZone-level averaged construction, with source_context_id equal to the
ThermalZone id. This validates the single-zone LoD1 construction cascade:
  Excel code -> CityGML inline layers -> CityGML uValue -> default.
```

Important correction from discussion:

```text
For valid Energy ADE LoD1, raw gml:Polygon solid faces are geometry only.
They must not be treated as objects that own layeredConstruction.

The valid LoD1 path is:
  Building
    -> lod1Solid
        -> gml:Polygon faces

  Building
    -> thermalZone
        -> ThermalZone
            -> layeredConstruction
                -> LayeredConstruction
                    -> libraryCode OR uValue OR layer/material

So LoD1 faces inherit the ThermalZone-level averaged construction for the whole
thermal hull. They do not each carry their own construction.

Code correction:
  citygml2idf/model/constructions.py
  _construction_element() now skips raw GML geometry owners such as gml:Polygon.
  Construction candidates are schema-valid CityObject contexts:
    BoundarySurface first, then ThermalZone / BuildingPart / Building.

Rechecked fixtures after correction:
  test_lod1_avg_construction:
    source=excel
    source_context_id=test_lod1_zone

  test_lod1_inline_layers_construction:
    source=citygml
    source_context_id=test_lod1_inline_zone

  test_lod1_uvalue_construction:
    source=citygml
    source_context_id=test_lod1_uvalue_zone
```

## Agreed Validation Order From Here

For now validate this stack first:

```text
1. Geometry
   LoD1 raw solid
   LoD2/LoD3 boundedBy / thermalBoundary
   coincidesWithLoD2Hull / coincidesWithLoD3Hull
   Building + BuildingParts

2. Construction + Material
   Excel by libraryCode
   CityGML LayeredConstruction -> Layer -> Material
   CityGML uValue fallback
   defaults only when no usable data exists
   correct EnergyPlus units
   Energy ADE layer order -> EnergyPlus layer order

3. One-zone IDF
   FORCE_SINGLE_ZONE=True
   ENABLE_WINDOWS=False
   validate opaque geometry/material/construction only
```

Then add windows:

```text
4. One-zone + windows
   explicit LoD3 Window geometry
   LoD2 ratio fallback
   total/opaque area fallback
   detailed glazing/gas later
```

Then multizone:

```text
5. Multizone
   ThermalZone ownership
   thermalBoundary surfaces
   PartyWallSurface
   IntermediateFloorSurface
   AtticFloorSurface
   BasementCeilingSurface
   EnergyPlus Surface boundary pairs
```

Reason:

```text
Multizone depends on the first parts being correct.
If geometry or construction is wrong, multizone bugs become hard to diagnose.
```

For LoD1 specifically:

```text
Single-zone first:
  ThermalZone -> layeredConstruction -> whole hull

Multizone later:
  multiple ThermalZone solids
  no thermalBoundary in LoD1
  shared/interzone surfaces found by coincident solid faces
```

Current next work:

```text
Finish geometry + construction + material audit for LoD1, LoD2, LoD3, one-zone.
Fix material unit tracing.
Run IDF/EnergyPlus checks.
Then windows.
Then multizone.
```

## Update 2026-06-28: Geometry Audit Completed For Current Checklist

This session continued the geometry audit from `MAPPING.md` and finished these
items:

```text
[x] coincidesWithLoD2Hull targeted test/recheck
[x] coincidesWithLoD3Hull targeted test/recheck
[x] LoD metadata should detect surface-level lod2/lod3MultiSurface
[x] MultiSurface with multiple polygons in one BoundarySurface
[x] Interior rings/holes in parent surfaces
[x] LoD0 policy: skip vs approximation/extrusion
```

### Source Rules Checked

Energy ADE / CityGML rules used:

```text
LoD2 special case 5.1:
  ThermalZone.coincidesWithLod2Hull = true
  no duplicate thermalBoundary objects are needed
  use Building -> bldg:boundedBy -> LoD2 thematic surfaces
  LayeredConstruction is associated to building thematic surfaces/openings

LoD3 special case 6.1:
  ThermalZone.coincidesWithLod3Hull = true
  no duplicate thermalBoundary/opening objects are needed
  use Building -> bldg:boundedBy -> LoD3 thematic surfaces/openings
  LayeredConstruction is associated to building thematic surfaces/openings

CityGML building.xsd:
  Building can have lod0FootPrint, lod1Solid, lod2/lod3 geometry, boundedBy,
  and BuildingParts.

Energy_ADE_3.0_beta7.xsd:
  ThermalZoneType defines:
    isCooled
    isHeated
    coincidesWithLod2Hull
    coincidesWithLod3Hull
    thermalBoundary
```

### What Was Changed

Files changed:

```text
citygml2idf/semantics/building_surfaces.py
citygml2idf/model/constructions.py
citygml2idf/model/openings.py
citygml2idf/model/zones.py
citygml2idf/citygml/xml_io.py
citygml2idf/MAPPING.md
```

New fixture files:

```text
citygml2idf/input/test_lod3_coincides_hull.gml
citygml2idf/input/test_multisurface_multiple_polygons.gml
citygml2idf/input/test_lod0_policy_footprint_only.gml
```

#### 1. coincidesWithLoD2Hull

Verified with official Delft sample:

```text
citygml2idf/validation_file/Alderaan_Energy_ADE_Core_Building_physics_CoincidesWithLoD2Hull.gml
```

Expected behavior:

```text
ThermalZone has coincidesWithLod2Hull=true
Parser skips thermalBoundary path
Parser uses Building/BuildingPart -> bldg:boundedBy shell surfaces
```

Probe result:

```text
id_building_1 LOD2 surfaces=7 thermal_path=0 hull_path=7
```

Meaning:

```text
The LoD2 hull-special-case geometry path is correct.
```

#### 2. coincidesWithLoD3Hull

No official `coincidesWithLod3Hull=true` sample was found in `validation_file`, so
a small schema-valid fixture was created:

```text
citygml2idf/input/test_lod3_coincides_hull.gml
```

Fixture structure:

```text
Building
  -> bldg:boundedBy
      -> GroundSurface/RoofSurface/WallSurface
          -> bldg:lod3MultiSurface
          -> optional bldg:opening -> bldg:Window -> bldg:lod3MultiSurface
  -> nrg3:thermalZone
      -> nrg3:ThermalZone
          -> nrg3:coincidesWithLod3Hull=true
          -> no nrg3:thermalBoundary
```

Validation:

```text
XSD validation: PASSED
```

Parser result:

```text
test_lod3_coincides_building LOD3 surfaces=6 thermal_path=0 hull_path=6
```

Staged outputs:

```text
citygml2idf/output/runs/test_lod3_coincides_building__1Z_noWin/
  surfaces=6
  windows=0
  EnergyPlus exit=0
  Severe/Fatal=0

citygml2idf/output/runs/test_lod3_coincides_building__1Z_Win/
  surfaces=6
  windows=1
  EnergyPlus exit=0
  Severe/Fatal=0
```

Meaning:

```text
The LoD3 hull-special-case path works:
  thermalBoundary is skipped
  bldg:boundedBy surfaces are used
  bldg:opening / bldg:Window is reused when windows are enabled
```

#### 3. LoD Metadata Detection

Problem found:

```text
Some valid files store LoD geometry only on BoundarySurface objects:
  bldg:boundedBy -> WallSurface -> lod2MultiSurface/lod3MultiSurface

Old detect_lod() only checked building-level lod1/lod2/lod3 solids/multisurfaces,
so some valid files parsed correctly but reported LODNone.
```

Fix:

```text
building_surfaces.detect_lod()
now also inspects:
  bldg:boundedBy -> BoundarySurface -> lodNMultiSurface
  nrg3:thermalZone -> nrg3:thermalBoundary -> BoundarySurface -> lodNMultiSurface
```

Verified:

```text
Official Delft LoD2 coincident hull sample:
  id_building_1 LOD 2 surfaces 7

LoD3 fixture:
  test_lod3_coincides_building LOD 3 surfaces 6
```

#### 4. MultiSurface With Multiple Polygons

Problem:

```text
CityGML/GML MultiSurface can contain multiple gml:surfaceMember polygons.
EnergyPlus BuildingSurface:Detailed represents one polygon surface, not a
disconnected set of polygons.

Old parser read only the first posList, silently losing extra polygons.
```

Fix:

```text
building_surfaces._surface_rings()
reads all surfaceMember polygons under one BoundarySurface.

Each polygon becomes its own middle-layer surface:
  source_id = original_id__part1
  source_id = original_id__part2

Each split part preserves:
  source_gml_id = original BoundarySurface gml:id
  surface_part_index
  surface_part_count
```

Why preserve `source_gml_id`:

```text
construction, openings, and zone ownership must still resolve against the
original CityGML object, not the generated EnergyPlus part id.
```

Related fixes:

```text
constructions.py:
  resolve construction using source_gml_id when present

zones.py:
  if a ThermalZone owns one original boundary id, it owns all split parts

openings.py:
  resolve openings using source_gml_id
  avoid duplicating one parent opening onto every split part
```

Fixture:

```text
citygml2idf/input/test_multisurface_multiple_polygons.gml
```

Validation:

```text
XSD validation: PASSED
```

Parser result:

```text
test_multisurface_building LOD 3 surfaces 7
test_multi_wall_south__part1 source_gml_id=test_multi_wall_south part 1/2
test_multi_wall_south__part2 source_gml_id=test_multi_wall_south part 2/2
```

EnergyPlus result:

```text
citygml2idf/output/runs/test_multisurface_building__1Z_noWin/
  surfaces=7
  windows=0
  EnergyPlus exit=0
  Severe/Fatal=0
```

Important remaining limitation:

```text
We handled MultiSurface splitting, but we did not yet handle overlap detection.

What is handled:
  - one BoundarySurface can contain multiple gml:surfaceMember polygons
  - each polygon becomes one middle-layer surface / one EnergyPlus
    BuildingSurface:Detailed object
  - source_gml_id is preserved so construction, zone ownership, and openings can
    still point back to the original CityGML BoundarySurface

What is not handled yet:
  - we do not check whether two polygons in the same MultiSurface overlap
  - XSD will not catch this because XSD validates XML structure, not geometry
  - if bad GML has overlapping surfaceMember polygons, the parser currently
    writes both to IDF
  - that can duplicate heat-transfer area, and EnergyPlus may not always report
    it as a fatal error

Decision needed before coding:
  - ask professor whether overlapping polygons should fail validation
  - or whether the parser should keep only the first polygon and warn
  - or whether the parser should merge/clean the polygons

Current recommendation:
  - keep the current split behavior for valid non-overlapping MultiSurface data
  - add a later geometry validation step for duplicate/overlapping polygons
```

#### 5. Interior Rings / Holes Policy

Policy decided:

```text
CityGML/GML parent wall polygons may have interior rings representing holes.
EnergyPlus BuildingSurface:Detailed has no hole field.

Therefore:
  parent opaque surface uses the exterior ring
  opening/window is written separately as FenestrationSurface:Detailed
```

Code note:

```text
xml_io.read_pos_list() now documents this policy.
```

Verified with:

```text
citygml2idf/input/test_lod3_coincides_hull.gml
```

Middle-layer check:

```text
test_lod3_wall_south:
  wall vertices = 4
  wall area = 100.0
  window = test_lod3_window_south
  window area = 16.0
```

Meaning:

```text
The parser does not try to put a hole into BuildingSurface:Detailed.
It keeps the exterior wall polygon and writes the window separately.
```

Remaining caution:

```text
If a split MultiSurface parent also has openings, current code prevents duplicate
windows, but exact assignment of the opening to the correct split polygon needs
the later window audit.
```

#### 6. LoD0 Policy

Policy decided:

```text
LoD0 footprint / roof edge is not enough to create valid EnergyPlus thermal
surfaces without inventing height/envelope geometry.

For now:
  detect LoD0
  warn clearly
  return zero thermal surfaces
  do not extrude or approximate
```

Fixture:

```text
citygml2idf/input/test_lod0_policy_footprint_only.gml
```

Validation:

```text
XSD validation: PASSED
```

Parser result:

```text
test_lod0_policy_building LOD 0 surfaces 0
WARNING: LoD0 footprint/roof edge cannot produce IDF thermal surfaces; skipped
```

### MAPPING.md Updated

`citygml2idf/MAPPING.md` was updated to mark these geometry items completed:

```text
[x] coincidesWithLoD2Hull hull selection
[x] coincidesWithLoD3Hull hull/opening selection
[x] LoD metadata detects surface-level lod2/lod3MultiSurface
[x] MultiSurface with multiple polygons splits into part surfaces
[ ] MultiSurface overlap/duplicate-area validation is not implemented yet
[x] Interior rings/holes policy
[x] LoD0 policy
```

Evidence paths were added for:

```text
citygml2idf/output/runs/test_lod3_coincides_building__1Z_noWin/
citygml2idf/output/runs/test_lod3_coincides_building__1Z_Win/
citygml2idf/output/runs/test_multisurface_building__1Z_noWin/
```

### Verification Commands Run

```text
XSD validation:
  test_lod3_coincides_hull.gml -> PASSED
  test_multisurface_multiple_polygons.gml -> PASSED
  test_lod0_policy_footprint_only.gml -> PASSED

EnergyPlus staged runs:
  test_lod3_coincides_building__1Z_noWin -> exit=0, Severe/Fatal=0
  test_lod3_coincides_building__1Z_Win   -> exit=0, Severe/Fatal=0
  test_multisurface_building__1Z_noWin   -> exit=0, Severe/Fatal=0

Syntax:
  py_compile passed for:
    building_surfaces.py
    constructions.py
    openings.py
    zones.py
    xml_io.py
```

### Current Status After This Session

Geometry for one-zone / opaque-first path is now much stronger:

```text
Handled and tested:
  LoD1 raw solid fallback
  LoD2/LoD3 thermalBoundary path
  LoD2 coincidesWithLod2Hull path
  LoD3 coincidesWithLod3Hull path
  Building + BuildingParts as one IDF building
  surface-level LoD metadata
  MultiSurface multiple polygons
  parent surface holes/openings policy
  LoD0 skip policy
```

Still not fully audited:

```text
Construction/material:
  raw unit/source tracing
  Gas.rValue when unit is not m2-K/W
  SolidMaterial specificHeat/density/conductivity unit validation
  ReverseLayeredConstruction targeted sample

Windows:
  explicit LoD3 windows in real Alderaan/full sample path
  ratio fallback
  total/opaque area fallback
  detailed glazing/gas material mapping
  split-parent-window assignment

Multizone:
  ThermalZone ownership re-audit after geometry changes
  PartyWallSurface / IntermediateFloorSurface / AtticFloorSurface / BasementCeilingSurface
  EnergyPlus reciprocal Surface pairs
  LoD1 multizone solid coincident-face matching

Full pipeline:
  full output3 EnergyPlus batch run still pending
```

### Recommended Next Start

Continue with construction/material audit before moving to windows/multizone:

```text
1. Preserve raw CityGML material values and uom in middle layer / trace.
2. Fix Gas.rValue handling:
     only write Material:AirGap if value is in m2-K/W or convertible.
3. Validate SolidMaterial units:
     thickness -> m
     conductivity -> W/m-K
     density -> kg/m3
     specific heat -> J/kg-K
4. Check ReverseLayeredConstruction with a real/targeted sample.
5. Generate a clean opaque-only IDF batch after material fixes.
```

## 2026-06-29 Session Note: Repo, Geometry Remainders, Construction Trace Start

### Repo State

The active GitHub repo is:

```text
https://github.com/spadesmace/CityGML_to_IDF.git
```

The correct local repo path is:

```text
C:\Users\smeys\OneDrive\Desktop\CityGMLtoIDF
```

Do not use or edit the old `MountainEC_tool` / `energycenterlab` repo for this project work.

EnergyPlus and FMU template folders are intentionally local-only and should not be pushed:

```text
citygml2idf/templates/EnergyPlus-*/
citygml2idf/templates/EnergyPlusToFMU/
```

Known local working-tree items at the start of this note:

```text
CLAUDE.md modified by user
EPLUS_RULES.md modified by user
citygml2idf/config.py modified by user
citygml2idf/RULES_code.md deleted locally
COVERAGE.md untracked
```

Do not revert or edit those unless the user asks.

### What Changed This Session

`citygml2idf/MAPPING.md` was updated to remember geometry gaps that are still not finished:

```text
[ ] MultiSurface overlap/duplicate-area detection
[ ] Unsupported CityGML surface classes: OuterFloorSurface, InteriorWallSurface, ClosureSurface, etc.
[ ] Complex GML geometry/curves not fully handled
[ ] Window assignment to split MultiSurface parts still needs later check
```

No parser code should be changed without first explaining the small step and checking it together.

### Geometry Status

Geometry is acceptable for the current one-zone / opaque-first audit path, with these known limits:

```text
Handled:
  semantic bldg:boundedBy surfaces
  raw solid fallback when no semantic surfaces exist
  LoD1 raw solid path
  LoD2/LoD3 thermalBoundary path
  coincidesWithLoD2Hull
  coincidesWithLoD3Hull
  Building + BuildingParts as one IDF building
  MultiSurface with multiple surfaceMember polygons split into separate IDF surfaces

Still open:
  overlap/duplicate-area detection for multiple polygons
  unsupported CityGML surface classes policy
  curves/complex GML geometry support
  assigning windows correctly when one parent MultiSurface is split into parts
```

Important note: XSD validation checks XML structure, not geometric correctness. It will not catch overlapping polygons.

### Construction / Material Source Rules To Keep In Mind

Energy ADE 3.0 layered construction rules we are following:

```text
Rule 7:
  MaterialLibrary is a top-level object.
  It contains Gas and SolidMaterial inline as libraryMember children.

Rule 8:
  LayeredConstructionLibrary is a top-level object.
  It contains LayeredConstruction and ReverseLayeredConstruction inline as libraryMember children.

Rule 4.8.3:
  LayeredConstruction can be simple, e.g. only uValue.
  Or it can contain ordered Layer objects.

Rule 4.8.4:
  Layer objects are inline under LayeredConstruction.
  Each Layer points to its material by XLink.

Rule 4.8.5:
  ReverseLayeredConstruction points to a base LayeredConstruction by XLink.
  It means the layer order must be inverted.
```

EnergyPlus target rules from `EPLUS_RULES.md`:

```text
Material:
  thickness -> m
  conductivity -> W/m-K
  density -> kg/m3
  specific heat -> J/kg-K
  absorptance defaults can stay 0.9 / 0.7 / 0.7 for now

Material:NoMass:
  thermal resistance -> m2-K/W

Material:AirGap:
  thermal resistance -> m2-K/W

Construction:
  EnergyPlus layer order is outside-to-inside.
  Energy ADE source order is treated as inside-to-outside.
  The writer must reverse the parsed layer order for IDF.
```

### Where Construction Code Currently Handles This

Main file:

```text
citygml2idf/model/constructions.py
```

Important current functions:

```text
_material_from_excel()
  creates middle-layer material from Excel values

_material_from_citygml()
  creates middle-layer material from Gas / SolidMaterial in CityGML

_from_excel()
  creates construction from Excel when libraryCode matches

_from_citygml()
  creates construction from CityGML layers, ReverseLayeredConstruction, or uValue

_construction_element()
  finds legally reachable nrg3:layeredConstruction from a CityObject owner

_construction_candidates()
  checks surface first, then context owners such as ThermalZone / BuildingPart / Building

_resolve_surface()
  chooses Excel first, then CityGML fallback, then default

resolve_all()
  assigns selected construction names to parsed surfaces
```

### Current Construction / Material Gap

The selection logic exists, but the trace is not strong enough yet.

For every surface construction decision, we want the middle layer / trace to show:

```text
surface_id
source_gml_id
candidate owners checked
selected owner
selected construction id
libraryCode
codeSpace
source = excel | citygml_layers | citygml_uvalue | default
why default was used, if default
raw CityGML value and uom
converted EnergyPlus value and unit
```

Current known code gaps:

```text
_construction_code()
  reads only libraryCode text, not codeSpace.

_from_citygml()
  returns source as citygml, but should distinguish citygml_layers vs citygml_uvalue.

_resolve_surface()
  returns the selected construction, but not the full decision path.

resolve_all()
  caches construction names, so trace must be added carefully without hiding per-surface owner checks.

Gas.rValue
  must not silently become Material:AirGap unless the value is already m2-K/W or convertible.
```

### Next Start

Start construction/material work with a trace-only patch. Do not change selection behavior first.

Planned first patch:

```text
1. Add a helper that reads libraryCode text and codeSpace.
2. Add a helper that records candidate owners checked.
3. Add construction_trace to each surface.
4. Keep Excel -> CityGML -> default behavior unchanged.
5. Run small probes and compare trace directly against GML before touching IDF writer behavior.
```

After trace exists, test these cases together:

```text
1. Poor LoD1 / box building:
     should use default and explain no reachable layeredConstruction.

2. LoD1 averaged construction fixtures:
     ThermalZone -> layeredConstruction -> Excel match
     ThermalZone -> layeredConstruction -> CityGML inline layers
     ThermalZone -> layeredConstruction -> CityGML uValue

3. Rich Alderaan building:
     surface or thermalBoundary construction should resolve from real GML.

4. Mixed Alderaan output:
     compare middle-layer trace to direct GML before trusting IDF material/construction output.
```

## 2026-06-29 Session Note: Construction / Material Trace Implemented

### What Changed In Code

Main file changed:

```text
citygml2idf/model/constructions.py
```

Construction/material parsing is now more traceable and safer:

```text
[x] Added libraryCode + codeSpace reading for LayeredConstruction.
[x] Added per-surface construction_trace.
[x] Trace records candidate owners checked:
      surface
      ThermalZone
      BuildingPart / Building context where available
[x] Trace records selected owner, selected construction id, libraryCode, codeSpace, source, and why default.
[x] Split CityGML fallback source into:
      citygml_layers
      citygml_uvalue
[x] Preserved raw CityGML material values and uom in middle layer.
[x] Stored converted EnergyPlus units/values in material dicts.
[x] Added conductivity, density, thickness, specific heat, and uValue conversion helpers.
[x] Gas.rValue no longer silently becomes 0.15.
```

Important behavior after this session:

```text
SolidMaterial:
  thermalConductivity -> W/m-K
  density             -> kg/m3
  specificHeat        -> J/kg-K, EnergyPlus minimum enforced at 100
  Layer.thickness     -> m

LayeredConstruction with only uValue:
  uValue W/m2-K -> R = 1/uValue m2-K/W -> Material:NoMass

Gas:
  if rValue unit is m2-K/W -> Material:AirGap
  if rValue unit is not thermal resistance, e.g. J/K/mol -> do NOT convert to AirGap;
  keep raw data and use default material for that layer for now.
```

### Test Outputs Created

New generated test output root:

```text
citygml2idf/test_outputs/
```

Each numbered folder contains:

```text
README.md
middle_layer_geometry_construction_material.json
construction_material_trace_summary.json
```

Created outputs:

```text
output01_lod1_avg_excel_construction
  Source: citygml2idf/input/test_lod1_avg_construction.gml
  Building: test_lod1_avg_building
  Result: LoD1 ThermalZone-level layeredConstruction -> libraryCode -> Excel
  Source counts: excel = 6 surfaces

output02_lod2_coincides_default_construction
  Source: citygml2idf/validation_file/Alderaan_Energy_ADE_Core_Building_physics_CoincidesWithLoD2Hull.gml
  Building: id_building_1
  Result: coincidesWithLoD2Hull=true -> use bldg:boundedBy building shell
  Construction result: no layeredConstruction on surface, ThermalZone, or Building -> DEFAULT_CONSTRUCTION
  Source counts: default = 7 surfaces

output03_lod3_alderaan_excel_citygml_layers
  Source: citygml2idf/validation_file/Alderaan_Energy_ADE_All.gml
  Building: id_building_1
  Result: LoD3 thermalBoundary surfaces with surface-level layeredConstruction
  Source counts:
      citygml_layers = 3 surfaces
      excel          = 4 surfaces
```

### What We Verified Together

```text
[x] LoD1 averaged construction can resolve through ThermalZone-level layeredConstruction.
[x] LoD2 coincidesWithLoD2Hull uses the building shell instead of thermalBoundary surfaces.
[x] LoD2 default is explainable when no reachable layeredConstruction exists.
[x] LoD3 rich ADE path uses thermalBoundary surfaces.
[x] Surface-level layeredConstruction is found on LoD3 thermalBoundary surfaces.
[x] Excel priority works for libraryCode layered_constr_library_code_2.
[x] CityGML layer fallback works for ground/roof constructions.
[x] Middle layer now shows raw CityGML material values and EnergyPlus converted values.
[x] Bad Alderaan specificHeatCapacity values are preserved raw and converted to E+ safe 1000 J/kg-K.
[x] Gas rValue with unit J/K/mol is preserved raw and rejected for Material:AirGap thermal resistance.
```

### Important Source Logic Confirmed

Energy ADE / CityGML logic:

```text
LayeredConstruction can have:
  libraryCode
  uValue
  gValue / glazingRatio / optical fields
  ordered Layer[*]

Layer objects are inline under LayeredConstruction.
Layer.material is by XLink to Gas or SolidMaterial in MaterialLibrary.
Energy ADE layer order is inside-to-outside.
ReverseLayeredConstruction points by XLink to a base LayeredConstruction and reverses order.
```

EnergyPlus logic:

```text
Construction layers must be written outside-to-inside.
Writer reverses middle-layer inside_to_outside order for EnergyPlus.

Material requires:
  thickness m
  conductivity W/m-K
  density kg/m3
  specific heat J/kg-K, >= 100

Material:NoMass requires:
  thermal resistance m2-K/W

Material:AirGap requires:
  thermal resistance m2-K/W
```

Window note:

```text
ADE gValue can map to EnergyPlus SimpleGlazingSystem SHGC for simple window construction.
Detailed window materials are still later.
```

### Current Construction / Material Checklist Status

Done:

```text
[x] LayeredConstruction resolved from surface / ThermalZone / Building context.
[x] libraryCode read from CityGML.
[x] codeSpace traced.
[x] Excel priority when libraryCode exists in Excel.
[x] CityGML layer fallback when Excel does not win.
[x] Layer -> material XLink.
[x] SolidMaterial -> EnergyPlus Material.
[x] Layer.thickness -> metres.
[x] CityGML uValue -> Material:NoMass with R = 1 / U.
[x] Default construction only when no usable construction exists.
[x] Every surface has construction_trace explaining the decision.
[x] Raw CityGML material values preserved in middle layer.
[x] Converted EnergyPlus material values stored in middle layer.
[x] Gas rValue no longer blindly converted to 0.15.
[x] Bad gas rValue units like J/K/mol are flagged and defaulted.
[x] Energy ADE layer order stored as inside_to_outside.
[x] Writer reverses layers for EnergyPlus outside_to_inside.
```

Remaining:

```text
[ ] Re-run IDF/EnergyPlus after the construction.py changes.
[ ] Check ReverseLayeredConstruction with a real targeted output.
[ ] Check if Excel should match by code only or codeSpace + code.
[ ] Validate Excel required columns and units before trusting it.
[ ] Add clearer trace for Excel material raw/converted values.
[ ] Decide policy for bad SolidMaterial specificHeatCapacity:
      current behavior: if below E+ minimum, use 1000 and keep raw value.
[ ] Decide policy for Gas with non-resistance rValue:
      current behavior: default opaque material for that layer.
      possible future: skip layer, NoMass, or ask professor.
[ ] Check EnergyPlus maximum construction layer count before writer emits Construction.
[ ] Check Material:AirGap layer-position policy with EnergyPlus/professor.
[ ] Decide whether optical ADE fields on opaque LayeredConstruction
      emissivity / reflectance / transmittance / glazingRatio
      should be stored now or left for window phase.
[ ] Add detailed window construction tests later:
      WindowMaterial:Glazing + WindowMaterial:Gas.
```

### Next Recommended Start

Start next session from construction/material verification, not windows yet:

```text
1. Open output03 and inspect one Excel surface and one CityGML-layer surface.
2. Decide policy questions:
     code only vs codeSpace + code
     bad specificHeatCapacity
     Gas rValue not m2-K/W
3. Create targeted ReverseLayeredConstruction output.
4. Re-run opaque-only IDF/EnergyPlus with the new construction.py changes.
5. Update MAPPING.md checklist after those checks.
```

## 2026-06-30 Session Note: Two Middle-Layer Views Decision

Decision agreed:

```text
Alderaan_Energy_ADE_All.gml remains the main integration benchmark because it is the richest valid CityGML 2 + Energy ADE 3 sample we currently have.
Small extracted/targeted GML files are useful for teaching and debugging, but they do not replace Alderaan All as the parser confidence test.
```

Middle-layer architecture decision:

```text
The parser should produce two views from the same parser run, not two parser paths.

1. Trace/debug middle layer
   Full evidence for teaching and validation:
     raw CityGML ids
     source_gml_id
     candidate owners checked
     selected owner / construction
     libraryCode and codeSpace
     raw CityGML values and uom
     converted EnergyPlus values and units
     fallback reasons
     parser source = excel | citygml_layers | citygml_uvalue | default

2. IDF middle layer
   Clean writer contract only:
     buildings
     zones
     surfaces
     constructions
     materials
     windows/window_construction later
   All values here must already be EnergyPlus-ready.
```

Important modularity rule:

```text
writer.py must read only the IDF middle layer / clean writer fields.
writer.py must not know CityGML, Energy ADE schema, Excel lookup, XLinks, codeSpace, or fallback logic.
Trace/debug data is for parser audit only and should not be needed by writer.py.
```

Implementation direction started this session:

```text
reader.py should expose:
  build_trace_middle_layer(doc)  -> full debug/trace view
  to_idf_middle_layer(trace)     -> clean writer view from same parsed data
  build_idf_middle_layer(doc)    -> parse once and return clean IDF view

run.py should save both per-building files:
  middle_layer_trace_<building>.json
  middle_layer_idf_<building>.json

writer.py should use the IDF middle layer when run directly.
```

### Implementation Completed In Same Session

Files changed:

```text
citygml2idf/model/reader.py
citygml2idf/run.py
citygml2idf/write/writer.py
SESSION_HANDOFF.md
```

Implemented:

```text
reader.py:
  build_trace_middle_layer(doc)
    full parser/debug view; equivalent to old rich middle layer.

  to_idf_middle_layer(trace_middle)
    strips parser/debug fields and keeps only writer-needed EnergyPlus-ready data.

  build_idf_middle_layer(doc)
    parse once and return the clean writer view.

  build_both_middle_layers(doc)
    parse once and return (trace_middle, idf_middle).

  build_middle_layer(doc)
    kept as backward-compatible alias for the trace/full view.
```

```text
run.py:
  now builds both views from the same parser run.
  per building run folder now writes:
    middle_layer_trace_<building>.json
    middle_layer_idf_<building>.json
    middle_layer_<building>.json  # legacy alias for trace view
  writer receives the IDF middle layer only.
```

```text
writer.py:
  direct writer execution now calls build_idf_middle_layer(doc).
  EnergyPlus template path fixed from root/templates to citygml2idf/templates.
```

Verification:

```text
python -m py_compile citygml2idf/model/reader.py citygml2idf/run.py citygml2idf/write/writer.py
  passed

python -m citygml2idf.run --stage 1z-nowin --building id_building_11 Alderaan_Energy_ADE_All.gml
  produced both middle layers
  EnergyPlus launched successfully after IDD path fix
  exit=0
  remaining Severe: warmup convergence for ID_BUILDING_11_ZONE
```

Output checked:

```text
citygml2idf/output/runs/id_building_11__1Z_noWin/middle_layer_trace_id_building_11.json
  view=trace
  includes construction_trace and raw_citygml parser evidence

citygml2idf/output/runs/id_building_11__1Z_noWin/middle_layer_idf_id_building_11.json
  view=idf
  contains only clean writer fields
  confirmed absent:
    construction_trace
    raw_citygml
    fallback_reason
    candidate_owners_checked
    converted
```

Next caution:

```text
The writer path is now modular, but the id_building_11 EnergyPlus run still has a warmup convergence Severe.
That is an EnergyPlus/simulation-quality issue to inspect later, not a middle-layer split failure.
```
