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
- **A window is never invented**: emit a window only when the file provides a source (`openings.py` is presence-based — it fabricates nothing).
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
- **Construction resolution is the RAW CONVERTER — a most-detailed-first waterfall over the CityGML's OWN data** (`model/constructions.py`). A construction and its materials find each other by `gml:id` (inline nesting or `xlink:href`); `libraryCode` (a `gml:CodeType` qualified by its `codeSpace`) is a separate key used to find the layers in the file's own `LayeredConstructionLibrary`. Resolution order, each step bypassing the rest:
  1. **Tier 1 — DETAILED layers**: the construction's own inline `nrg:layer`, OR (if it carries only a `libraryCode`) the in-file `LayeredConstructionLibrary` member matched by `(codeSpace, code)`;
  2. **Tier 2 — AVERAGED `uValue` → `Material:NoMass`** (R = 1/U), the typical LoD1/hull case;
  3. **Tier 4 — generic default** + warning.
  **There is NO Excel.** The old `(codeSpace, code) → construction_db.xlsx` rung was removed (it mis-modelled the archetype and duplicated the in-file library). **Tier 3 — the EXTERNAL archetype fallback — is DEFERRED** and lives in `model/archetypes.py`: a **swappable JSON** table (`input/archetypes.json`) read generically as `key → values`, keyed by building **function + year + weight** (TABULA / UBEM-CARDs), NOT by `libraryCode`. It is **built but not wired** — raw converter first, and the shipped JSON is an empty placeholder so the tier is inert. We never invent the numbers: drop in the real JSON later (change the path, no code change) and confirm the key fields (`bldg:function`, `bldg:yearOfConstruction`, `nrg3:bdgConstructionWeight`) with the professor.
- **Interzone surfaces** (a face shared by two modelled zones of one building) become an **explicit reciprocal `Surface` pair** (BC=Surface, reversed twin, Floor↔Ceiling flipped, mirror `<name>_Rev` construction). Boundary is decided by **zone count, not the type name**. A face against the shell / another building / in a single-zone building → `Adiabatic`.
- **One IDF per building.** Each building is recentered to its own origin (min-corner→0,0, floor z=0); the shift is stored as `origin_offset`.

## Running it

Everything runs as a Python module from the **repo root** (`CityGMLtoIDF/`). The orchestrator is `run.py` — it is **presence-based**: read one file, and for each building in it build one IDF and run EnergyPlus. No stages, no modes; the FILE decides the zones/windows.

```bash
python -m citygml2idf.run path/to/file.gml                            # every building in the file
python -m citygml2idf.run --building id_building_11 path/to/file.gml  # just that one building
```

Each building lands in its own folder `citygml2idf/output/runs/<BuildingId>/` holding the IDF, **both** per-building middle layers (`middle_layer_trace_<id>.json` = parser evidence, `middle_layer_idf_<id>.json` = clean writer contract), a `<id>_preview.png`, and **all** EnergyPlus output (`.err`, `.dxf`, `.eio`, …). Different buildings → different folders, so runs never overwrite each other.

Most modules are independently runnable as a self-test/demo (each prints verification numbers):

```bash
python -m citygml2idf.citygml.xml_io [path.gml]    # load, validate (best-effort XSD), prove xlink+posList
python -m citygml2idf.model.reader [path.gml]      # dump middle_layer_trace.json + middle_layer_idf.json, print envelope areas
python -m citygml2idf.model.constructions [path.gml]  # each surface's construction branch (EXCEL / CITYGML_LAYERS / …) + layers
python -m citygml2idf.write.writer [path.gml]      # full build + E+ run, report Severe/Fatal counts
```

## Testing model — one Energy ADE case per sample, not a test framework

There is **no unit-test framework**, and **no stage/config flags** — the old `config.py` and `run.py --stage` scaffolding were removed; the pipeline is **presence-based, one path** (the file decides zones/windows). Instead we test **one Energy ADE spec Table-2 case at a time**, each a **self-contained single-file GML** under [citygml2idf/input/cases/](citygml2idf/input/cases/), authored to pass the XSD gate. The 7 cases, in build order (one new capability per step):

`2.1` LoD2·1zone·no-win → `5.1` LoD2·1zone·coincidesWithLoD2Hull → `3.1` LoD2·multizone → `6.1` LoD3·1zone·windows·coincidesWithLoD3Hull → `4.1` LoD3·multizone·windows → `1.1` LoD1·1zone → `1.2` LoD1·multizone.

For each case: run `python -m citygml2idf.run input/cases/<case>.gml`, then confirm the middle layer (right surfaces / zones / constructions), the IDF, and `exit=0` with **0 Severe/Fatal** in `eplusout.err`. Each sample is **self-contained** — every reference resolves inside the one file (within-file xlinks like Alderaan are fine); it is **never trimmed** from the multi-building Alderaan (that would break shared library xlinks). The per-case coverage record lives in [MAPPING.md](MAPPING.md); the running log is [SESSION_HANDOFF.md](SESSION_HANDOFF.md).

## Dependencies & external tooling (not vendored unless noted — must be supplied)

Python deps (no `requirements.txt` present): **lxml, pyproj, numpy, eppy** (IDF), **matplotlib** (the PNG preview in `idf_building_visualize.py`). *(No `pandas`/`openpyxl` — the construction fallback DB is now a stdlib-`json` archetype stub, not an Excel workbook.)*

EnergyPlus is invoked as an external process. `write/writer.py` expects a `templates/` folder **inside the package** at [citygml2idf/templates/](citygml2idf/templates/) (`_TEMPLATES = <package>/templates`):
- `Energy+.idd` (the EnergyPlus 23.1 IDD — the schema eppy/the writer enforce),
- `EnergyPlus-23.1.0-87ed9199d4-Windows-x86_64/energyplus.exe` (the engine; `EnergyPlusToFMU/` toolchain also lives here),
- optionally `weather.epw`. Weather is modular: `WEATHER_EPW = None` → design-day-only IDF (no `RunPeriod`/result outputs); set it to an `.epw` → adds the annual `RunPeriod` + summary outputs.

Real sample `.gml` data + the validation XSDs ship under [citygml2idf/validation_file/](citygml2idf/validation_file/) (see "Schema validation gate" above); pass a `.gml` path explicitly, or point `xml_io.DEFAULT_INPUT` at one.
