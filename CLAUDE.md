# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A converter from **CityGML 2.0 + Energy ADE 3.0** building models to **EnergyPlus 23.1 IDF** files (one IDF per building). It is a thesis project; the Python package lives in [citygml2idf/](citygml2idf/). An earlier CityJSON-based iteration was superseded by this CityGML approach. The driving principle is **schema-first, not LoD-first**: the parser follows the Energy ADE / CityGML structure (ThermalZone → thermalBoundary → BoundarySurface → geometry/opening), and one robust path serves both test and real input.

## Canonical documents — read these first

Living docs drive the project and outrank anything inferred from code:

- [EPLUS_RULES.md](EPLUS_RULES.md) — **the single, authoritative EnergyPlus rulebook**: exactly what EnergyPlus requires of every IDF (geometry, materials, constructions, windows, multizone), each rule pinned to the local IDD marker + E+ Essentials / BigLadder I/O Reference with verified anchors. Never code an E+ rule from memory; if a parser policy disagrees with this file, **EnergyPlus wins**. *(Supersedes the removed `RULES_code.md`.)*
- [MAPPING.md](MAPPING.md) — the **source→IDF support matrix**: for every CityGML/ADE object, what the parser reads, what it means, where it lands in the middle layer, which EnergyPlus object is written, whether the path is tested, and what is missing (status markers `[x] [~] [ ] [!] [-]`).
- [COVERAGE.md](COVERAGE.md) — **which Energy ADE building models we can actually convert** (mapped to the spec's Table 2 cases), the per-concern handled/not-handled breakdown, the gap→file table, and the schema-grounded "where can a window legally come from per LoD" analysis.
- [SESSION_HANDOFF.md](SESSION_HANDOFF.md) — the **running session log / decisions** (dated; the thesis-report source). Keep it current each working session. *(This replaces the removed `process.md`.)*

## Authoritative reference sources (consult; never map from memory)

Every mapping decision must be cross-checked against a real source. **For any EnergyPlus rule, fetch the live docs** — do not rely on recollection:

- **EnergyPlus Essentials** (concepts, conventions, units/axes): <https://energyplus.readthedocs.io/>
- **EnergyPlus Input/Output Reference, v23.1** (BigLadder — exact object/field semantics): <https://bigladdersoftware.com/> (epx/docs)
- The vendored **`Energy+.idd`** (EnergyPlus 23.1) is the exact schema enforced at write time — field names, `\key` choices, required fields. Quote it as `Object:Field`.

For the source data model (CityGML / Energy ADE), also keep these at hand:
- **CityGML 2.0** OGC standard (OGC 12-019): <https://www.ogc.org/standard/citygml/>
- **Energy ADE 3.0** specification PDF + the **UML model / XSDs** (the Delft / SIG3D Energy ADE repository): <https://github.com/cstb/citygml-energy>. Spec §4.1 (inline vs byReference, geometry XLinks), §4.3.1 (ThermalZone per LoD, `coincidesWithLodXHull`), §4.3.2 (thermal boundaries) are the basis for the zoning/window rules.

When in doubt about `gValue`↔`SHGC`, layer order, boundary conditions, or any ADE element, open the spec/UML/XSD rather than guessing.

## Schema validation gate (`validation_file/`)

[citygml2idf/validation_file/](citygml2idf/validation_file/) holds the **official XSD schemas** for CityGML 2.0 + Energy ADE 3.0 (`CityGml_ADE_SChema/`, including `Energy_ADE_3.0_beta7.xsd`, the GML 3.1.1 base, and the ADE codelists), plus the **GML samples** (`Alderaan_Energy_ADE_*.gml`). **`Alderaan_Energy_ADE_All.gml` is the main canonical sample.** The parser runs a **best-effort offline XSD validation gate** before parsing ([xml_io.py](citygml2idf/citygml/xml_io.py)): a custom resolver serves each web-referenced import from this folder, so validation works without network. The samples PASS; the gate **warns and continues** if the schema can't be built — it never blocks a parse. Treat these XSDs as ground truth for what an ADE element is.

## The golden rule (project-wide invariant)

Trust **only** structure + geometry + explicit references (`xlink:href` and `(codeSpace, libraryCode)`). Never trust names, comments, or stated numbers. Specifically:
- **Geometry (vertices) is authoritative**: azimuth/tilt/area/height are computed from vertices, never read from `nrg3:bdgBdrySurfAzimuth`/`bdgArea`/etc. Stated attributes are only a cross-check (warn on mismatch).
- **A window is never invented**: emit a window only when the file provides a source. `DEFAULT_WWR` exists solely for testing and violates this rule by design — keep it `None` in production.
- On bad/imperfect input: **warn and continue**, never crash silently, never drop received geometry.

## Architecture — the one-way pipeline

Each folder has a single duty; data flows one direction into a **middle layer** that the writer is the only consumer of. The middle layer has **two views** (same parse, two shapes):

```
citygml/xml_io.py    ── the ONLY module that touches lxml/XML
      │                  (match by namespace URI not prefix; gml:id→element registry;
      │                   resolve xlinks, accepting "#id" AND bare "id")
      ▼
geometry/            ── pure math, no XML: rings.py (Newell normal, area, outward winding),
      │                  crs.py (EPSG parse, reproject-if-geographic, recenter),
      │                  classify.py (role from normal)
      ▼
semantics/           ── surface_types.py (CityGML/ADE type → E+ Surface_Type + boundary),
      │                  building_surfaces.py (one building's envelope, any LoD → uniform surface list)
      ▼
model/reader.py      ── orchestrates: builds the TRACE middle layer, wiring in
      │                  constructions.py → openings.py → zones.py, then derives the IDF view
      ▼
  middle layer ── TWO VIEWS:
      │   • trace : full parser evidence (construction_trace, raw_citygml, converted values,
      │             source ids, fallback reasons) — for audit/teaching/debugging
      │   • idf   : clean writer contract (buildings, zones, surfaces, constructions,
      │             materials, windows) — derived by to_idf_middle_layer()
      ▼
write/writer.py      ── IDF view → IDF via eppy, block by block; runs EnergyPlus
idf_building_visualize.py ── optional PNG preview of a building's surfaces
```

Key design facts worth knowing before editing:
- **Namespace matching by URI, not prefix.** `xml_io.NS` is the single place URIs live; the file's `nrg3:`/`energy:` prefix is irrelevant. The Energy ADE URI is auto-adopted from the file's nsmap.
- **Two distinct link mechanisms, kept separate:** (a) CityGML geometry shared by reference — a `gml:Solid`/`MultiSurface` holds `<surfaceMember xlink:href="#id">`, resolved O(1) via the id registry; (b) Energy ADE `nrg3:ThermalZone.thermalBoundary` xlinks zone→surface for ownership. `thermalBoundary` = zone↔surface ownership; `layeredConstruction` = surface→physics. There is **no** `ThermalBoundary` element in ADE 3.0 beta7 (confirmed against the XSD).
- **Extraction is presence-based, not LoD-driven.** `detect_lod` is recorded for info only; code branches on "are `nrg3:thermalBoundary` / labeled `bldg:boundedBy` surfaces present?", not on the LoD integer. LoD2/3 use labeled surfaces; LoD1 falls back to classifying raw solid faces by outward normal.
- **Two-view middle layer.** `build_trace_middle_layer` produces the rich audit view; `to_idf_middle_layer` strips it to what the writer needs. `build_both_middle_layers(doc)` returns `(trace, idf)`. **writer.py consumes only the idf view** — keep trace-only fields out of it.
- **Construction resolution is a catalogue waterfall keyed by `(codeSpace, code)`, never the bare code** (`model/constructions.py`). A construction and its materials find each other by `gml:id` (inline nesting or `xlink:href`); `libraryCode` (a `gml:CodeType` qualified by its `codeSpace`) is a separate catalogue key. Resolution order, each step bypassing the rest:
  1. **Excel/DB** by `(codeSpace, code)` → build from [construction_db.xlsx](citygml2idf/input/construction_db.xlsx);
  2. the construction's **own inline layers**;
  3. **in-file library** by `(codeSpace, code)` → a `LayeredConstructionLibrary` member not reached by xlink;
  4. **`uValue` → `Material:NoMass`** (R = 1/U), averaged (LoD1);
  5. generic **default** + warning.
  The xlsx **requires** a `code_space` column (blank cell = catalogue-agnostic, match by bare code). All spreadsheet-shape knowledge lives in `SHEET_NAMES`/`COLUMN_MAP` — swap the xlsx, change no code.
- **Interzone surfaces** (a face shared by two modelled zones of one building) become an **explicit reciprocal `Surface` pair** (BC=Surface, reversed twin, Floor↔Ceiling flipped, mirror `<name>_Rev` construction). Boundary is decided by **zone count, not the type name**. A face against the shell / another building / in a single-zone building → `Adiabatic`.
- **One IDF per building.** Each building is recentered to its own origin (min-corner→0,0, floor z=0); the shift is stored as `origin_offset`.

## Running it

Everything runs as a Python module from the **repo root** (`CityGMLtoIDF/`). The orchestrator + test harness is `run.py`:

```bash
python -m citygml2idf.run --stage real                       # all buildings, production path
python -m citygml2idf.run --stage mz-win --building Building_B3
python -m citygml2idf.run --stage 1z-nowin path/to/file.gml  # building id and/or .gml path are positional too
python -m citygml2idf.run --default-wwr 0.3 --building Building_B1   # TEST-ONLY synthesized windows
```

Each run lands in its own folder `citygml2idf/output/runs/<BuildingId>__<stage>/` holding the IDF, **both** per-building middle layers (`middle_layer_trace_<id>.json` = parser evidence, `middle_layer_idf_<id>.json` = clean writer contract), a PNG preview, and **all** EnergyPlus output (`.err`, `.dxf`, `.eio`, …). The `<stage>` tag comes from the active flags so stages never overwrite each other. [citygml2idf/test_outputs/](citygml2idf/test_outputs/) holds a **curated archive of representative example runs** (`output01_lod1…`, `output02_lod2…`, `output03_lod3…`, `output04_…`), each with a `README.md` explaining what it demonstrates.

Most modules are independently runnable as a self-test/demo (each prints verification numbers):

```bash
python -m citygml2idf.citygml.xml_io [path.gml]    # load, validate (best-effort XSD), prove xlink+posList
python -m citygml2idf.model.reader [path.gml]      # dump middle_layer_trace.json + middle_layer_idf.json, print envelope areas
python -m citygml2idf.model.constructions [path.gml]  # each surface's construction branch (EXCEL / CITYGML_LAYERS / …) + layers
python -m citygml2idf.write.writer [path.gml]      # full build + E+ run, report Severe/Fatal counts
```

## Testing model — staged, by flag, not a test framework

There is **no unit-test framework**. "Tests" are staged EnergyPlus runs (the ladder logged in [SESSION_HANDOFF.md](SESSION_HANDOFF.md)): build + run ONE capability at a time, keep each run's full output, and confirm `exit=0` with **0 Severe/Fatal** in `eplusout.err`. Three flags in [citygml2idf/config.py](citygml2idf/config.py) only *gate which path runs* — the parser is always full and robust:

| Flag | Production | Test use |
|---|---|---|
| `ENABLE_WINDOWS` | `True` | `False` → skip `openings.py`, every wall opaque |
| `FORCE_SINGLE_ZONE` | `False` | `True` → ignore `thermalBoundary`, merge building into one hull zone |
| `DEFAULT_WWR` | `None` | float → fabricate windows on a wall with no source (violates the golden rule; test only) |

Prefer `run.py --stage {1z-nowin, 1z-win, mz-nowin, mz-win, real}` over editing `config.py` — a stage applies overrides for that process only. After a run, scan `eplusout.err` for `** Severe`/`** Fatal` and view the `.dxf` (e.g. sharecad.org).

## Dependencies & external tooling (not vendored unless noted — must be supplied)

Python deps (no `requirements.txt` present): **lxml, pyproj, numpy, pandas, openpyxl** (xlsx I/O), **eppy** (IDF), **matplotlib** (the PNG preview in `idf_building_visualize.py`).

EnergyPlus is invoked as an external process. `write/writer.py` expects a `templates/` folder **inside the package** at [citygml2idf/templates/](citygml2idf/templates/) (`_TEMPLATES = <package>/templates`):
- `Energy+.idd` (the EnergyPlus 23.1 IDD — the schema eppy/the writer enforce),
- `EnergyPlus-23.1.0-87ed9199d4-Windows-x86_64/energyplus.exe` (the engine; `EnergyPlusToFMU/` toolchain also lives here),
- optionally `weather.epw`. Weather is modular: `WEATHER_EPW = None` → design-day-only IDF (no `RunPeriod`/result outputs); set it to an `.epw` → adds the annual `RunPeriod` + summary outputs.

Real sample `.gml` data + the validation XSDs ship under [citygml2idf/validation_file/](citygml2idf/validation_file/) (see "Schema validation gate" above); pass a `.gml` path explicitly, or point `xml_io.DEFAULT_INPUT` at one.
