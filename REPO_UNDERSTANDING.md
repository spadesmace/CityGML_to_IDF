# 1. Project Summary

This project converts CityGML 2.0 / Energy ADE building files into EnergyPlus IDF simulation files.

It solves the problem of taking geometry, surfaces, constructions, materials, thermal zones, and windows from CityGML/Energy ADE and turning them into an EnergyPlus-ready model.

Main inputs:
- CityGML `.gml` files, usually from `citygml2idf/input/cases/` or `citygml2idf/validation_file/`.
- Optional CLI building id filter via `--building`.
- EnergyPlus IDD file at `citygml2idf/templates/Energy+.idd`.
- Optional weather file support exists in `citygml2idf/write/writer.py`, but `WEATHER_EPW = None` currently means design-day-only runs by default.

Main outputs:
- Per-building middle-layer JSON: `citygml2idf/output/runs/<BuildingId>/middle_layer_<BuildingId>.json`.
- Per-building IDF: `citygml2idf/output/runs/<BuildingId>/<BuildingId>.idf`.
- EnergyPlus result files: `citygml2idf/output/runs/<BuildingId>/eplusout.*`.

Who/what uses it:
- A user runs the CLI entry point with a `.gml` file.
- EnergyPlus consumes the generated `.idf`.
- No API server, GUI, package metadata, or external caller is visible in the current repo.

# 3. Starting Points

Main entry point:
- `citygml2idf/run.py`
  - Run with `python -m citygml2idf.run path/to/file.gml`.
  - Optional filter: `python -m citygml2idf.run --building id_building_11 path/to/file.gml`.
  - Calls `xml_io.CityGMLDoc`, then `build_middle_layer`, then `writer.build_idf`, then `writer.run_energyplus`.

Secondary/demo entry points:
- `citygml2idf/write/writer.py`
  - Can run as `python -m citygml2idf.write.writer path/to/file.gml`.
  - Builds IDFs under `citygml2idf/output/idf/` by default and runs EnergyPlus.
- `citygml2idf/model/reader.py`
  - Can run as a demo to write `citygml2idf/output/middle_layer.json`.
- Several parser modules have `_demo()` blocks for local inspection:
  - `citygml2idf/citygml/xml_io.py`
  - `citygml2idf/semantics/building_surfaces.py`
  - `citygml2idf/model/constructions.py`
  - `citygml2idf/model/openings.py`
  - `citygml2idf/model/zones.py`
  - `citygml2idf/model/archetypes.py`

First functions that run in the main CLI:
- `parse_args()` in `citygml2idf/run.py`
- `main()` in `citygml2idf/run.py`
- `CityGMLDoc.__init__()` in `citygml2idf/citygml/xml_io.py`
- `build_middle_layer()` in `citygml2idf/model/reader.py`
- `run_building()` in `citygml2idf/run.py`

# 4. Folder and File Map

`citygml2idf/`
- Main Python package. Core logic.

`citygml2idf/run.py`
- CLI orchestrator. Core/integration.
- Reads one CityGML file, builds the middle layer, writes one IDF per buildable building, runs EnergyPlus, prints warning/severe counts.

`citygml2idf/citygml/`
- XML access layer. Core utility.
- Keeps `lxml` and namespace/xlink logic isolated from the rest of the code.

`citygml2idf/citygml/xml_io.py`
- Loads CityGML, resolves namespaces, indexes `gml:id`, follows `xlink:href`, reads `gml:posList`, optionally validates against local XSD files. Core utility.

`citygml2idf/geometry/`
- Pure geometry helpers. Core utility.

`citygml2idf/geometry/rings.py`
- Polygon operations: remove closing vertex, Newell normal, area, centroid, outward winding, window simplification to four points. Core logic.

`citygml2idf/geometry/classify.py`
- Classifies unlabeled faces as `wall`, `roof`, or `ground` from outward normal tilt. Core logic.

`citygml2idf/geometry/crs.py`
- Parses EPSG, detects geographic CRS, builds pyproj transformer, reprojects to metres, finds min corner. Core utility.

`citygml2idf/semantics/`
- Meaning/mapping layer between CityGML/Energy ADE concepts and EnergyPlus concepts. Core logic.

