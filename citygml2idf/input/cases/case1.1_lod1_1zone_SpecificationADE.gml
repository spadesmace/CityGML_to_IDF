<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================================
  Energy ADE 3.0 — Table 2, CASE 1.1
  "Single LoD1 thermal zone, no thermal openings, no thermal boundaries"
  SYNTHETIC, self-contained (every reference resolves inside this file).
  ============================================================================

  PARSE PATH (what the pipeline is expected to take)
    geometry  : SurfacePath.RAW_SOLID_FALLBACK
                No bldg:boundedBy thematic surfaces and no nrg3:thermalBoundary
                exist, so select_surface_path() falls through to the raw faces of
                bldg:lod1Solid; each face's role comes from its OUTWARD NORMAL
                (geometry/classify.py), never from a label.
    physics   : construction-owner cascade -> surface (a gml:Polygon, cannot own a
                LayeredConstruction) -> ThermalZone CONTEXT -> Tier 2 (uValue, no
                layers) -> Material:NoMass with R = 1/U.
    zoning    : one nrg3:ThermalZone -> one E+ Zone owning the whole hull.

  GEOMETRY
    A 10 (x) x 8 (y) x 3 (z) box at the origin. Deliberately non-cubic so an
    axis swap would be visible. Faces are wound CCW seen from OUTSIDE.
      ground  z=0        area 80 m2   -> Floor / Ground
      roof    z=3        area 80 m2   -> Roof  / Outdoors
      south   y=0        area 30 m2   |
      north   y=8        area 30 m2   |-> Wall / Outdoors
      east    x=10       area 24 m2   |
      west    x=0        area 24 m2   |
    Total envelope = 268 m2. Zone volume = 240 m3.

  ENERGY ADE CONTENT (per the spec's rules for LoD1)
    * ThermalZone modelled, with an OPTIONAL LoD1 solid of its own. Per the spec
      that solid XLINKS the homologous polygons of the building's lod1Solid
      instead of duplicating them — this also proves the parser does NOT
      double-count those faces (it reads bldg:lod1Solid only).
    * NO thermalBoundary and NO thermal openings — both forbidden in LoD1.
    * coincidesWithLod2Hull / coincidesWithLod3Hull = false: they are LoD2/LoD3
      concepts and do not apply here (the XSD makes both elements MANDATORY on
      ThermalZoneType, so they must still be written).
    * ONE averaged LayeredConstruction associated to the THERMAL ZONE, carrying a
      single U value for the whole thermal hull (Table 2, case 1.1). It is INLINE
      here (case 2.1 covers the xlink form). No gValue: there are no openings.

  TEST AIM
    1. The file passes the offline XSD gate (CityGML 2.0 + Energy ADE 3.0 beta7).
    2. The parser picks RAW_SOLID_FALLBACK and yields exactly 6 surfaces with the
       roles/areas above.
    3. The single hull construction on the ZONE reaches all 6 surfaces through the
       context cascade (Tier 2 -> Material:NoMass, R = 1/0.5 = 2.0 m2-K/W).
    4. One E+ Zone owns all 6 surfaces.
    5. EnergyPlus runs with exit 0 and 0 Severe / 0 Fatal.
-->
<core:CityModel xmlns:core="http://www.opengis.net/citygml/2.0"
                xmlns:bldg="http://www.opengis.net/citygml/building/2.0"
                xmlns:gml="http://www.opengis.net/gml"
                xmlns:nrg3="http://www.citygml.org/ade/energy/3.0"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<gml:name>Energy ADE Case 1.1 - LoD1 single thermal zone, no boundaries, no openings</gml:name>
	<gml:boundedBy>
		<gml:Envelope srsName="EPSG:28992" srsDimension="3">
			<gml:lowerCorner>0 0 0</gml:lowerCorner>
			<gml:upperCorner>10 8 3</gml:upperCorner>
		</gml:Envelope>
	</gml:boundedBy>

	<core:cityObjectMember>
		<bldg:Building gml:id="Case11_LoD1_1zone">
			<gml:name>Case 1.1 building</gml:name>
			<bldg:function codeSpace="building_function">1000</bldg:function>
			<bldg:yearOfConstruction>1985</bldg:yearOfConstruction>
			<bldg:measuredHeight uom="m">3.0</bldg:measuredHeight>

			<!-- ===== the ONLY geometry source: the LoD1 solid (no thematic surfaces) ===== -->
			<bldg:lod1Solid>
				<gml:Solid gml:id="Case11_solid">
					<gml:exterior>
						<gml:CompositeSurface srsName="EPSG:28992" srsDimension="3">

							<!-- ground, z = 0, outward normal -Z -->
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case11_poly_ground">
									<gml:exterior><gml:LinearRing>
										<gml:posList>0 0 0  0 8 0  10 8 0  10 0 0  0 0 0</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>

							<!-- flat roof, z = 3, outward normal +Z -->
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case11_poly_roof">
									<gml:exterior><gml:LinearRing>
										<gml:posList>0 0 3  10 0 3  10 8 3  0 8 3  0 0 3</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>

							<!-- south wall, y = 0, outward normal -Y -->
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case11_poly_wall_south">
									<gml:exterior><gml:LinearRing>
										<gml:posList>0 0 0  10 0 0  10 0 3  0 0 3  0 0 0</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>

							<!-- east wall, x = 10, outward normal +X -->
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case11_poly_wall_east">
									<gml:exterior><gml:LinearRing>
										<gml:posList>10 0 0  10 8 0  10 8 3  10 0 3  10 0 0</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>

							<!-- north wall, y = 8, outward normal +Y -->
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case11_poly_wall_north">
									<gml:exterior><gml:LinearRing>
										<gml:posList>10 8 0  0 8 0  0 8 3  10 8 3  10 8 0</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>

							<!-- west wall, x = 0, outward normal -X -->
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case11_poly_wall_west">
									<gml:exterior><gml:LinearRing>
										<gml:posList>0 8 0  0 0 0  0 0 3  0 8 3  0 8 0</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>

						</gml:CompositeSurface>
					</gml:exterior>
				</gml:Solid>
			</bldg:lod1Solid>

			<!-- ===== the single thermal zone ===== -->
			<nrg3:thermalZone>
				<nrg3:ThermalZone gml:id="Case11_zone">
					<gml:name>Case 1.1 thermal zone</gml:name>

					<!-- ONE averaged construction for the WHOLE thermal hull (Table 2, case 1.1).
					     Associated to the ZONE, not to any surface: in LoD1 no surface object
					     exists that could own it. -->
					<nrg3:layeredConstruction>
						<nrg3:LayeredConstruction gml:id="Case11_constr_hull">
							<gml:name>Averaged hull construction U=0.50</gml:name>
							<nrg3:uValue uom="W/(K*m^2)">0.5</nrg3:uValue>
						</nrg3:LayeredConstruction>
					</nrg3:layeredConstruction>

					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:value uom="m^3">240</nrg3:value>
							<nrg3:type codeSpace="volume_codeSpace">grossVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>

					<!-- OPTIONAL zone solid: XLinks to the homologous polygons of the building's
					     LoD1 solid (spec, case 1.1). Not a second copy of the geometry. -->
					<nrg3:lod1Solid>
						<gml:Solid gml:id="Case11_zone_solid">
							<gml:exterior>
								<gml:CompositeSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember xlink:href="#Case11_poly_ground"/>
									<gml:surfaceMember xlink:href="#Case11_poly_roof"/>
									<gml:surfaceMember xlink:href="#Case11_poly_wall_south"/>
									<gml:surfaceMember xlink:href="#Case11_poly_wall_east"/>
									<gml:surfaceMember xlink:href="#Case11_poly_wall_north"/>
									<gml:surfaceMember xlink:href="#Case11_poly_wall_west"/>
								</gml:CompositeSurface>
							</gml:exterior>
						</gml:Solid>
					</nrg3:lod1Solid>

					<nrg3:isCooled>false</nrg3:isCooled>
					<nrg3:isHeated>true</nrg3:isHeated>
					<!-- LoD2/LoD3 concepts; false here (both are MANDATORY in the XSD) -->
					<nrg3:coincidesWithLod2Hull>false</nrg3:coincidesWithLod2Hull>
					<nrg3:coincidesWithLod3Hull>false</nrg3:coincidesWithLod3Hull>

					<!-- NO nrg3:thermalBoundary: forbidden in LoD1. -->
				</nrg3:ThermalZone>
			</nrg3:thermalZone>
		</bldg:Building>
	</core:cityObjectMember>
</core:CityModel>
