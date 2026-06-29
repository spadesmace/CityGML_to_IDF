"""
xml_io.py — the ONLY module in citygml2idf that knows about lxml/XML.

Everything else (geometry, lod, surfaces, zones, openings, constructions) talks
to CityGML through the small, clean API here. If we ever swap the XML library,
this is the single file that changes.

Two facts about CityGML drive this module's design:

1. Match by NAMESPACE URI, never by prefix.
   The file writes `bldg:WallSurface`, `nrg3:ThermalZone`, ... but those prefixes
   are arbitrary — another exporter may call the Energy ADE `energy:` instead of
   `nrg3:`. The URI (e.g. http://www.citygml.org/ade/energy/3.0) is the stable
   contract, so we look elements up by URI. The URIs live in NS below = the ONE
   place to edit for a different schema version.

2. Geometry is shared by REFERENCE.
   A LOD2/3 `gml:Solid` does not contain coordinates — it says
   `<gml:surfaceMember xlink:href="#b2_ground"/>` and the actual polygon lives
   under `bldg:boundedBy`. So on load we index every element that has a `gml:id`
   into a registry, and `resolve()` follows an xlink in O(1).

Run as a demo (from the repo root):
    python -m citygml2idf.xml_io [path-to-citygml]
prints the building list with each building's LOD + zone counts, and proves
xlink resolution + posList parsing on one shared polygon.
"""

from __future__ import annotations

import os
import sys
from urllib.parse import urlparse

from lxml import etree

# WHY: stable namespace URIs (see point 1 above). Prefixes here are just our own
# short handles; the URIs are what actually match elements in any valid file.
NS = {
    "gml":   "http://www.opengis.net/gml",
    "core":  "http://www.opengis.net/citygml/2.0",
    "bldg":  "http://www.opengis.net/citygml/building/2.0",
    "grp":   "http://www.opengis.net/citygml/cityobjectgroup/2.0",
    "gen":   "http://www.opengis.net/citygml/generics/2.0",
    "nrg":   "http://www.citygml.org/ade/energy/3.0",
    "xlink": "http://www.w3.org/1999/xlink",
}

# WHY: these two attributes are read constantly; precompute their qualified form.
XLINK_HREF = f"{{{NS['xlink']}}}href"
GML_ID = f"{{{NS['gml']}}}id"

# WHY: resolve data paths relative to the PACKAGE root (citygml2idf/), not this
# file's folder — this module lives one level down in citygml/, while input/,
# output/ and validation_file/ sit at the package root. Computing _PKG keeps the
# paths correct no matter how deep we nest the readers.
_HERE = os.path.dirname(os.path.abspath(__file__))
_PKG = os.path.dirname(_HERE)                      # citygml2idf/
DEFAULT_INPUT = os.path.join(_PKG, "input", "sample_energyADE.gml")


# WHY: robustness rule (carried over from the CityJSON work) — never crash
# silently on imperfect input; surface problems as plain warnings and continue.
def warn(msg):
    print(f"[xml_io] WARNING: {msg}", file=sys.stderr)


def qualified_name(prefix, local, ns=NS):
    """('bldg', 'Building') -> '{http://...building/2.0}Building' (lxml's form)."""
    return f"{{{ns[prefix]}}}{local}"


def local_name(el):
    """Tag without its namespace, e.g. '{..}WallSurface' -> 'WallSurface'."""
    return etree.QName(el).localname