`citygml2idf/semantics/building_surfaces.py`
- Chooses building envelope surfaces and converts raw XML geometry into `Surface` objects. Core logic.

`citygml2idf/semantics/surface_types.py`
- Maps CityGML/ADE surface local names to EnergyPlus `Surface_Type` and boundary defaults. Core config-in-code.

`citygml2idf/model/`
- Typed middle layer and enrichers. Core logic.

`citygml2idf/model/model.py`
- Dataclasses for `Model`, `Building`, `Zone`, `Surface`, `Window`, `Construction`, `Material`, `WindowConstruction`; JSON serializer. Core data model.

`citygml2idf/model/reader.py`
- Main middle-layer assembler. Core logic.
- Calls surface extraction, CRS conversion, recentering, construction resolution, window resolution, and zone assignment.

`citygml2idf/model/constructions.py`
- Resolves opaque and glazing constructions from Energy ADE data. Core logic.
- Handles in-file construction libraries, layer stacks, `uValue` fallback, default construction, and window glazing fields.

`citygml2idf/model/materials.py`
- Builds EnergyPlus material objects from Energy ADE material/layer data. Core logic.

`citygml2idf/model/openings.py`
- Resolves exterior wall windows from explicit LoD3 `bldg:Window` geometry or LoD2 window-to-wall ratio/area data. Core logic.

`citygml2idf/model/zones.py`
- Assigns EnergyPlus zones and interzone boundary pairs from `nrg:ThermalZone`. Core logic.

`citygml2idf/model/units.py`
- Numeric coercion and unit conversion helpers. Utility.

`citygml2idf/model/citygml_read.py`
- Small typed XML readers for child text, measures, codes, and property objects. Utility.

`citygml2idf/model/archetypes.py`
- Loads archetype JSON and looks up rows. Utility, but currently not wired into construction resolution.

`citygml2idf/write/`
- EnergyPlus writer/runtime integration. Integration/core output.

`citygml2idf/write/writer.py`
- Builds IDF objects with `eppy`, writes `.idf`, runs EnergyPlus executable. Integration.

`citygml2idf/input/`
- Input data. Test/sample data.

`citygml2idf/input/cases/`
- Sample `.gml` cases:
  - `case2.1_lod2_1zone_nowin_synth.gml`
  - `LoD2_1Zone_window_WWR_synth.gml`
  - `case_lod3_1zone_win_Alderaan_Building2.gml`

`citygml2idf/input/archetypes.json`
- Placeholder archetype table. Config/data, but currently only read by `model/archetypes.py`; construction fallback says this tier is deferred.

`citygml2idf/templates/`
- EnergyPlus and template assets. Integration/config.
- Important files:
  - `Energy+.idd`: IDD used by eppy.
  - `EnergyPlus-23.1.0-87ed9199d4-Windows-x86_64/`: bundled EnergyPlus executable path used by `writer.py`.
  - `weather.epw`: present, but not active because `WEATHER_EPW = None`.
  - `materials.json`, `constructions.json`, `config.json`: present but no current Python import references them; current runtime role is unclear.
  - `singleFamilyHouse_test.idf`, `singleFamilyHouse_test_mult.idf`: present but not used by current writer path.

`citygml2idf/validation_file/`
- CityGML/Energy ADE sample files and local XSD files. Validation/sample data.
- `CityGml_ADE_SChema/` is used by `xml_io.validate()` to build an offline schema.

Root markdown files:
- `CLAUDE.md`, `COVERAGE.md`, `EPLUS_RULES.md`, `MAPPING.md`, `SESSION_HANDOFF.md`.
- Documentation/context files. They were not needed to identify the active runtime path.

# 5. Core Flow

1. `python -m citygml2idf.run <file.gml>` starts `citygml2idf/run.py`.

2. `parse_args()` finds:
- the CityGML path,
- optional target building id.

3. `main()` creates `xml_io.CityGMLDoc(path)`.
- Parses XML with `lxml`.
- Resolves namespace URIs.
- Indexes every element with `gml:id`.
- Enables fast local xlink resolution.

