# COVERAGE.md — which Energy ADE 3.0 building models our parser can convert

*What the converter actually handles today (verified against the code on 2026-06-29), mapped to the
Energy ADE 3.0 specification's modelling cases (spec §4.1–4.3, Table 1/Table 2, and the Building-physics /
Layered-construction UML).* Companion to [EPLUS_RULES.md](EPLUS_RULES.md) (the EnergyPlus-side rules) and
the source XSDs in [citygml2idf/validation_file/](citygml2idf/validation_file/).

## Verdict — what we can convert today

We can produce a valid EnergyPlus IDF for a building modelled as:
- **any single thermal zone** — LoD1 (solid), LoD2 or LoD3 (thematic surfaces), including the
  **`coincidesWithLoD2Hull` / `coincidesWithLoD3Hull`** special cases (5.1 / 6.1); and
- **multiple thermal zones at LoD2 or LoD3**, where the zone↔surface link is given explicitly by
  **`nrg3:thermalBoundary`** (inline or XLink).

We **cannot** correctly convert a building modelled as **multiple LoD1 thermal zones** (solid-only, no
thematic surfaces) — that case needs matching coincident solid faces between zones, which we don't do.

## Coverage against the spec's modelling cases (Table 2)

| Spec case | Status |
|---|---|
| Example 1 — **LoD0** building | **Correctly skipped** — no thermal geometry allowed at LoD0; parser warns + emits nothing |
| Case 1.1 — **single LoD1** zone (solid, averaged `LayeredConstruction`) | ✅ Handled |
| Case 1.2 — **multiple LoD1** zones | ❌ Not handled (no coincident-face interzone; all faces collapse to one zone) |
| Case 2.1 — **single LoD2** zone, some thermal boundaries | ✅ Handled |
| Case 3.1 — **multiple LoD2** zones | ✅ Handled (thermalBoundary ownership + reciprocal `Surface` pairs) |
| Special 5.1 — single LoD2, `coincidesWithLoD2Hull=TRUE` | ✅ Handled |
| Example 4 / Case 4.1 — **multiple LoD3** zones with openings | ✅ Handled (⚠️ coplanarity caveat below) |
| Special 6.1 — single LoD3, `coincidesWithLoD3Hull=TRUE` | ✅ Handled |

**General encoding rules:** Rule 1 (inline/byReference) ✅ (`property_object` handles both) · Rule 2
(geometry XLinks) ✅ (`surfaceMember` href resolution) · Rule 4 (ThermalZone as child of Building, links by
XLink) ✅. **BuildingParts** ✅ (merged recursively). **MultiSurface with several polygons** ✅ (split into
separate surfaces).

## What each concern handles vs. doesn't

### Geometry — [building_surfaces.py](citygml2idf/semantics/building_surfaces.py), [geometry/](citygml2idf/geometry/)
**Handled:** `posList` (2D/3D); CRS read + reproject-if-geographic + recenter; Newell normal, outward
re-orientation for **convex** masses (file winding ignored), area; LoD2/3 thematic surfaces via both
`bldg:boundedBy` and `nrg3:thermalBoundary`; LoD1 solid faces classified by normal; exterior ring only
(holes ignored — correct for E+); the 3-way cascade thermalBoundary → boundedBy → raw solid.
**Not handled:**
- **Outward normals are correct only for CONVEX buildings.** Each face's outward direction is decided by
  pointing *away from the building's (or zone's) vertex-average centroid* ([building_surfaces.py](citygml2idf/semantics/building_surfaces.py) `interior = rings.centroid(all_pts)` → [rings.py](citygml2idf/geometry/rings.py) `orient_outward`). For a box/convex mass the centroid is always inside, so this is right. For a **concave footprint (L/T/U, courtyard)** the centroid can fall in the "dent" (outside the solid), so the dent-facing **inner walls get flipped inward** → wrong azimuth, and at LoD1 even wrong roof↔floor (role comes from `normal.z`). The Alderaan sample is all convex, so this never triggers there. **Fix when needed:** orient all faces *consistently* via signed volume (divergence theorem) on the closed solid — shape-proof, no centroid — with a per-face ray test as fallback for non-closed LoD2/3 sets.
