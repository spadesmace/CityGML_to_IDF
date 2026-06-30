# EPLUS_RULES.md — what EnergyPlus requires of every IDF we write

**The single, authoritative rulebook.** Every rule here is *what EnergyPlus itself requires* (IDD +
Essentials + I/O Reference) — nothing else is canonical. The parser/writer MUST satisfy all of it so an
emitted IDF is *valid EnergyPlus*. Grouped by the order we build a model:

1. **[STAGE 1 — one building, one zone, any LoD](#stage-1)** → Geometry · Materials · Constructions
2. **[STAGE 2 — Windows](#stage-2)**
3. **[STAGE 3 — Multizone / interzone](#stage-3)**

Each stage is split into the three things the parser has to get right: **Units · Naming · Logic**
(required fields, allowed values, ordering, geometry math).

## How to read a rule + where it comes from

Every rule cites its source. Three authorities, strongest first:

- **IDD (local, ground truth)** — `citygml2idf/templates/Energy+.idd`, the exact schema EnergyPlus 23.1
  enforces. Cited as `Object:Field` + the IDD marker that proves the rule:
  `\required-field`, `\units`, `\minimum`, `\key`, `\default`, `\min-fields`, `\extensible`.
  These are quoted verbatim from the local file — re-grep the object name to re-verify.
- **E+ Essentials** (concepts/conventions) — *EnergyPlus Input Specifications*:
  <https://energyplus.readthedocs.io/en/stable/essentials/essentials.html>. Sections cited:
  *"IDF and JSON syntax"* (units) and *"Thermal Zones and Surfaces"* (axes, vertex order).
- **E+ Input/Output Reference v23.1** (BigLadder, per-object prose), two group pages:
  - geometry → [group-thermal-zone-description-geometry.html](https://bigladdersoftware.com/epx/docs/23-1/input-output-reference/group-thermal-zone-description-geometry.html)
  - constructions/materials → [group-surface-construction-elements.html](https://bigladdersoftware.com/epx/docs/23-1/input-output-reference/group-surface-construction-elements.html)

**Verified deep links (BigLadder v23.1)** — click straight to the field while parsing:

| Object | Anchor URL |
|---|---|
| GlobalGeometryRules | `…/group-thermal-zone-description-geometry.html#globalgeometryrules` (`#field-starting-vertex-position`, `#field-vertex-entry-direction`, `#field-coordinate-system`) |
| Zone | `…#zone` (`#field-multiplier`, `#field-ceiling-height`, `#field-volume`, `#field-floor-area`) |
| BuildingSurface:Detailed | `…#buildingsurfacedetailed` (`#field-surface-type-000`, `#field-outside-boundary-condition-3`, `#field-outside-boundary-condition-object-9`, `#field-sun-exposure-2`, `#field-wind-exposure-3`, `#field-number-of-vertices-3`) |
| FenestrationSurface:Detailed | `…#fenestrationsurfacedetailed` (`#field-building-surface-name-5`, `#field-number-of-vertices-4`) |
| Material / NoMass / AirGap / Construction / WindowMaterial:* | `…/group-surface-construction-elements.html` |

**Verify locally**: the EnergyPlus engine is vendored at
`citygml2idf/templates/EnergyPlus-23.1.0-87ed9199d4-Windows-x86_64/energyplus.exe` (+ the EnergyPlusToFMU
toolchain). The acceptance test for any rule is a run with **0 `** Severe` / `** Fatal`** in `eplusout.err`.

> **Scope.** This file states only the EnergyPlus requirement and the minimal **Parser** action that
> satisfies it. *How* we derive each value from CityGML / Energy ADE — the golden rule (trust only
> structure/geometry/xlinks), the Excel-first construction waterfall, geometry-over-stated-attributes,
> the ADE LoD/ThermalZone modelling — lives in the code and in `CLAUDE.md` / `MAPPING.md`, not in a second
> rules file. If a parser policy and this file ever disagree, **EnergyPlus wins** and the policy is the bug.

---

<a id="stage-1"></a>
# STAGE 1 — one building, one zone, any LoD

The minimal valid model: settings → materials → constructions → one `Zone` → one
`BuildingSurface:Detailed` per envelope face. No windows, no HVAC (free-floating zone is fine for
checking geometry/construction).

## 1.0 Foundation — coordinate system & units (apply to ALL geometry below)

### F1 — SI units everywhere · **Units**
Every numeric input is SI. The IDD tags each geometric/physical field with its unit:
vertices `\units m`, areas `m2`, volumes `m3`, conductivity `W/m-K`, etc.
- **Parser:** emit metres / SI only; never feet, never degrees-of-arc for length.
- **Source:** Essentials §"IDF and JSON syntax" — *"For both input files, the numeric inputs are in SI
  units (International System of Units often called metric units)."* · IDD `\units` markers throughout.

### F2 — Axes: X = East, Y = North, Z = Up (right-handed) · **Logic**
A projected vertex `(Easting, Northing, height)` maps directly to `(X, Y, Z)`.
- **Parser:** a projected CityGML `posList` is already `(X=E, Y=N, Z=up)`; for a geographic CRS,
  reproject lon→X, lat→Y, height stays Z.
- **Source:** Essentials §"Thermal Zones and Surfaces" — *"The X-axis points east, the Y-axis points
  north, and the Z-axis points up."*

### F3 — One coordinate system, declared once, model near the origin · **Logic**
`GlobalGeometryRules` is **`\required-object` `\unique-object`**. `Coordinate System` (A3) is a
**`\required-field`** choice `World | Relative`. `World` = *"all coordinates entered are absolute for
this facility."*
- **Parser:** emit exactly one `GlobalGeometryRules` with `Coordinate System = World`, and recenter the
  site so coordinates are small (min-corner → 0,0; floor → z=0) for numerical precision. Recentering is a
  pure translation — areas/normals/winding unchanged.
- **Source:** IDD `GlobalGeometryRules` (`\required-object`, `\unique-object`, A3 `\required-field`,
  `\key World`).

## 1.A GEOMETRY

### G-1 — `GlobalGeometryRules` winding must match how we wrote vertices · **Logic**
`Starting Vertex Position` (A1, `\required-field`, keys `UpperLeftCorner|LowerLeftCorner|UpperRightCorner|
LowerRightCorner`) and `Vertex Entry Direction` (A2, `\required-field`, keys `Counterclockwise|Clockwise`).
EnergyPlus reads vertices *as viewed from outside the surface* (IDD note: *"Surfaces are specified as
viewed from outside the surface"*).
- **Parser:** we orient every ring outward (CCW from outside), so write `Vertex Entry Direction =
  Counterclockwise` and `Starting Vertex Position = UpperLeftCorner`. Whatever we declare here MUST equal
  how the vertices were actually wound.
- **Source:** IDD `GlobalGeometryRules:Starting Vertex Position / Vertex Entry Direction` · Essentials
  §"Thermal Zones and Surfaces" — *"the order of coordinates for each surface should start with the upper
  left corner (when viewed from 'outside' the zone with the surface) and that the coordinates should
  proceed in a counter-clockwise order."*

### G-2 — One `BuildingSurface:Detailed` per envelope face; surfaces are zero-thickness polygons · **Logic**
A heat-transfer surface is a polygon (vertices only); thickness lives in the construction, not the geometry.
The object is `\extensible:3` (x,y,z triplets) with `\min-fields 20`.
- **Parser:** one `BuildingSurface:Detailed` per CityGML boundary surface, a single plane; map
  `nrg3:bdgBdrySurfThickness` to materials, never to vertices.
- **Source:** IDD `BuildingSurface:Detailed` (`\format vertices`, `\extensible:3`, `\memo … Does not
  include subsurfaces`).

### G-3 — ≥ 3 vertices, coplanar, given in metres · **Units + Logic**
`Number of Vertices` (N2) is **`\minimum 3`** (no maximum — base surfaces may have many); each
`Vertex n X/Y/Z-coordinate` is a `\required-field` `\units m`. The first triplet is `\required-field`;
further triplets extend the object.
- **Parser:** every surface needs ≥ 3 (near-)coplanar corners in metres. We **warn, never drop** received
  geometry that is thin/degenerate — it is a semantic check, not an E+ hard stop.
- **Source:** IDD `BuildingSurface:Detailed:Number of Vertices` (`\minimum 3`), `Vertex 1 X-coordinate`
  (`\required-field`, `\units m`).

### G-4 — Drop the closing point; ring must not repeat the first vertex · **Logic**
GML rings are closed (last point = first). EnergyPlus wants the distinct corners only.
- **Parser:** remove the duplicate closing point before counting/writing vertices. (Use an **absolute**
  tolerance — a relative tolerance on large UTM coords silently collapses polygons; see process.md
  2026-06-23.)
- **Source:** consequence of IDD `Number of Vertices` (count of *distinct* corners) + E+ enclosure checks.

### G-5 — Outward normal points away from the zone interior · **Logic**
The "CCW from outside" rule exists so each surface normal faces the exterior: floor normal down, roof up,
wall sideways-out. EnergyPlus derives the surface's orientation from the winding.
- **Parser:** compute the Newell normal; flip the ring if it points toward the zone/solid centroid
  (`geometry.rings.orient_outward`). Never trust the exporter's winding.
- **Source:** Essentials (CCW-from-outside ⇒ outward normal) · IDD `GlobalGeometryRules` note
  *"as viewed from outside the surface."*

### G-6 — Geometry is authoritative; stated azimuth/area/tilt are only a cross-check · **Logic**
EnergyPlus computes azimuth, tilt, area and height **from the vertices** and ignores any separately
stated value.
- **Parser:** build from vertices only; use `nrg3:bdgBdrySurfAzimuth`/`bdgArea`/`bdgHeight` solely as a
  warn-on-mismatch sanity check (a ~1° azimuth delta = UTM grid-north vs true-north, expected).
- **Source:** Essentials §"Thermal Zones and Surfaces" — *"EnergyPlus uses the three dimensional position
  of each corner of a surface to define the position and orientation of that surface"* (azimuth/tilt/area
  are therefore derived from the vertices) · I/O Reference `BuildingSurface:Detailed`.

### G-7 — `Surface Type` has exactly 4 legal values · **Naming**
`Surface Type` (A2) is a **`\required-field`** choice: **`Floor | Wall | Ceiling | Roof`** — nothing else.
- **Parser:** collapse every CityGML/ADE boundary subtype onto one of these 4. Roof vs Wall vs Floor vs
  Ceiling is decided by the outward-normal tilt (up→Roof, down→Floor/Ground, sideways→Wall); the many ADE
  subtypes differ by *boundary condition* (G-9), not by Surface Type. (`semantics/surface_types.py`.)
- **Source:** IDD `BuildingSurface:Detailed:Surface Type` (`\required-field`, the four `\key`s).

### G-8 — Every surface needs all required fields populated · **Logic**
`BuildingSurface:Detailed` `\min-fields 20`. Required: `Name` (A1), `Surface Type` (A2),
`Construction Name` (A3), `Zone Name` (A4), `Outside Boundary Condition` (A6). `Sun Exposure` (A8) and
`Wind Exposure` (A9) default to `SunExposed`/`WindExposed`.
- **Parser:** never emit a surface missing one of these; fill `Sun/Wind Exposure` per the boundary (G-9).
- **Source:** IDD `BuildingSurface:Detailed` (`\min-fields 20`; A1–A6 `\required-field`).

### G-9 — `Outside Boundary Condition` is a closed choice list; exposure follows it · **Naming + Logic**
`Outside Boundary Condition` (A6, `\required-field`) keys include `Outdoors | Ground | Adiabatic |
Surface | Zone | Foundation | OtherSideCoefficients | …`. Only `Outdoors` is sun/wind exposed.
| CityGML/ADE role | Surface Type | Outside Boundary Condition | Sun/Wind |
|---|---|---|---|
| `bldg:WallSurface`, `RoofSurface` | Wall / Roof | `Outdoors` | SunExposed / WindExposed |
| `bldg:GroundSurface` | Floor | `Ground` | NoSun / NoWind |
| interior/shared (single-zone here) | Wall/Floor/Ceiling | `Adiabatic` | NoSun / NoWind |
- **Parser:** `Ground`/`Adiabatic`/`Surface`/`Zone` ⇒ `NoSun, NoWind`; only `Outdoors` ⇒ exposed
  (`semantics/surface_types.sun_wind_exposure`). In a single-zone build, all interior faces are
  `Adiabatic` (multizone upgrades this — see STAGE 3, Z-2).
- **Source:** IDD `BuildingSurface:Detailed:Outside Boundary Condition` (the `\key` list) + `Sun Exposure`/
  `Wind Exposure` (`\key NoSun`/`\key NoWind`).

### G-10 — One `Zone`, fully enclosed, auto-calculated geometry · **Logic + Units**
`Zone:Name` (A1) `\required-field` `\reference ZoneNames`. `Ceiling Height` (N7, `m`), `Volume` (N8, `m3`),
`Floor Area` (N9, `m2`) are all `\autocalculatable` (default `autocalculate`); `Multiplier` (N6) `\minimum 1`
`\default 1`; X/Y/Z Origin `\units m \default 0`.
- **Parser:** emit one `Zone` (the whole building when there is no `nrg3:ThermalZone`); set
  `Ceiling Height`/`Floor Area` = `autocalculate`, `Multiplier = 1`, origin (0,0,0). Pass `Volume` only if
  the ADE gives `nrg3:volume`, else `autocalculate`. The zone must be a closed solid or E+ warns
  "not fully enclosed".
- **Source:** IDD `Zone` (N6 `\minimum 1`; N7/N8/N9 `\autocalculatable`; origins `\units m`).

## 1.B MATERIALS

### M-1 — Three opaque material objects, chosen by the data that exists · **Logic**
`Material` (full mass), `Material:NoMass` (R-value only — *"principal description is R"*),
`Material:AirGap` (*"Air Space in Opaque Construction"*, R-value only).
- **Parser:** `nrg3:SolidMaterial` with conductivity+density+specific-heat+thickness → `Material`; a layer
  with only an R-value → `Material:NoMass`; `nrg3:Gas`/air cavity with an R-value → `Material:AirGap`. Pick
  by source, never by name.
- **Source:** IDD `Material`, `Material:NoMass` (`\memo … principal description is R`), `Material:AirGap`
  (`\memo Air Space in Opaque Construction`) · I/O Reference: NoMass — *"using a simple R-value only
  material forces EnergyPlus to assume steady state heat conduction through this material layer"*; AirGap —
  *"should only be used for an air gap between other layers in a construction"* (cannot be used in windows).

### M-2 — `Material` required fields, SI units, value ranges · **Units + Logic**
`\min-fields 6`. Required: `Name` (A1), `Roughness` (A2), `Thickness` (N1), `Conductivity` (N2),
`Density` (N3), `Specific Heat` (N4).
| Field | Unit | Constraint |
|---|---|---|
| Thickness (N1) | `m` | `\minimum> 0` (strictly positive) |
| Conductivity (N2) | `W/m-K` | `\minimum> 0` |
| Density (N3) | `kg/m3` | `\minimum> 0` |
| Specific Heat (N4) | `J/kg-K` | **`\minimum 100`** |
| Thermal/Solar/Visible Absorptance (N5–N7) | – | optional, default `0.9 / 0.7 / 0.7` |
- **Parser:** Energy ADE SI ≡ E+ SI (W/(m·K), J/(kg·K)) → DIRECT, no conversion. Fill absorptances with the
  defaults; never emit a `Material` missing a required field — default it (+ warn) or downgrade to
  `NoMass`. Watch the **`Specific Heat ≥ 100`** floor.
- **Source:** IDD `Material` (`\min-fields 6`; N1–N3 `\minimum> 0`; N4 `\minimum 100`; N5–N7 `\default`).

### M-3 — `Roughness` is a 6-value choice · **Naming**
`Roughness` (A2, `\required-field`) keys: `VeryRough | Rough | MediumRough | MediumSmooth | Smooth |
VerySmooth`.
- **Parser:** map/clamp to one of these six; default `MediumRough` when unknown.
- **Source:** IDD `Material:Roughness` / `Material:NoMass:Roughness` (`\key` list).

### M-4 — R-only materials use `m2-K/W` · **Units**
`Material:NoMass:Thermal Resistance` (N1) `\units m2-K/W` `\minimum .001`; `Material:AirGap:Thermal
Resistance` (N1) `\units m2-K/W` `\minimum> 0`.
- **Parser:** emit thermal resistance in m²·K/W; respect the `.001` floor for NoMass.
- **Source:** IDD `Material:NoMass` (N1 `\minimum .001`), `Material:AirGap` (N1 `\minimum> 0`).

### M-5 — Material names are the cross-object key · **Naming**
Each material `Name` carries `\reference MaterialName`; constructions point at materials by that exact
string (`\object-list MaterialName`).
- **Parser:** material names must be unique and must match a `Construction` layer string byte-for-byte.
- **Source:** IDD `Material:Name` (`\reference MaterialName`) ↔ `Construction:Outside Layer`
  (`\object-list MaterialName`).

## 1.C CONSTRUCTIONS

### C-1 — A `Construction` is an ordered layer list, OUTSIDE → INSIDE · **Logic**
*"Start with outside layer and work your way to the inside layer."* `Outside Layer` (A2) is
`\required-field`; then `Layer 2 … Layer 10` (`Up to 10 layers total, 8 for windows`).
- **Parser:** write layers outside→inside. The CityGML/Energy ADE layer order is **inside→outside**, so the
  writer **reverses** it for EnergyPlus (the middle layer records `layer_order = inside_to_outside`); never
  silently mis-order. *(Confirm the ADE direction against the Energy ADE spec/XSD — a silent reversal is a
  valid-but-wrong-physics bug.)*
- **Source:** IDD `Construction` (`\memo Start with outside layer …`; A2 `\required-field`;
  `\memo Up to 10 layers`) · I/O Reference — layers are assembled *"from the outside layer to the inside
  layer"*.

### C-2 — One construction per surface; each layer must resolve to a defined material · **Logic**
`BuildingSurface:Detailed:Construction Name` (A3) `\required-field` `\object-list ConstructionNames`
(single reference). Each `Construction` layer is `\object-list MaterialName` → must name a real material.
- **Parser:** 1 surface → 1 construction → N material layers. Never emit a `Construction` referencing an
  undefined material (Excel-first waterfall: Excel → file's inline layers → default + warn).
- **Source:** IDD `BuildingSurface:Detailed:Construction Name` (`\required-field`) · `Construction` layers
  (`\object-list MaterialName`).

### C-3 — Unique construction names; define once, reference N times · **Naming**
`Construction:Name` (A1) `\reference ConstructionNames`; surfaces reference it by that exact string.
- **Parser:** keep CityGML construction ids/codes as unique names; dedup so a construction used on many
  surfaces is written **once** and referenced many times.
- **Source:** IDD `Construction:Name` (`\reference ConstructionNames`).

### C-4 — Layer-count ceiling · **Logic**
Up to **10** layers for opaque constructions (8 for windows).
- **Parser:** if an assembly exceeds 10 layers, merge/clamp (+ warn) rather than overflow.
- **Source:** IDD `Construction` (`\memo Up to 10 layers total, 8 for windows`; fields A2…A11).

---

<a id="stage-2"></a>
# STAGE 2 — Windows (sub-surfaces)

Add only when STAGE 1 runs clean. A window is a `FenestrationSurface:Detailed` hosted on a wall, plus a
glazing `Construction`/`WindowMaterial:*`. **Never invented** — emitted only when the CityGML supplies a
source (project golden rule).

## 2.A GEOMETRY (sub-surface)

### W-1 — `FenestrationSurface:Detailed` hangs on a base surface · **Logic**
`\min-fields 18`. Required: `Name` (A1), `Surface Type` (A2), `Construction Name` (A3),
`Building Surface Name` (A4 — the host wall, `\object-list SurfaceNames`).
- **Parser:** one `FenestrationSurface:Detailed` per window, `Building Surface Name` = its host
  `BuildingSurface:Detailed`.
- **Source:** IDD `FenestrationSurface:Detailed` (`\min-fields 18`; A1–A4 `\required-field`;
  A4 `\object-list SurfaceNames`).

### W-2 — Sub-surface `Surface Type` is a 5-value choice · **Naming**
`Surface Type` (A2, `\required-field`): `Window | Door | GlassDoor | TubularDaylightDome |
TubularDaylightDiffuser`.
- **Parser:** glazing → `Window`. Doors are folded into opaque wall area for now; promote to `Door` later.
- **Source:** IDD `FenestrationSurface:Detailed:Surface Type` (`\key` list).

### W-3 — 3 or 4 vertices, in metres, coplanar with and inside the host · **Units + Logic**
`Number of Vertices` (N3) `\minimum 3 \maximum 4` (windows are triangles or quads — *unlike* base surfaces
which allow many). Vertices `\units m`; first 3 triplets `\required-field`, the 4th is *"Not used for
triangles."*
- **Parser:** a synthesized window (from a WWR) = a coplanar rectangle of area = `WWR × wall_area`, centred
  and inset on the host plane (scale the wall ring about its centre by √WWR). An explicit LoD3 opening that
  is not coplanar with its host must be **projected onto the host-wall plane** (or warned + skipped) —
  EnergyPlus requires the sub-surface coplanar with its base, and area ≤ host area.
- **Source:** IDD `FenestrationSurface:Detailed:Number of Vertices` (`\minimum 3 \maximum 4`), `Vertex …`
  (`\units m`, `\note Not used for triangles`).

### W-4 — Geometry wins over a stated WWR · **Logic**
If an explicit `bldg:Window` and a stated `…OpeningToSurfaceRatio` disagree, trust the geometry, warn (same
authoritative-vertices principle as G-6).
- **Parser:** richest→poorest source: explicit `bldg:Window` → `openingToSurfaceRatio` →
  `(total−opaque)/total` → none/opaque.
- **Source:** I/O Reference (fenestration area is derived from vertices) · same vertices-are-truth principle
  as G-6.

## 2.B GLAZING MATERIAL & CONSTRUCTION

### W-5 — Glazing uses `WindowMaterial:*`, never opaque materials · **Logic**
Two methods: `WindowMaterial:SimpleGlazingSystem` (U + SHGC only) **or** `WindowMaterial:Glazing` +
`WindowMaterial:Gas` (detailed panes). A window `Construction` lists these glazing materials (≤ 8 layers).
- **Parser:** only a U-value + g-value present → one `SimpleGlazingSystem`; real glass panes + `nrg3:Gas`
  → `Glazing` + `Gas`. Opaque M-1/M-2 logic is never reused for glass.
- **Source:** IDD `WindowMaterial:SimpleGlazingSystem` (`\memo … define an entire glazing system using
  simple performance parameters`), `WindowMaterial:Glazing`, `WindowMaterial:Gas` · I/O Reference —
  SimpleGlazingSystem is *"for when you only have U-factor and SHGC"* values rather than detailed optics.

### W-6 — `SimpleGlazingSystem` fields, units, ranges · **Units + Naming**
`\min-fields 3`. `U-Factor` (N1, `\required-field`, `\units W/m2-K`, `\minimum> 0`, *"including film
coefficients"*); `Solar Heat Gain Coefficient` (N2, `\required-field`, `\minimum> 0 \maximum< 1`);
`Visible Transmittance` (N3) optional. `Name` carries `\reference MaterialName` **and**
`\reference GlazingMaterialName`.
- **Parser:** map `nrg3:uValue → U-Factor` (W/m²·K). Map ADE `gValue` to EnergyPlus
  `Solar Heat Gain Coefficient` when using `WindowMaterial:SimpleGlazingSystem`; both describe solar
  gain through the glazing system, and SHGC must be strictly between 0 and 1.
- **Source:** IDD `WindowMaterial:SimpleGlazingSystem` (N1 `\units W/m2-K \minimum> 0`; N2 `\minimum> 0
  \maximum< 1`).

### W-7 — Detailed glazing units (if used) · **Units**
`WindowMaterial:Glazing` `\min-fields 14`, `Thickness` (N1) `\units m \minimum> 0`, transmittance/
reflectance fields in 0–1. `WindowMaterial:Gas` `Gas Type` (A2) choice `Air|Argon|Krypton|Xenon|Custom`,
`Thickness` (N1) `\units m`.
- **Parser:** only when detailed panes exist in the file; otherwise prefer W-6.
- **Source:** IDD `WindowMaterial:Glazing` (N1 `\units m`), `WindowMaterial:Gas` (A2 `\key`s, N1 `\units m`).

---

<a id="stage-3"></a>
# STAGE 3 — Multizone / interzone

One `Zone` per `nrg3:ThermalZone`. The new EnergyPlus requirement is how surfaces *between* two zones are
described.

### Z-1 — One `Zone` per thermal zone; names unique · **Naming + Logic**
`Zone:Name` (A1) `\required-field`, unique across Zone/Space/ZoneList. Each surface's `Zone Name` (A4) must
name an existing zone.
- **Parser:** emit one `Zone` per `nrg3:ThermalZone`; assign each surface to its owning zone via the
  `nrg3:thermalBoundary` xlink (or to the single hull zone when `coincidesWithLoDxHull` / no zones).
- **Source:** IDD `Zone:Name` (`\required-field`, unique) · `BuildingSurface:Detailed:Zone Name`
  (`\required-field`, `\object-list ZoneNames`).

### Z-2 — A shared surface's boundary is set by ZONE COUNT, not by its type name · **Logic**
`Outside Boundary Condition` (A6) + `Outside Boundary Condition Object` (A7). IDD A7 note: *"If Surface,
specify name of corresponding surface in adjacent zone … If Zone, specify the name of the corresponding
zone and the program will generate the corresponding interzone surface."* `Adiabatic` = no other side
(no conduction, but the layers still store/release heat — thermal mass kept).
- **Parser (`model/zones.py`):**
  - face shared by **two modelled zones of the same building** → **interzone**;
  - face against **another building / the shell**, a **single-zone** building, or an **unmodelled** zone →
    **`Adiabatic`**;
  - explicit ADE `isAdiabatic` flag → **Adiabatic wins**.
  The **type still sets `Surface Type`** (Wall, or Floor/Ceiling by outward normal); only the *boundary*
  depends on zone count. A `PartyWall` between two zones of one building is interzone, NOT adiabatic.
- **Source:** IDD `BuildingSurface:Detailed:Outside Boundary Condition Object` (A7 note) + `\key Surface`
  / `\key Zone` / `\key Adiabatic`.

### Z-3 — Interzone via an explicit reciprocal `Surface` PAIR · **Logic**
When `Outside Boundary Condition = Surface` (A6), `Outside Boundary Condition Object` (A7) names the
**partner surface in the adjacent zone**; the partner must point back. (The alternative `= Zone` lets E+
auto-generate the partner — our documented fallback.)
- **Parser:** the owner face stays in zone A with `A6=Surface`, `A7=`twin name; a **reversed twin** is added
  to zone B — reversed winding, Floor↔Ceiling flipped, mirror construction `<name>_Rev` when multi-layer —
  with `A6=Surface`, `A7=`owner name. Re-orient the owner outward from **its own** zone centroid so its
  Floor/Ceiling label is correct. (IMPLEMENTED.)
- **Source:** IDD `BuildingSurface:Detailed` A6 (`\key Surface`) + A7 (*"name of corresponding surface in
  adjacent zone"*).

### Z-4 — Both interzone surfaces are unexposed · **Naming**
For `Surface` and `Zone` (and `Adiabatic`) boundaries set `Sun Exposure = NoSun`, `Wind Exposure = NoWind`
(only `Outdoors` is exposed, G-9).
- **Source:** IDD `BuildingSurface:Detailed:Sun Exposure / Wind Exposure` (`\key NoSun` / `\key NoWind`).

### Z-5 — Reversed twin keeps layer order physically correct · **Logic**
A construction is outside→inside (C-1). The twin sees the assembly from the other side, so its layer order
is reversed relative to the owner.
- **Parser:** emit a `<name>_Rev` construction with reversed layers for the twin when the assembly has > 1
  layer (a symmetric/1-layer assembly can reuse the same construction).
- **Source:** IDD `Construction` (`\memo Start with outside layer …`) applied to each side independently.

### Z-6 — Each zone must be a closed enclosure · **Logic**
EnergyPlus warns/severes when a zone is "not fully enclosed" or lacks a floor. Interzone pairs (Z-3) give
both zones a real bounding floor/ceiling so each closes.
- **Parser:** ensure every zone has a complete set of bounding surfaces (the owner + reversed twins). Faith-
  fully kept but geometrically inconsistent CityGML (e.g. a 5th wall on a 4-wall box) will still warn — we
  never drop received geometry (see process.md Stage 3).
- **Source:** I/O Reference, surface/zone enclosure checks · IDD `Zone` (auto floor area/volume need closure).

---

## Quick checklist (parser self-audit before a run)

- [ ] exactly one `Version`, `Building` (`\required-object`), `GlobalGeometryRules` (`\required-object`,
      World + Counterclockwise + UpperLeftCorner)
- [ ] every length/area/volume in **m / m² / m³**; conductivity W/m-K; specific heat J/kg-K **≥ 100**
- [ ] every `BuildingSurface:Detailed`: Name, `Surface Type ∈ {Wall,Floor,Ceiling,Roof}`, Construction,
      Zone, `Outside Boundary Condition` (valid key), Sun/Wind, ≥ 3 distinct coplanar vertices, outward normal
- [ ] every `Construction` layer resolves to a defined `Material`/`Material:NoMass`/`Material:AirGap`/
      `WindowMaterial:*`; outside→inside; ≤ 10 (≤ 8 window) layers; names unique + byte-exact
- [ ] windows: `FenestrationSurface:Detailed` on a real host wall, 3–4 coplanar vertices, glazing via
      `WindowMaterial:*` (never opaque); SHGC strictly in (0,1)
- [ ] multizone: one `Zone` per thermal zone; shared faces = reciprocal `Surface` pair (A7 points both ways)
      or `Adiabatic` by zone count; NoSun/NoWind on interior faces; each zone closed
- [ ] run `energyplus.exe --design-day` → `eplusout.err` has **0 `** Severe` / `** Fatal`**