4. `build_middle_layer(doc)` creates the typed `Model`.
- Iterates every `bldg:Building`.
- Calls `building_surfaces.surfaces_of_building()` per building.

5. `surfaces_of_building()` chooses one surface source:
- First: Energy ADE `ThermalZone -> thermalBoundary`.
- Second: CityGML `bldg:boundedBy` shell surfaces.
- Third: raw selected LoD solid faces.
- Last: no surfaces; building remains in the model but is skipped for IDF output.

6. `process_surfaces()` converts raw surface records into `Surface` dataclasses.
- Drops invalid polygons.
- Orients rings outward.
- Uses CityGML/ADE type mapping when available.
- Falls back to geometry normal classification when type is unknown or raw.
- Sets default EnergyPlus surface type and boundary.

7. `reader.py` handles CRS and origin.
- Reads `srsName`.
- Reprojects only if CRS is geographic.
- Recenters each building to its own min corner.
- Computes surface area.

8. `constructions.resolve_all()` enriches surfaces.
- For each surface, checks construction owners: surface, thermal zone, building part, building.
- Resolves detailed material layers if present.
- Else resolves `uValue` to a no-mass resistance material.
- Else assigns `DEFAULT_CONSTRUCTION`.
- Populates `Model.constructions` and `Model.materials`.

9. `openings.resolve_windows()` attaches windows.
- Only exterior walls are considered.
- Tries explicit LoD3 `bldg:Window` geometry.
- Else tries wall opening ratio or total/opaque area.
- Creates `Window` objects and `WindowConstruction` glazings.

10. `zones.assign_zones()` assigns zones and boundary relationships.
- If no `nrg:ThermalZone`, creates one implicit zone for the whole building.
- If thermal zones exist, assigns surfaces from `thermalBoundary` references or hull coincidence flags.
- Shared surfaces owned by two zones become explicit reciprocal EnergyPlus `Surface` pairs.

11. `run.py` filters buildable buildings.
- Buildable means `building.surfaces` is non-empty.
- Optional `--building` selects one id.

12. `run_building()` writes outputs.
- Calls `model.subset_for_building()`.
- Writes middle-layer JSON.
- Calls `writer.build_idf()`.
- Calls `writer.run_energyplus()`.

13. `writer.build_idf()` emits EnergyPlus objects.
- Creates an empty IDF.
- Adds global simulation settings, site, design days, ground temperatures, geometry outputs.
- Adds used materials and constructions.
- Adds zones and `BuildingSurface:Detailed`.
- Adds glazing constructions and `FenestrationSurface:Detailed`.
- Saves `<BuildingId>.idf`.

14. `writer.run_energyplus()` runs the bundled EnergyPlus executable.
- Uses `--design-day` unless a valid weather file is passed/set.
- Reads `eplusout.err`.
- Returns exit code and error text.

# 6. Important Functions and Classes

`citygml2idf/run.py::main(building_id=None, path=None)`
- Purpose: main CLI orchestration.
- Inputs: optional building id, CityGML path.
- Outputs: writes run folders and prints status.
- Depends on: `xml_io.CityGMLDoc`, `build_middle_layer`, `run_building`.
- Why it matters: this is the normal user-facing workflow.

`citygml2idf/run.py::run_building(building, model)`
- Purpose: generate one building's middle JSON, IDF, and EnergyPlus run.
- Inputs: `Building`, full `Model`.
- Outputs: files under `output/runs/<BuildingId>/`; boolean success based on severe/fatal lines.
- Depends on: `Model.subset_for_building`, `writer.build_idf`, `writer.run_energyplus`.
- Why it matters: this defines per-building output behavior.

`citygml2idf/citygml/xml_io.py::CityGMLDoc`
- Purpose: loaded XML document plus namespace and id lookup helpers.
- Inputs: `.gml` path.
- Outputs: object with `root`, `ns`, `_by_id`, lookup methods.
- Depends on: `lxml.etree`.
- Why it matters: all XML access flows through this class.