class CityGMLDoc:
    """A loaded CityGML file plus the two things every other module needs:
    a resolved namespace map and a gml:id -> element registry."""

    def __init__(self, path):
        self.path = path
        # WHY: tolerant parser — strip insignificant whitespace, allow big trees,
        # and do NOT fetch external entities (safer + faster).
        parser = etree.XMLParser(remove_blank_text=True, huge_tree=True,
                                 resolve_entities=False)
        self.tree = etree.parse(path, parser)
        self.root = self.tree.getroot()
        self.ns = self._resolve_namespaces()
        self._by_id = self._index_by_id()

    # --- setup -------------------------------------------------------------
    def _resolve_namespaces(self):
        # WHY: keep our stable URIs, but auto-adopt the file's actual Energy ADE
        # URI if it targets a slightly different version — otherwise a new file
        # could silently match nothing.
        ns = dict(NS)
        for uri in (self.root.nsmap or {}).values():
            if uri and "ade/energy" in uri:
                ns["nrg"] = uri
        return ns

    def _index_by_id(self):
        # WHY: build the xlink registry once (see point 2 in the module docstring).
        idx = {}
        for el in self.root.iter():
            gid = el.get(GML_ID)
            if gid is not None:
                idx[gid] = el
        return idx

    # --- lookups -----------------------------------------------------------
    def qualified_name(self, prefix, local):
        """Qualified name using THIS document's resolved namespaces."""
        return qualified_name(prefix, local, self.ns)

    def iter_type(self, prefix, local):
        """Every element of a qualified type, anywhere in the tree (a generator)."""
        return self.root.iter(self.qualified_name(prefix, local))

    def descendants(self, el, prefix, local):
        """All matching elements at any depth under `el`."""
        return el.findall(f".//{self.qualified_name(prefix, local)}")

    def children(self, el, prefix, local):
        """Immediate children only — matters when the same type can nest."""
        want = self.qualified_name(prefix, local)
        return [c for c in el if c.tag == want]

    def get_by_id(self, gml_id):
        """Element carrying gml:id == gml_id, or None."""
        return self._by_id.get(gml_id)

    def resolve_xlink(self, el):
        """Follow an element's xlink:href to the referenced element.

        Same-document references normally look like '#id'. Some valid producer
        files write a bare relative id ('id') instead, so we accept both when
        the target exists in this document.
        """
        href = el.get(XLINK_HREF)
        if not href:
            return None
        if href.startswith("#"):
            target = self._by_id.get(href[1:])
            if target is None:
                warn(f"xlink href '{href}' not found in document")
            return target
        target = self._by_id.get(href)
        if target is not None:
            return target
        warn(f"external xlink href not resolvable locally: '{href}'")
        return None

    def property_object(self, property_el):
        """Return the object carried by a CityGML/ADE property element.

        XSD pattern, used everywhere in CityGML:
          <someProperty><TargetObject .../></someProperty>   = inline
          <someProperty xlink:href="#target_id"/>            = by reference

        The schema usually allows one OR the other. If a bad file gives both, we
        warn and keep the inline object because it is the most local statement.
        """
        inline = next((child for child in property_el if isinstance(child.tag, str)), None)
        href = property_el.get(XLINK_HREF)
        if inline is not None and href:
            warn(f"property <{local_name(property_el)}> has both inline object and xlink '{href}'; using inline")
        if inline is not None:
            return inline
        return self.resolve_xlink(property_el)


# === geometry-text helpers (still pure XML, no math yet) =====================

def buildings(doc):
    """Every bldg:Building in the file (entry point for the readers)."""
    return list(doc.iter_type("bldg", "Building"))


def srs_name(doc):
    """The document CRS string, e.g. 'urn:ogc:def:crs:EPSG::25832', read from the
    first element that declares an srsName. (Parsing the EPSG code is geometry's
    job — this module just hands back the raw string.)"""
    for el in doc.root.iter():
        s = el.get("srsName")
        if s:
            return s
    return None

# Interior-ring policy:
# CityGML/GML polygons may have interior rings for holes/openings. EnergyPlus
# BuildingSurface:Detailed has no hole field; holes are represented by separate
# FenestrationSurface:Detailed objects. So geometry reads the exterior ring here,
# and openings.py writes explicit windows later when enabled.
def read_pos_list(doc, geom_el):
    """Parse the first gml:posList under `geom_el` into [(x, y, z), ...].

    Honours srsDimension (2 or 3; pads z=0.0 when the data is 2D). Returns the
    ring exactly as written (still closed: last point == first). Interior rings
    (holes) are out of scope for now — we take the exterior ring only.
    """
    pl = geom_el.find(f".//{doc.qualified_name('gml', 'posList')}")
    if pl is None:
        # A MultiSurface may carry only <gml:surfaceMember xlink:href="#polygon">.
        # Follow the first member to the real polygon, then parse its posList.
        for member in geom_el.findall(f".//{doc.qualified_name('gml', 'surfaceMember')}"):
            target = doc.property_object(member)
            if target is not None:
                return read_pos_list(doc, target)
        return []
    if not (pl.text and pl.text.strip()):
        return []
    dim = int(pl.get("srsDimension", 3))
    nums = [float(v) for v in pl.text.split()]
    pts = []
    for i in range(0, len(nums) - dim + 1, dim):
        x, y = nums[i], nums[i + 1]
        z = nums[i + 2] if dim >= 3 else 0.0
        pts.append((x, y, z))
    return pts