- **Multi-zone LoD1 coincident-face matching** (the Case 1.2 gap).
- **Implicit-representation geometry** (`lod3ImplicitRepresentation` on zones/openings) — only explicit
  `MultiSurface` is read.
- **`bdgBdrySurfIsAdiabatic`** flag — never read; boundary is decided only by zone-count + type. The
  spec/UML say `isAdiabatic` should force Adiabatic.
- **Azimuth/Inclination cross-check** — geometry is authoritative (good), but the stated values aren't
  read back as a sanity check.

### Construction — [constructions.py](citygml2idf/model/constructions.py)
Catalogue identity is the PAIR **`(codeSpace, code)`**, never the bare code (two catalogues may reuse a
code). Resolution order (each step bypasses the rest): **Excel/DB by `(codeSpace, code)` → own inline
layers → in-file `LayeredConstructionLibrary` by `(codeSpace, code)` → `uValue` → default.**

**Handled:** `layeredConstruction` inline **and** byReference (XLink); **`libraryCode` → Excel/DB lookup
keyed by `(codeSpace, code)`** (the xlsx declares each code's catalogue in a required `code_space` column;
blank cell = agnostic → bare-code match); the construction's own in-file `layer → thickness → material`;
**in-file `LayeredConstructionLibrary` lookup by `(codeSpace, code)`** (a construction named only by
`libraryCode`, whose layers live in a library member not reached by xlink, now resolves); `uValue` →
`Material:NoMass` (R=1/U) for averaged/LoD1; `layeredConstruction` attached to **ThermalZone / BuildingPart
/ Building** context (the LoD1 averaged case); **`ReverseLayeredConstruction`** → `baseLayeredConstruction`
reversed; dedup; thickness unit conversion (m/mm/cm).
**Not handled / partial:**
- **In-file `MaterialLibrary` lookup by `libraryCode`** — materials are reached by xlink (which works);
  a material identified *only* by a bare `libraryCode` against an in-file `MaterialLibrary` is not indexed
  (the same code→library mechanism could be added for materials).
- `glazingRatio / emissivity / reflectance / transmittance` on `LayeredConstruction` — ignored (glazing
  uses the Excel default; per-window/LoD1 use of these is a separate gap below).

### Material — [constructions.py](citygml2idf/model/constructions.py)
**Handled:** `SolidMaterial` (thermalConductivity, density, specificHeatCapacity, thickness) → `Material`;
`Gas` (rValue) → `Material:AirGap`; material byReference (XLink) inside a layer; incomplete mass data →
`NoMass` fallback (R = thickness/conductivity); specific-heat kJ→J + the ≥100 clamp.
**Not handled (and not needed for an E+ thermal run):** `permeance / porosity / embodiedEnergy /
embodiedCarbon` on SolidMaterial; `Gas.isVentilated`.

### Windows — [openings.py](citygml2idf/model/openings.py)
**Handled:** explicit `bldg:Window` LoD3 geometry via `bldg:opening`; `bdgBdrySurfOpeningToSurfaceRatio`;
`(totalSurfaceArea − opaqueSurfaceArea)/totalSurfaceArea`; synthesized inset coplanar window; one default
`SimpleGlazingSystem`; windows only on exterior walls.
**Not handled / partial:**
- **Per-window glazing from the file** — the actual window's `uValue/gValue` (its own `LayeredConstruction`)
  is **ignored**; every window uses the single Excel default glazing.
- **`bldg:Door`** → folded into opaque wall (by design, EPLUS_RULES W-2/W5).
- **Non-coplanar LoD3 opening** — not projected onto the host plane (spec explicitly warns LoD3 openings may
  be non-coplanar → E+ can reject it).
- **Implicit-representation** window geometry — not read.
- `gValue → SHGC` still unverified.

## Where a window can legally come from (per LoD) — the schema reason

Window data can only live where the Energy ADE XSD gives it a **host element**, and the three LoDs have
three different hosts. This is *why* LoD1 looks "opaque" and what the robust LoD1 signal actually is.

