"""The ONLY module that touches lxml: load a CityGML file, follow references, read rings.

1. Match by namespace URI, never by prefix: a file may call the Energy ADE `energy:` instead
   of `nrg3:`; the URI is the contract. The URIs live in NS, the one place to edit.
2. Objects are shared by reference (xlink:href="#id", GML 3.1.1): every gml:id is indexed once
   on load, and property_object reads any property inline or by xlink.
"""

from __future__ import annotations

import sys

from lxml import etree

# Namespace URIs (point 1); the prefixes are only our short handles.
NS = {
    "gml":   "http://www.opengis.net/gml",
    "core":  "http://www.opengis.net/citygml/2.0",
    "bldg":  "http://www.opengis.net/citygml/building/2.0",
    "nrg":   "http://www.citygml.org/ade/energy/3.0",
    "xlink": "http://www.w3.org/1999/xlink",
}

# The two attributes read everywhere, in lxml's {uri}name form.
XLINK_HREF = f"{{{NS['xlink']}}}href"
GML_ID = f"{{{NS['gml']}}}id"

# Every object we turn into an EnergyPlus name or look up by gml:id. gml:id is OPTIONAL
# (gmlBase.xsd AbstractGMLType: use="optional"), so a valid file may leave it out; such an object
# gets a generated id when the file is loaded (CityGMLDoc._index_by_id).
# The lists are the XSD substitution groups: bldg:_BoundarySurface (9) + the 4 Energy ADE
# surfaces, bldg:_Opening, nrg3:AbstractLayeredConstruction, nrg3:AbstractMaterial, + holders.
NAMED_OBJECTS = frozenset({
    "Building", "ThermalZone", "Polygon",
    "WallSurface", "RoofSurface", "GroundSurface", "ClosureSurface", "FloorSurface",
    "OuterFloorSurface", "InteriorWallSurface", "CeilingSurface", "OuterCeilingSurface",
    "PartyWallSurface", "IntermediateFloorSurface", "AtticFloorSurface", "BasementCeilingSurface",
    "Window", "Door",
    "LayeredConstruction", "ReverseLayeredConstruction", "Layer", "SolidMaterial", "Gas",
})


def warn(msg):
    """Print a warning and go on: bad input never stops the run."""
    print(f"[xml_io] WARNING: {msg}", file=sys.stderr)


def local_name(el):
    """Tag without its namespace, e.g. '{..}WallSurface' -> 'WallSurface'."""
    return etree.QName(el).localname


class CityGMLDoc:
    """A loaded CityGML file: its namespaces and its gml:id -> element registry."""

    def __init__(self, path):
        if not path:
            raise SystemExit("CityGMLDoc: pass a CityGML/.gml path")
        self.path = path
        # no external entities are fetched; big files are allowed
        parser = etree.XMLParser(remove_blank_text=True, huge_tree=True,
                                 resolve_entities=False)
        self.tree = etree.parse(path, parser)
        self.root = self.tree.getroot()
        self.ns = self._resolve_namespaces()
        self._by_id = self._index_by_id()

    # --- setup -------------------------------------------------------------
    def _resolve_namespaces(self):
        """NS, but with the file's own Energy ADE URI when it declares a different one."""
        ns = dict(NS)
        for uri in (self.root.nsmap or {}).values():
            if uri and "ade/energy" in uri:
                ns["nrg"] = uri
        return ns

    def _index_by_id(self):
        """Build the gml:id -> element registry once, generating the ids a file leaves out.

        Returns
        -------
        dict
            gml:id -> element, for the file's own ids and the generated ones.

        Notes
        -----
        gml:id is optional (gmlBase.xsd AbstractGMLType), so a VALID file may have an object
        without one. Each NAMED_OBJECTS element without an id gets
        `<nearest ancestor gml:id>_<local name>_<n>` (n = 1, 2, ... in file order), e.g.
        `Case11_solid_Polygon_1`. It is set on the in-memory element only (the file is never
        changed), the same file always gives the same names, and every lookup and EnergyPlus
        name downstream works as for a real id. No warning: a missing id is valid input.
        """
        idx = {}
        for el in self.root.iter(tag=etree.Element):              # the file's own ids
            gid = el.get(GML_ID)
            if gid is not None:
                idx[gid] = el
        counts = {}
        for el in self.root.iter(tag=etree.Element):              # file order: parents first
            if el.get(GML_ID) is not None or local_name(el) not in NAMED_OBJECTS:
                continue
            parent_id = next((a.get(GML_ID) for a in el.iterancestors() if a.get(GML_ID)),
                             local_name(self.root))
            key = (parent_id, local_name(el))
            gid = None
            while gid is None or gid in idx:                      # never reuse a file's own id
                counts[key] = counts.get(key, 0) + 1
                gid = f"{parent_id}_{local_name(el)}_{counts[key]}"
            el.set(GML_ID, gid)
            idx[gid] = el
        return idx

    # --- lookups -----------------------------------------------------------
    def qualified_name(self, prefix, local):
        """('bldg', 'Building') -> '{http://...building/2.0}Building', with this file's namespaces."""
        return f"{{{self.ns[prefix]}}}{local}"

    def iter_type(self, prefix, local):
        """Every element of one type anywhere in the tree (a generator), e.g. a Building under
        cityObjectMember or under a CityObjectGroup."""
        return self.root.iter(self.qualified_name(prefix, local))

    def children(self, el, prefix, local):
        """Immediate children only — matters when the same type can nest."""
        want = self.qualified_name(prefix, local)
        return [c for c in el if c.tag == want]

    def get_by_id(self, gml_id):
        """Element carrying gml:id == gml_id, or None."""
        return self._by_id.get(gml_id)

    def resolve_xlink(self, el):
        """The element an xlink:href points to, or None with a warning.

        Accepts '#id' and a bare 'id' (some producers write it). A reference into another
        file cannot be followed: one file is read at a time.
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
        if inline is not None and href:  # if we have both, keep inline (most local)
            warn(f"property <{local_name(property_el)}> has both inline object and xlink '{href}'; using inline")
        if inline is not None:
            return inline
        return self.resolve_xlink(property_el)


# === file-level readers =======================================================
def buildings(doc):
    """Every bldg:Building in the file."""
    return list(doc.iter_type("bldg", "Building"))


def srs_name(doc):
    """The file's CRS string, e.g. 'urn:ogc:def:crs:EPSG::25832' (the first srsName found), or None."""
    for el in doc.root.iter():
        s = el.get("srsName")
        if s:
            return s
    return None