# === optional XSD validation gate ===========================================
# WHY: the Energy ADE schema imports the CityGML/GML schemas by WEB URL
# (http://schemas.opengis.net/...). To validate OFFLINE we intercept each of
# those requests and serve the matching local file from validation_file/. The
# whole gate is best-effort: if the schema can't be built (a needed import is
# missing or unreachable) we WARN and continue — we never block a parse on it.

VALIDATION_ROOT = os.path.join(_PKG, "validation_file")
VALIDATION_SCHEMA_DIR = os.path.join(VALIDATION_ROOT, "CityGml_ADE_SChema")
ENERGY_XSD = os.path.join(VALIDATION_SCHEMA_DIR, "Energy_ADE_3.0_beta7.xsd")


class _LocalXSDResolver(etree.Resolver):
    """Serve any imported schema (referenced by URL) from a local folder, matched
    by file name. Returns None for anything we don't have -> lxml's default
    behaviour takes over (which may then try the network)."""

    def __init__(self, search_dirs):
        self.search_dirs = search_dirs

    def resolve(self, system_url, public_id, context):
        if system_url:
            name = os.path.basename(urlparse(system_url).path) or system_url
            for d in self.search_dirs:
                cand = os.path.join(d, name)
                if os.path.isfile(cand):
                    return self.resolve_filename(cand, context)
        return None


def build_schema(entry_xsd=ENERGY_XSD):
    """Compile the Energy ADE schema, resolving its imports from validation_file/.
    Raises on failure (caller decides whether to warn-and-skip)."""
    if not os.path.isfile(entry_xsd):
        raise FileNotFoundError(entry_xsd)
    search = [
        VALIDATION_SCHEMA_DIR,
        os.path.join(VALIDATION_SCHEMA_DIR, "codelists"),
        os.path.join(VALIDATION_SCHEMA_DIR, "gml3.1.1base"),
    ]
    parser = etree.XMLParser()
    parser.resolvers.add(_LocalXSDResolver(search))
    xsd_doc = etree.parse(entry_xsd, parser)
    return etree.XMLSchema(xsd_doc)


def validate(path=None, entry_xsd=ENERGY_XSD, max_report=15):
    """Best-effort schema validation. Returns True/False when validation could
    run, or None when the schema couldn't even be built (then we just warn)."""
    path = path or DEFAULT_INPUT
    try:
        schema = build_schema(entry_xsd)
    except Exception as e:
        warn(f"validation skipped - could not build schema ({type(e).__name__}: {e})")
        return None
    try:
        ok = schema.validate(etree.parse(path))
    except Exception as e:
        warn(f"validation skipped - could not validate ({type(e).__name__}: {e})")
        return None
    if ok:
        print("[xml_io] XSD validation: PASSED")
    else:
        errs = list(schema.error_log)
        warn(f"XSD validation found {len(errs)} issue(s) (showing up to {max_report}):")
        for err in errs[:max_report]:
            warn(f"  line {err.line}: {err.message}")
    return ok


# === demo ====================================================================

def _demo(path=None):
    path = path or DEFAULT_INPUT
    validate(path)                       # best-effort schema gate (warns, never blocks)
    doc = CityGMLDoc(path)
    print(f"Loaded            : {os.path.basename(path)}")
    print(f"CRS (srsName)     : {srs_name(doc)}")
    print(f"Energy ADE URI    : {doc.ns['nrg']}")
    print(f"gml:id elements   : {len(doc._by_id)}")

    bs = buildings(doc)
    print(f"Buildings         : {len(bs)}")
    for b in bs:
        bid = b.get(GML_ID)
        lods = [l for l in ("lod1Solid", "lod2Solid", "lod3Solid")
                if b.find(f".//{doc.qualified_name('bldg', l)}") is not None]
        n_bounded = len(doc.descendants(b, "bldg", "boundedBy"))
        n_zones = len(doc.descendants(b, "nrg", "ThermalZone"))
        print(f"  - {bid:<12} geom={lods or ['(none)']}  "
              f"boundedBy={n_bounded}  thermalZones={n_zones}")

    # Prove xlink resolution + posList parsing on the first referenced surface.
    for sm in doc.iter_type("gml", "surfaceMember"):
        if sm.get(XLINK_HREF):
            target = doc.resolve_xlink(sm)
            pts = read_pos_list(doc, target) if target is not None else []
            print(f"xlink demo        : {sm.get(XLINK_HREF)} -> "
                  f"<{local_name(target)} id={target.get(GML_ID)}>, "
                  f"{len(pts)} pts, first={pts[0] if pts else None}")
            break


if __name__ == "__main__":
    _demo(sys.argv[1] if len(sys.argv) > 1 else None)