**Each glazing carrier and its legal attachment point** (verified in `Energy_ADE_3.0_beta7.xsd`):

| Carrier (XSD element) | Substitution group / host | Needs a thematic surface? |
|---|---|---|
| `bldg:Window` / `_Opening` (+ `bdgOpnArea`) | `bldg:_GenericApplicationPropertyOfOpening` — sits under `bldg:opening` of a BoundarySurface | **Yes** + a "hole" → **LoD3** |
| `bdgBdrySurfOpeningToSurfaceRatio`, `…TotalSurfaceArea`, `…OpaqueSurfaceArea` | `bldg:_GenericApplicationPropertyOfBoundarySurface` (XSD ~lines 1618–1652) — only on a `_BoundarySurface` | **Yes** → **LoD2** (and LoD3) |
| `glazingRatio`, `gValue`, `uValue` | elements of `LayeredConstructionType` (XSD lines 1380–1382), attached via `layeredConstruction`, which is `core:_GenericApplicationPropertyOfCityObject` (line 1087) | **No** — attaches to *any* CityObject incl. **ThermalZone / Building** → **LoD1** |

**Why LoD1 has no per-surface ratio and no geometric window.** Spec §4.3.1: *"In LoD1, ThermalZones can be
modelled via a solid geometry … no further modelling is allowed using thematic surfaces."* No thematic
surface ⇒ there is no `_BoundarySurface` and no `bldg:opening` in the file, so both
`bdgBdrySurfOpeningToSurfaceRatio` **and** `bldg:Window` are schema-illegal at LoD1 — their host elements
don't exist.

**The legal LoD1 window signal = `glazingRatio` (+ `gValue`) on the averaged `LayeredConstruction`.** Because
`layeredConstruction` is a generic CityObject property, the construction hangs directly on the **ThermalZone**
(or Building) — no surface needed — and carries the averaged hull values. This is exactly Table 2 **Case
1.1**: *"a single set of averaged building physics values (e.g. U and g values) for the whole thermal hull."*

```
ThermalZone (or Building)
  └─ nrg3:layeredConstruction → LayeredConstruction
        ├─ uValue        ← averaged hull thermal transmittance
        ├─ glazingRatio  ← averaged glazed fraction of the hull   ← "do we have windows?"
        └─ gValue        ← solar heat gain of the glazing (≈ SHGC) ← "how do they perform?"
```

- `glazingRatio` present and > 0 ⇒ the building **has** windows (an averaged fraction over the whole hull,
  not per wall); `gValue` ⇒ the glazing's SHGC. Robust treatment: use `glazingRatio` as a **hull-wide WWR**
  on the geometry-classified exterior walls (same `synthesize_window` math), SHGC ← `gValue`.
- No `glazingRatio` (or = 0) ⇒ genuinely opaque.

**Summary — window provenance by LoD:**

| LoD | Thematic surfaces? | Legal window carrier | Mechanism |
|---|---|---|---|
| 0 | none (no zone geom) | — | no windows (no surfaces) |
| 1 / 1.x | **not allowed** | `glazingRatio` + `gValue` on the zone/building `LayeredConstruction` | averaged hull glazed fraction |
| 2 | yes (no holes) | `bdgBdrySurfOpeningToSurfaceRatio`, else `(total − opaque)/total` | per-surface ratio |
| 3 | yes (with holes) | explicit `bldg:Window` / `_Opening` geometry | real polygon |

> `glazingRatio`/`gValue` are *also* valid on LoD2/LoD3 constructions, but there the per-surface ratio and
> the explicit geometry are richer and take precedence.

**Honest LoD1 limitation.** LoD1 gives **one averaged `uValue`** for the whole hull (opaque + glass
blended) — never a separate opaque-U and window-U. So once a glazed fraction is split out, *which* U the
window gets is a modelling choice the file can't resolve (use a default/Excel window U, or accept the
blended U). That ambiguity is inherent to averaged LoD1 data.

**"LoD1.2 / LoD1.3".** These are CityGML 3.0 geometric sub-levels of the block model; Energy ADE 3.0 has no
`lod1.2` slot (its geometry is `lod1/2/3Solid` + `lod2/3MultiSurface`). For thermal purposes LoD1.x is
treated **exactly like LoD1**: a solid block, no thematic surfaces → glazing only via `glazingRatio`.

