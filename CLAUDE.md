# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A converter from **CityGML 2.0 + Energy ADE 3.0** building models to **EnergyPlus 23.1 IDF** files (one IDF per building). It is a thesis project; the Python package lives in [citygml2idf/](citygml2idf/). An earlier CityJSON-based iteration was superseded by this CityGML approach.

## Canonical documents — read these first

Two living docs drive the project and outrank anything inferred from code:

- [citygml2idf/RULES_code.md](citygml2idf/RULES_code.md) — the EnergyPlus rules the converter MUST obey (geometry G1–G13, materials M1–M3, constructions C1–C7, windows W1–W5), each cited to its source (E+ Essentials, the vendored IDD, Energy ADE 3.0 §4.3.1–4.3.2). When a mapping question comes up, the answer is here, verified against sources — never code an E+ rule from memory.
- [citygml2idf/process.md](citygml2idf/process.md) — a dated session log of every decision and what was built. **Append a new dated entry each working session** (it is the thesis-report source). The older `process_update.md` history was the prior CityJSON module — reference only.

## Authoritative reference sources (consult; never map from memory)

Every mapping decision must be cross-checked against a real source. **For any EnergyPlus rule, fetch the live docs** — do not rely on recollection:

- **EnergyPlus Essentials** (concepts, conventions, units/axes): <https://energyplus.readthedocs.io/>
- **EnergyPlus Input/Output Reference, v23.1** (BigLadder — exact object/field semantics): <https://bigladdersoftware.com/> (epx/docs)
- The vendored **`Energy+.idd`** (EnergyPlus 23.1) is the exact schema enforced at write time — field names, `\key` choices, required fields. Quote it as `Object:Field`.

For the source data model (CityGML / Energy ADE), also fetch and keep these at hand:
- **CityGML 2.0** OGC standard (OGC 12-019): <https://www.ogc.org/standard/citygml/>
- **Energy ADE 3.0** specification PDF + the **UML model / XSDs** (the Delft / SIG3D Energy ADE repository): <https://github.com/cstb/citygml-energy>. Spec sections §4.3.1 (ThermalZone modelling per LoD) and §4.3.2 (thermal-boundary classes) are the basis for the zoning/interzone rules.

These supersede assumptions: when in doubt about `gValue`↔`SHGC`, layer order, boundary conditions, or any ADE element, open the spec/UML/XSD rather than guessing.

## Schema validation gate (`validation_file/`)

[citygml2idf/validation_file/](citygml2idf/validation_file/) holds the **official XSD schemas** for CityGML 2.0 + Energy ADE 3.0 (`CityGml_ADE_SChema/`, including `Energy_ADE_3.0_beta7.xsd`, the GML 3.1.1 base, and the ADE codelists), plus the **GML samples** (`Alderaan_Energy_ADE_*.gml`). The parser runs a **best-effort offline XSD validation gate** on input before parsing ([xml_io.py](citygml2idf/citygml/xml_io.py) `validate`/`build_schema`): a custom resolver serves each web-referenced import from this folder so validation works without network. The sample files PASS validation; the gate **warns and continues** if the schema can't be built — it never blocks a parse. Treat these XSDs as the ground truth for what an ADE element is.

## The golden rule (project-wide invariant)

Trust **only** structure + geometry + explicit `xlink` references. Never trust names, comments, `libraryCode` strings, or stated numbers. Specifically:
- **Geometry (vertices) is authoritative** (G11): azimuth/tilt/area/height are computed from vertices, never read from `nrg3:bdgBdrySurfAzimuth`/`bdgArea`/etc. Stated attributes are only a cross-check (warn on mismatch).
- **A window is never invented** (W1.4): emit a window only when the file provides a source. `DEFAULT_WWR` exists solely for testing and violates this rule by design — keep it `None` in production.
- On bad/imperfect input: **warn and continue**, never crash silently, never drop received geometry.

## Architecture — the one-way pipeline

Each folder has a single duty; data flows in one direction through a **middle-layer dict** (the firewall) that the writer is the only consumer of:

```
citygml/xml_io.py   ── the ONLY module that touches lxml/XML
      │                 (match by namespace URI, not prefix; gml:id→element registry; resolve xlinks)
      ▼
geometry/           ── pure math, no XML: rings.py (Newell normal, area, outward winding),
      │                 crs.py (EPSG parse, reproject-if-geographic, recenter), classify.py (role from normal)
      ▼
semantics/          ── surface_types.py (CityGML/ADE type → E+ Surface_Type + boundary),
      │                 building_surfaces.py (one building's envelope, any LoD → uniform surface list)
      ▼
model/              ── reader.py orchestrates: builds the middle layer, then wires in
      │                 constructions.py (Excel-first waterfall) → openings.py (windows) → zones.py (zoning)
      ▼
  middle_layer.json (the bridge — writer-neutral; inspect this to debug)
      ▼
write/writer.py     ── middle layer → IDF via eppy, block by block; runs EnergyPlus
```