`citygml2idf/citygml/xml_io.py::read_pos_list(doc, geom_el)`
- Purpose: parse first `gml:posList` into coordinate tuples.
- Inputs: `CityGMLDoc`, geometry element.
- Outputs: list of `(x, y, z)` points.
- Depends on: `doc.qualified_name`, `doc.property_object`.
- Why it matters: this is where XML geometry enters Python.

`citygml2idf/model/reader.py::build_middle_layer(doc)`
- Purpose: assemble the complete typed `Model`.
- Inputs: `CityGMLDoc`.
- Outputs: `Model`.
- Depends on: `building_surfaces`, `crs`, `rings`, `constructions`, `openings`, `zones`.
- Why it matters: central parser pipeline.

`citygml2idf/semantics/building_surfaces.py::surfaces_of_building(doc, building)`
- Purpose: pick and process envelope surfaces for one building.
- Inputs: document and `bldg:Building` element.
- Outputs: `(lod, SurfacePath, list[Surface])`.
- Depends on: `detect_lod`, `select_surface_path`, `process_surfaces`.
- Why it matters: decides what geometry becomes the EnergyPlus envelope.

`citygml2idf/semantics/building_surfaces.py::select_surface_path(doc, building, lod)`
- Purpose: choose surface source priority.
- Inputs: document, building element, detected LoD.
- Outputs: `SurfacePath` and raw records.
- Depends on: `_thermal_boundary_surfaces`, `_labeled_surfaces`, `_solid_faces`.
- Why it matters: prevents mixing multiple geometry sources for one building.

`citygml2idf/semantics/building_surfaces.py::process_surfaces(raw)`
- Purpose: convert raw records to typed surfaces.
- Inputs: raw surface tuples.
- Outputs: list of `Surface`.
- Depends on: `rings.orient_outward`, `classify.classify_by_normal`, `surface_types`.
- Why it matters: sets role, EnergyPlus surface type, boundary, and provenance.

`citygml2idf/model/constructions.py::resolve_all(doc, middle)`
- Purpose: resolve constructions/materials for every surface.
- Inputs: `CityGMLDoc`, `Model`.
- Outputs: fills `middle.constructions`, `middle.materials`, and each surface construction.
- Depends on: `_resolve_surface`, `_index_file_library`, material builders.
- Why it matters: EnergyPlus surfaces require construction names.

`citygml2idf/model/constructions.py::_resolve_surface(...)`
- Purpose: construction resolution waterfall for one surface.
- Inputs: document, surface XML element, `Surface`, materials dict, file library.
- Outputs: construction name, `Construction`, trace dict.
- Depends on: owner lookup, `_from_citygml`, default material.
- Why it matters: implements the key material/construction fallback rules.

`citygml2idf/model/materials.py::_material_from_citygml(...)`
- Purpose: turn an ADE material/layer into an EnergyPlus `Material` or `Material:AirGap`.
- Inputs: document, material element, layer thickness, layer element.
- Outputs: `Material`.
- Depends on: unit converters.
- Why it matters: converts physical material data into EnergyPlus units and defaults.

`citygml2idf/model/openings.py::resolve_windows(doc, middle)`
- Purpose: attach windows and glazing constructions.
- Inputs: document, `Model`.
- Outputs: updates surfaces with `Window` objects and fills `middle.window_constructions`.
- Depends on: `windows_for_wall`, `constructions.window_glazing`.
- Why it matters: handles both explicit LoD3 windows and synthesized WWR windows.

`citygml2idf/model/zones.py::assign_zones(doc, middle)`
- Purpose: assign surfaces to zones and create interzone partner surfaces.
- Inputs: document, `Model`.
- Outputs: updated `Model` with zones and boundary objects.
- Depends on: `thermal_zones`, `boundary_surface_ids`, `make_partner`.
- Why it matters: EnergyPlus needs each surface assigned to a zone with correct boundary condition.

`citygml2idf/write/writer.py::build_idf(...)`
- Purpose: write one building's IDF.
- Inputs: `Building`, constructions, materials, window constructions, output directory.
- Outputs: path to saved `.idf`.
- Depends on: eppy `IDF`, `add_materials`, `add_constructions`, `add_building`, `add_windows`.
- Why it matters: converts the middle layer into EnergyPlus objects.

