<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================================
  Energy ADE 3.0, Table 2, CASE 1.1
  "Single LoD1 thermal zone, no thermal openings, no thermal boundaries"
  SYNTHETIC, self-contained (every reference resolves inside this file).
  ============================================================================

  PARSE PATH (what the reader must do with this file)
    geometry      : the 6 polygons of bldg:lod1Solid (there are no thematic surfaces
                    and no thermal boundaries). Each face keeps the file's winding; its
                    role comes from its direction: up = roof, down = ground, sideways = wall.
    zones         : one nrg3:ThermalZone, the only zone of an LoD1 building, owns the
                    whole hull.
    constructions : the zone's averaged LayeredConstruction (uValue 0.5, no layers)
                    reaches all 6 faces -> Material:NoMass, R = 1 / 0.5 = 2.0 m2-K/W.
    windows       : none (LoD1 has no openings).
    infiltration  : nrg3:infiltrationRate 0.3 1/h -> ZoneInfiltration 0.3 ACH.

  GEOMETRY
  A 10 (x) x 8 (y) x 3 (z) box at the origin; every face counter-clockwise seen
  from outside (its normal points out).
    ground z=0   80 m2  |  roof  z=3   80 m2
    south  y=0   30 m2  |  north y=8   30 m2  |  east x=10  24 m2  |  west x=0  24 m2
  Total envelope 268 m2; zone volume 240 m3 (= the stated nrg3:volume).
  The box is non-cubic on purpose, so an axis swap would show.

  ENERGY ADE CONTENT (the spec's LoD1 rules: Table 1 and Table 2, case 1.1)
    * One ThermalZone, with an optional LoD1 solid of its own that XLinks the
      building's lod1Solid polygons (it must not be read as extra faces).
    * No thermalBoundary and no openings: neither is allowed in LoD1.
    * coincidesWithLod2Hull / coincidesWithLod3Hull = false (mandatory in the XSD,
      not used in LoD1).
    * ONE averaged LayeredConstruction on the zone, inline: uValue 0.5 W/(K*m^2).

  TEST AIM
    1. XSD gate passes (CityGML 2.0 + Energy ADE 3.0 beta7).
    2. Exactly 6 surfaces from bldg:lod1Solid, with the roles and areas above.
    3. All 6 use the zone's construction: Material:NoMass, R = 2.0 m2-K/W.
    4. One E+ Zone owns all 6 surfaces; ZoneInfiltration 0.3 ACH; no windows.
    5. EnergyPlus exit 0, 0 Severe / 0 Fatal, with ONE expected warning, "This
       building has no thermal mass": a U-value-only construction has none.
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
							<nrg3:type codeSpace="http://www.sig3d.org/citygml/2.0/energy/3.0/VolumeTypeValue">grossVolume</nrg3:type>
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

					<!-- air leakage through the fabric; E+ ZoneInfiltration:DesignFlowRate, AirChanges/Hour -->
					<nrg3:infiltrationRate uom="1/h">0.3</nrg3:infiltrationRate>
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