Key design facts worth knowing before editing:
- **Namespace matching by URI, not prefix.** `xml_io.NS` is the single place URIs live; the file's `nrg3:`/`energy:` prefix is irrelevant. The Energy ADE URI is auto-adopted from the file's nsmap.
- **Two distinct link mechanisms, kept separate:** (a) CityGML geometry shared by reference — a `gml:Solid` holds `<surfaceMember xlink:href="#id">`, resolved O(1) via the id registry; (b) Energy ADE `nrg3:ThermalZone.thermalBoundary` xlinks zone→surface for ownership. `thermalBoundary` = zone↔surface ownership; `layeredConstruction` = surface→physics. There is **no** `ThermalBoundary` element in ADE 3.0 beta7 (confirmed against the XSD).
- **Extraction is data-driven / presence-based, not LoD-driven.** `detect_lod` is recorded for info only; code branches on "are labeled `bldg:boundedBy` surfaces present?", not on the LoD integer. LoD2/3 use labeled surfaces; LoD1 falls back to classifying solid faces by outward normal.
- **Construction resolution is an Excel-first waterfall** (`model/constructions.py`): `libraryCode` in [citygml2idf/input/construction_db.xlsx](citygml2idf/input/construction_db.xlsx) → build from Excel; else drill the file's own inline `nrg3:LayeredConstruction/Layer`; else generic default + warning. All spreadsheet-shape knowledge lives in `SHEET_NAMES`/`COLUMN_MAP` — swap the xlsx, change no code.
- **Interzone surfaces** (a face shared by two modelled zones of one building) become an **explicit reciprocal `Surface` pair** (BC=Surface, reversed twin, Floor↔Ceiling flipped). Boundary is decided by **zone count, not the type name** (G12). A face against the shell / another building / in a single-zone building → `Adiabatic`.
- **One IDF per building.** Each building is recentered to its own origin (min-corner→0,0, floor z=0); the shift is stored as `origin_offset`.

## Running it

Everything runs as a Python module from the **repo root** (`CityGMLtoIDF/`). The orchestrator + test harness is `run.py`:

```bash
python -m citygml2idf.run                          # all buildings, production flags
python -m citygml2idf.run Building_B3               # one building
python -m citygml2idf.run --stage mz-win Building_B3
python -m citygml2idf.run --default-wwr 0.3 Building_B1   # TEST-ONLY synthesized windows
```

Each run lands in its own self-contained folder `citygml2idf/output/runs/<BuildingId>__<zone>_<win>/` holding the IDF, a per-building `middle_layer_<id>.json`, a PNG preview, and **all** EnergyPlus output (`.err`, `.dxf`, `.eio`, …). The `<zone>_<win>` tag comes from the active flags so stages never overwrite each other.

Most modules are independently runnable as a self-test/demo (each prints verification numbers):

```bash
python -m citygml2idf.citygml.xml_io [path.gml]    # load, validate (best-effort XSD), prove xlink+posList
python -m citygml2idf.model.reader [path.gml]      # build + dump middle_layer.json, print envelope areas
python -m citygml2idf.model.constructions          # show each surface's construction branch + layers
python -m citygml2idf.write.writer [path.gml]      # full build + E+ run, report Severe/Fatal counts
```

## Testing model — staged, by flag, not a test framework

There is **no unit-test framework**. "Tests" are the professor's staged EnergyPlus runs (RULES_code §F): build + run ONE capability at a time, keep each run's full output, and confirm `exit=0` with **0 Severe/Fatal** in `eplusout.err`. Three flags in [citygml2idf/config.py](citygml2idf/config.py) only *gate which path runs* — the parser is always full and robust:

| Flag | Production | Test use |
|---|---|---|
| `ENABLE_WINDOWS` | `True` | `False` → skip `openings.py`, every wall opaque |
| `FORCE_SINGLE_ZONE` | `False` | `True` → ignore `thermalBoundary`, merge building into one hull zone |
| `DEFAULT_WWR` | `None` | float → fabricate windows on wall with no source (violates the golden rule; test only) |

Prefer `run.py --stage {1z-nowin,1z-win,mz-nowin,mz-win,real}` over editing `config.py` — a stage applies overrides for that process only. After a run, scan `eplusout.err` for `** Severe`/`** Fatal` and view the `.dxf` (e.g. sharecad.org). The five-stage ladder (1B·1Z·noWindow → … → multi-building) is all ✅ as of the latest session.

## Dependencies & external tooling (not vendored — must be supplied)

Python deps (no `requirements.txt` present): **lxml, pyproj, numpy, pandas, eppy**.

EnergyPlus is invoked as an external process. `write/writer.py` expects, in a `templates/` folder **beside** the `citygml2idf/` package (i.e. `CityGMLtoIDF/templates/`):
- `Energy+.idd` (the EnergyPlus 23.1 IDD — the schema eppy/the writer enforce),
- `EnergyPlus-23.1.0-87ed9199d4-Windows-x86_64/energyplus.exe`,
- optionally `weather.epw`. Weather is modular: `WEATHER_EPW = None` → design-day-only IDF (no `RunPeriod`/result outputs, run with `--design-day`); set it to an `.epw` → adds the annual `RunPeriod` + summary outputs. Neither `templates/` nor a default `input/sample_energyADE.gml` exists in a fresh checkout — supply them, or pass a `.gml` path explicitly. Real sample `.gml` data + the validation XSDs ship under [citygml2idf/validation_file/](citygml2idf/validation_file/) (see the "Schema validation gate" section above).