`citygml2idf/write/writer.py::run_energyplus(idf_path, weather=WEATHER_EPW, out_dir=None)`
- Purpose: run EnergyPlus for one IDF.
- Inputs: IDF path, optional weather path, output directory.
- Outputs: `(returncode, err_text)`.
- Depends on: bundled `energyplus.exe`.
- Why it matters: validates the generated IDF through EnergyPlus.

`citygml2idf/model/model.py::Model`
- Purpose: whole middle-layer container.
- Inputs: CRS dict, buildings, constructions, materials, window constructions.
- Outputs: object graph and `subset_for_building()`.
- Depends on: dataclasses.
- Why it matters: this is the internal contract between reader and writer.

`citygml2idf/model/model.py::Surface`
- Purpose: one EnergyPlus envelope face plus audit provenance.
- Inputs: source id, role/type/boundary, points, construction, zone, windows.
- Outputs: dataclass instance consumed by zone logic and writer.
- Depends on: parser modules mutate it in place.
- Why it matters: most pipeline stages attach data to `Surface`.

# 7. Relationships Between Files

High-level architecture:
- Layered pipeline: XML access -> geometry/semantics -> typed middle layer -> EnergyPlus writer.
- `model.Model` is the boundary between parsing/enrichment and writing.
- Most parser modules mutate the same `Model`/`Surface` dataclasses in place.

Main dependency chain:
- `run.py`
  - imports `citygml/xml_io.py`
  - imports `model/reader.py`
  - imports `write/writer.py`
- `model/reader.py`
  - imports `citygml/xml_io.py`
  - imports `geometry/crs.py`, `geometry/rings.py`
  - imports `semantics/building_surfaces.py`
  - imports `model/constructions.py`, `model/openings.py`, `model/zones.py`
  - imports dataclasses from `model/model.py`
- `semantics/building_surfaces.py`
  - imports `xml_io`, `geometry/rings.py`, `geometry/classify.py`, `surface_types.py`, `Surface`.
- `model/constructions.py`
  - imports `xml_io`, `citygml_read.py`, `materials.py`, `units.py`, dataclasses.
- `model/materials.py`
  - imports `citygml_read.py`, `units.py`, `Material`.
- `model/openings.py`
  - imports `xml_io`, `rings.py`, `constructions.py`, `Window`, `WindowConstruction`.
- `model/zones.py`
  - imports `xml_io`, `rings.py`, `Construction`, `Surface`, `Zone`.
  - imports `_child_text` and `_num` through `model/constructions.py` compatibility re-exports.
- `write/writer.py`
  - imports `eppy.modeleditor.IDF`
  - imports `xml_io`, `surface_types.sun_wind_exposure`, `Zone`, `build_middle_layer`.

Circular/confusing dependencies:
- `model/reader.py` imports `model/constructions.py`; `model/constructions.py` has a `_demo()` that imports `model.reader` only inside the demo function. Runtime pipeline is not circular.
- `write/writer.py` imports `build_middle_layer` for its standalone demo entry point, while `run.py` imports `writer.py`. This is not a runtime circular import because `writer.py` does not import `run.py`.
- `model/zones.py` imports `_child_text` and `_num` from `model/constructions.py`, where they are compatibility re-exports from `citygml_read.py` and `units.py`. This works, but the dependency direction is confusing.

# 8. Business Logic / Main Logic

Main rules:
- One buildable CityGML building becomes one EnergyPlus IDF.
- Buildings with no usable surfaces remain in the middle layer but are skipped by the writer.
- Surface source priority is presence-based:
  1. Energy ADE thermal boundaries.
  2. CityGML `boundedBy` shell.
  3. Raw LoD solid faces.
  4. Nothing usable.
- Energy ADE `ThermalZone` presence drives zoning, not LoD alone.
- If no `ThermalZone` exists, the building gets one implicit EnergyPlus zone.
- If a thermal zone declares `coincidesWithLod2Hull` or `coincidesWithLod3Hull`, it owns the whole shell.
- A surface owned by two modeled zones becomes an explicit reciprocal `Surface` pair.
- Surface type mapping is explicit in `surface_types.py`; unknown labeled types are classified by geometry normal rather than dropped immediately.
- Raw/unlabeled faces are classified by outward normal tilt:
  - roof if tilt <= 60 degrees,
  - ground if tilt >= 120 degrees,
  - otherwise wall.