# === geometry: ONE reader for every building surface, LoD1 solid and window ===
# Interior rings (holes) are not read: EnergyPlus BuildingSurface:Detailed has no hole field;
# openings are written as their own FenestrationSurface:Detailed objects.
def _point(values):
    """(x, y, z) from 2 or 3 numbers (z = 0.0 for 2D data)."""
    return (values[0], values[1], values[2] if len(values) >= 3 else 0.0)


def read_ring(doc, polygon):
    """The exterior ring of ONE gml:Polygon as [(x, y, z), ...], exactly as written.

    Parameters
    ----------
    doc : CityGMLDoc
        The parsed CityGML file.
    polygon : lxml element
        A gml:Polygon.

    Returns
    -------
    list of tuple
        The points (closing point kept); [] with a warning when the ring cannot be read.

    Notes
    -----
    GML 3.1.1 LinearRingType: posList, or a sequence of pos / pointProperty / pointRep, or
    coordinates, or coord. We read posList and pos only; the others warn
    "not supported yet". posList honours srsDimension (default 3; 2 -> z = 0.0).
    """
    exterior = doc.children(polygon, "gml", "exterior")
    ring = doc.children(exterior[0], "gml", "LinearRing") if exterior else []
    if not ring:
        warn(f"polygon {polygon.get(GML_ID)}: no gml:exterior/gml:LinearRing; not supported yet")
        return []
    pos_list = doc.children(ring[0], "gml", "posList")
    if pos_list:
        dim = int(pos_list[0].get("srsDimension", 3))
        nums = [float(v) for v in (pos_list[0].text or "").split()]
        return [_point(nums[i:i + dim]) for i in range(0, len(nums) - dim + 1, dim)]
    positions = doc.children(ring[0], "gml", "pos")
    if positions:
        points = []
        for p in positions:
            numbers = [float(v) for v in (p.text or "").split()]
            points.append(_point(numbers))
        return points
    written_as = sorted({local_name(c) for c in ring[0] if isinstance(c.tag, str)})
    warn(f"polygon {polygon.get(GML_ID)}: ring written as {written_as}; not supported yet "
         f"(only gml:posList or gml:pos)")
    return []


def surface_polygons(doc, geometry):
    """Every gml:Polygon of one surface geometry, with its exterior ring, in file order.

    Parameters
    ----------
    doc : CityGMLDoc
        The parsed CityGML file.
    geometry : lxml element
        A gml:Polygon, MultiSurface, CompositeSurface or Solid.

    Returns
    -------
    list of (lxml element, list of tuple)
        (polygon, ring) pairs; a ring is [] when it cannot be read (read_ring warned).

    Notes
    -----
    GML 3.1.1: MultiSurface / CompositeSurface -> surfaceMember (or the surfaceMembers array);
    Solid -> exterior. Every member is opened with property_object, so inline AND xlink work at
    every level. Any other geometry (e.g. OrientableSurface) warns "not supported yet".
    """
    kind = local_name(geometry)
    if kind == "Polygon":
        return [(geometry, read_ring(doc, geometry))]
    if kind in ("MultiSurface", "CompositeSurface"):
        members = [doc.property_object(m) for m in doc.children(geometry, "gml", "surfaceMember")]
        for array in doc.children(geometry, "gml", "surfaceMembers"):
            members.extend(child for child in array if isinstance(child.tag, str))
    elif kind == "Solid":
        members = [doc.property_object(e) for e in doc.children(geometry, "gml", "exterior")]
    else:
        warn(f"gml:{kind}: not supported yet")
        return []
    pairs = []
    for member in members:
        if member is not None:
            pairs.extend(surface_polygons(doc, member))
    return pairs