**Why our parser is opaque at LoD1 today.** [openings.py](citygml2idf/model/openings.py) only reads the
LoD2/LoD3 carriers (explicit `bldg:Window`, per-wall ratio/areas), and
[constructions.py](citygml2idf/model/constructions.py) reads the construction's `uValue` (→ `Material:NoMass`)
but **ignores `glazingRatio` and `gValue`**. So at LoD1 no window source fires → opaque, unless the **test**
flag `DEFAULT_WWR` injects a ratio. `DEFAULT_WWR` is effectively a stand-in for the real LoD1 signal
(`glazingRatio`) that we don't yet read.

## Gaps → where each should be added

| Gap | Step / file to add it |
|---|---|
| **Outward normals for CONCAVE buildings** (L/T/U) | replace the centroid heuristic in [rings.py](citygml2idf/geometry/rings.py) `orient_outward` / [building_surfaces.py](citygml2idf/semantics/building_surfaces.py) with consistent orientation via signed volume on the closed solid (per-face ray test as fallback) |
| Multi-zone **LoD1** interzone (coincident solid faces) | new adjacency-matcher in [zones.py](citygml2idf/model/zones.py), with faces tagged per solid in [building_surfaces.py](citygml2idf/semantics/building_surfaces.py) — runs before `assign_zones` pass 2 |
| Honor **`bdgBdrySurfIsAdiabatic`** | read it in [building_surfaces.py](citygml2idf/semantics/building_surfaces.py); let it win in `assign_zones` pass 2 ([zones.py](citygml2idf/model/zones.py)) |
| **LoD3 opening coplanarity** projection | [openings.py](citygml2idf/model/openings.py) `explicit_windows` — project ring onto host-wall plane (or warn+skip) |
| **LoD1 windows** from `glazingRatio` | [openings.py](citygml2idf/model/openings.py) — add a LoD1 branch to the W1 cascade: read `glazingRatio` (+ `gValue`) from the zone/building `LayeredConstruction` ([constructions.py](citygml2idf/model/constructions.py)) and use it as a hull-wide WWR (the real, non-test analogue of `DEFAULT_WWR`) |
| **Per-window** glazing from file U/g | [openings.py](citygml2idf/model/openings.py) + [constructions.py](citygml2idf/model/constructions.py) — build a `SimpleGlazingSystem`/`Glazing+Gas` from the window's own `LayeredConstruction` instead of the Excel default |
| ~~In-file **construction** library by `libraryCode`~~ — **DONE** | Implemented: catalogue identity is `(codeSpace, code)`; `_index_file_library` resolves `LayeredConstructionLibrary` members by code. Remaining: extend the same `(codeSpace, code)` index to **`MaterialLibrary`** members in [constructions.py](citygml2idf/model/constructions.py). |
| **Implicit-representation** geometry | [xml_io.py](citygml2idf/citygml/xml_io.py) — resolve `ImplicitGeometry` (ref point + transform + relative geometry), then feed openings/surfaces |
| Azimuth/inclination cross-check | a new semantic-validate step (warn-only) |
| Loads/HVAC (`isHeated/isCooled`, `infiltrationRate`, `usageZone`, EPC) | out of current scope — a later loads module |

## Priority note

Of the gaps above, three would make a real-world file **fail or be silently wrong** rather than merely
under-detailed:
1. **Concave building** (L/T/U) — inner walls flip inward (wrong azimuth; wrong roof/floor at LoD1).
2. **Multi-zone LoD1** (Case 1.2) — faces collapse into one zone.
3. **Non-coplanar LoD3 opening** — EnergyPlus can reject the sub-surface.

All three are **untriggered by the current sample**: every Alderaan building is convex, single-zone-per-shape
or hull/thermalBoundary based, with coplanar/ratio openings. Everything else degrades gracefully (defaults +
warnings). The `validation_file/Alderaan_*` samples include a `CoincidesWithLoD2Hull` file, which exercises
special case 5.1 (handled).