- Coordinates are reprojected only when source CRS is geographic; projected/unknown CRS is treated as already metric.
- Each building is recentered to its own minimum corner before IDF writing.
- EnergyPlus gets vertices in world coordinates with counterclockwise outward winding.
- Constructions resolve from real CityGML data first:
  1. detailed layers,
  2. `uValue` as no-mass R-value,
  3. default construction.
- External archetype fallback is present as a placeholder but not wired.
- Windows are only attached to exterior walls.
- Window priority:
  1. explicit LoD3 `bldg:Window`,
  2. opening-to-surface ratio,
  3. derived ratio from total and opaque wall area,
  4. no window.
- Doors are skipped and treated as opaque.
- Windows with more than four vertices are simplified to an in-plane quad because EnergyPlus fenestration is limited to four vertices.
- Weather-file annual simulation is supported by code paths, but disabled by default.

Important assumptions:
- `gml:id` and local xlinks are the main object-linking mechanism.
- Namespace URI matters, not XML prefix.
- Energy ADE namespace may vary; `CityGMLDoc` adopts the file's Energy ADE URI when found.
- Construction library identity is `(codeSpace, code)`, not code alone.
- Missing material fields are defaulted per field, not by replacing the whole material.
- `uValue` fallback uses `R = 1 / U`.

Edge cases handled:
- External xlinks warn and return no local object.
- Property elements with both inline object and xlink warn and use inline object.
- 2D `posList` gets `z = 0.0`.
- Empty or short polygons are skipped with warnings.
- Large projected coordinates are handled by absolute tolerance when dropping closing ring points.
- Unknown CRS is assumed metric.
- Missing Energy ADE volume lets EnergyPlus autocalculate zone volume.
- More than two zones sharing one surface warns and uses the first two.
- Orphan surfaces not owned by any zone are assigned to the first zone with a warning.
- Missing gas `rValue` or unrecognized units use a default air-gap resistance.
- Specific heat below EnergyPlus minimum is raised to the minimum.

Unclear:
- How dependencies are installed is unclear because there is no `requirements.txt`, `pyproject.toml`, `setup.py`, or environment file in the current file list.
- Current runtime use of `templates/config.json`, `templates/materials.json`, and `templates/constructions.json` is unclear because no Python code imports them.
- Current runtime use of `singleFamilyHouse_test.idf` files is unclear because `writer.py` builds from an empty IDF.

# 9. External Dependencies

`lxml`
- Why: parse XML, inspect namespaces/tags, compile and run XSD validation.
- Where: `citygml2idf/citygml/xml_io.py`.
- Critical: yes; CityGML parsing depends on it.

`numpy`
- Why: vector math for polygon normals, areas, centroids, CRS min corner, zone centroids.
- Where: `geometry/rings.py`, `geometry/crs.py`, `model/zones.py`.
- Critical: yes for geometry processing.

`pyproj`
- Why: detect CRS type and reproject geographic coordinates to UTM/metres.
- Where: `geometry/crs.py`.
- Critical: critical for geographic CRS input; projected CRS can pass through but import is still required.

`eppy`
- Why: create and save EnergyPlus IDF objects from Python.
- Where: `write/writer.py`.
- Critical: yes for IDF generation.

EnergyPlus 23.1 executable
- Why: run generated IDF and produce `eplusout.*`.
- Where: `write/writer.py`, path `citygml2idf/templates/EnergyPlus-23.1.0-87ed9199d4-Windows-x86_64/energyplus.exe`.
- Critical: critical for simulation/validation; IDF generation still depends on IDD/eppy.

EnergyPlus IDD
- Why: tells eppy the EnergyPlus object schema.
- Where: `citygml2idf/templates/Energy+.idd`.
- Critical: yes for eppy object creation.

CityGML / Energy ADE schemas and codelists
- Why: optional offline validation.
- Where: `citygml2idf/validation_file/CityGml_ADE_SChema/`.
- Critical: optional; `xml_io.validate()` warns and continues if validation cannot run.

Standard library
- Important modules: `argparse`, `json`, `os`, `sys`, `subprocess`, `math`, `re`, `dataclasses`, `typing`, `urllib.parse`, `io`.
- Critical: yes, but bundled with Python.

# 10. Tests and Validation

No project-owned automated test suite is visible.

Verification options visible in the repo:
- Parse/build/run a sample case:
  - `python -m citygml2idf.run citygml2idf/input/cases/case2.1_lod2_1zone_nowin_synth.gml`
  - Expected output path: `citygml2idf/output/runs/<BuildingId>/`.
  - Check terminal output for EnergyPlus exit code, warnings, and severe/fatal count.
- Run a single building from a multi-building file:
  - `python -m citygml2idf.run --building id_building_11 citygml2idf/input/cases/case_lod3_1zone_win_Alderaan_Building2.gml`
- Generate only the middle layer through the reader demo:
  - `python -m citygml2idf.model.reader citygml2idf/input/cases/case2.1_lod2_1zone_nowin_synth.gml`
  - This writes `citygml2idf/output/middle_layer.json`.
- Validate a CityGML file with the best-effort XSD gate by calling `xml_io.validate(path)` or running the XML demo:
  - `python -m citygml2idf.citygml.xml_io citygml2idf/input/cases/case2.1_lod2_1zone_nowin_synth.gml`

Important validation caveats:
- The main CLI writes output files and runs EnergyPlus.
- EnergyPlus execution depends on the bundled Windows executable path existing.
- Python dependencies must already be installed; no dependency manifest is present.
- I did not run the pipeline while creating this document because the request was to avoid modifying code, and the main verification commands generate output files.

# 11. Suggested Reading Order

1. `citygml2idf/run.py`
   - Start here to see the actual CLI workflow and output locations.

2. `citygml2idf/model/model.py`
   - Read the middle-layer dataclasses before reading parser details.

3. `citygml2idf/model/reader.py`
   - This shows the full parser/enrichment sequence in one place.

4. `citygml2idf/citygml/xml_io.py`
   - Understand XML loading, namespace matching, xlink resolution, and geometry text extraction.

5. `citygml2idf/semantics/building_surfaces.py`
   - Understand how building surfaces are selected and converted into `Surface` objects.

6. `citygml2idf/semantics/surface_types.py`
   - Read the CityGML/ADE surface type to EnergyPlus mapping.

7. `citygml2idf/geometry/rings.py`
   - Understand outward orientation, normals, areas, and window simplification.

8. `citygml2idf/geometry/classify.py`
   - Understand raw LoD face classification.

9. `citygml2idf/geometry/crs.py`
   - Understand CRS parsing, reprojection, and recentering assumptions.

10. `citygml2idf/model/constructions.py`
    - Read the construction waterfall and glazing conversion.

11. `citygml2idf/model/materials.py`
    - Read per-field material defaults and EnergyPlus material mapping.

12. `citygml2idf/model/units.py`
    - Read unit conversion rules used by materials/constructions.

13. `citygml2idf/model/openings.py`
    - Understand explicit and synthesized windows.

14. `citygml2idf/model/zones.py`
    - Understand thermal zones, hull coincidence, and interzone surface pairs.

15. `citygml2idf/write/writer.py`
    - Read how the middle layer becomes EnergyPlus IDF objects and how EnergyPlus is run.

16. `citygml2idf/input/cases/case2.1_lod2_1zone_nowin_synth.gml`
    - Read a small LoD2 one-zone no-window example.

17. `citygml2idf/input/cases/LoD2_1Zone_window_WWR_synth.gml`
    - Read an LoD2 case with synthesized window logic.

18. `citygml2idf/input/cases/case_lod3_1zone_win_Alderaan_Building2.gml`
    - Read an LoD3 explicit-window example after the smaller cases.

19. `citygml2idf/model/citygml_read.py`
    - Read this when you want the small XML helper details used by construction/material parsing.

20. `citygml2idf/model/archetypes.py` and `citygml2idf/input/archetypes.json`
    - Read last; this fallback exists but is not wired into the active construction pipeline.
