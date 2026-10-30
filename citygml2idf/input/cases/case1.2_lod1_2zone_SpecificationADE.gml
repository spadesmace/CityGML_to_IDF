<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================================
  Energy ADE 3.0, Table 2, CASE 1.2
  "Multiple LoD1 thermal zones, no thermal openings, no thermal boundaries"
  SYNTHETIC, self-contained (every reference resolves inside this file).
  ============================================================================

  PARSE PATH (what the reader must do with this file)
    geometry      : each zone's own nrg3:lod1Solid (6 faces per zone). A face that is an
                    XLink to a polygon of the building's bldg:lod1Solid is EXTERIOR; a face
                    with a polygon of its own (the shared slab) lies BETWEEN the two zones.
                    Each face keeps the file's winding; the role of an exterior face comes
                    from its direction: up = roof, down = ground, sideways = wall.
    zones         : two nrg3:ThermalZone; each owns the 6 faces of its own solid.
    shared slab   : written twice, once per zone, the same 4 corners in opposite order:
                    the lower zone's copy points up (its ceiling), the upper zone's copy
                    points down (its floor). Both are interior faces (adiabatic by default).
    constructions : each zone's own averaged LayeredConstruction reaches its own 6 faces:
                    lower uValue 0.5 gives R = 2.0, upper uValue 0.4 gives R = 2.5 m2-K/W.
    windows       : none (LoD1 has no openings).
    infiltration  : nrg3:infiltrationRate 0.3 1/h on each zone.

  GEOMETRY
  A 10 (x) x 8 (y) x 6 (z) block at the origin, two storeys of 3 m; every face
  counter-clockwise seen from outside its own solid (its normal points out).
    building lod1Solid: 10 polygons. Each wall is written in two parts, split at z = 3,
    so that each zone can XLink exactly its own part.
      ground z=0  80 m2  |  roof z=6  80 m2
      south / north y=0 / y=8: 2 parts of 30 m2 each  |  east / west x=10 / x=0: 2 parts of 24 m2 each
    lower zone: ground + the 4 lower wall parts (XLinks) + its slab at z=3 (own polygon, up)
    upper zone: roof + the 4 upper wall parts (XLinks) + its slab at z=3 (own polygon, down)
  Each zone: envelope 268 m2, volume 240 m3 (= its stated nrg3:volume).

  ENERGY ADE CONTENT (the spec's LoD1 rules: Table 1 and Table 2, case 1.2)
    * Two ThermalZones, each with its own LoD1 solid; the exterior faces XLink the
      homologous polygons of the building's lod1Solid (spec: "XLinks can be used to
      reference the homologous polygons of the LoD1 solid").
    * No thermalBoundary and no openings: neither is allowed in LoD1.
    * coincidesWithLod2Hull / coincidesWithLod3Hull = false (mandatory in the XSD,
      not used in LoD1).
    * One averaged LayeredConstruction per zone, inline: uValue 0.5 and 0.4 W/(K*m^2).

  TEST AIM
    1. XSD gate passes (CityGML 2.0 + Energy ADE 3.0 beta7).
    2. 12 surfaces, 6 per zone, read from the zones' own solids; no polygon read twice.
    3. Exterior: ground Floor/Ground, roof Roof/Outdoors, 8 wall parts Wall/Outdoors.
       The slab: the lower zone's copy is a Ceiling, the upper zone's copy a Floor,
       both Adiabatic.
    4. Each zone's faces use that zone's construction: R = 2.0 lower, R = 2.5 upper.
    5. Two E+ Zones; ZoneInfiltration 0.3 ACH on each; no windows.
    6. EnergyPlus exit 0, 0 Severe / 0 Fatal; expected warning "This building has no
       thermal mass" (U-value-only constructions have none).
-->
<core:CityModel xmlns:core="http://www.opengis.net/citygml/2.0"
                xmlns:bldg="http://www.opengis.net/citygml/building/2.0"
                xmlns:gml="http://www.opengis.net/gml"
                xmlns:nrg3="http://www.citygml.org/ade/energy/3.0"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<gml:name>Energy ADE Case 1.2 - LoD1 two thermal zones, no boundaries, no openings</gml:name>
	<gml:boundedBy>
		<gml:Envelope srsName="EPSG:28992" srsDimension="3">
			<gml:lowerCorner>0 0 0</gml:lowerCorner>
			<gml:upperCorner>10 8 6</gml:upperCorner>
		</gml:Envelope>
	</gml:boundedBy>

	<core:cityObjectMember>
		<bldg:Building gml:id="Case12_LoD1_2zone">
			<gml:name>Case 1.2 building</gml:name>
			<bldg:function codeSpace="building_function">1000</bldg:function>
			<bldg:yearOfConstruction>1985</bldg:yearOfConstruction>
			<bldg:measuredHeight uom="m">6.0</bldg:measuredHeight>

			<!-- ===== the building's LoD1 solid: the whole block, walls split at z = 3 ===== -->
			<bldg:lod1Solid>
				<gml:Solid gml:id="Case12_solid">
					<gml:exterior>
						<gml:CompositeSurface srsName="EPSG:28992" srsDimension="3">

							<!-- ground, z = 0, outward normal -Z -->
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case12_poly_ground">
									<gml:exterior><gml:LinearRing>
										<gml:posList>0 0 0  0 8 0  10 8 0  10 0 0  0 0 0</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>

							<!-- flat roof, z = 6, outward normal +Z -->
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case12_poly_roof">
									<gml:exterior><gml:LinearRing>
										<gml:posList>0 0 6  10 0 6  10 8 6  0 8 6  0 0 6</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>

							<!-- south wall, y = 0, outward normal -Y: lower and upper part -->
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case12_poly_south_low">
									<gml:exterior><gml:LinearRing>
										<gml:posList>0 0 0  10 0 0  10 0 3  0 0 3  0 0 0</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case12_poly_south_up">
									<gml:exterior><gml:LinearRing>
										<gml:posList>0 0 3  10 0 3  10 0 6  0 0 6  0 0 3</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>

							<!-- east wall, x = 10, outward normal +X: lower and upper part -->
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case12_poly_east_low">
									<gml:exterior><gml:LinearRing>
										<gml:posList>10 0 0  10 8 0  10 8 3  10 0 3  10 0 0</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case12_poly_east_up">
									<gml:exterior><gml:LinearRing>
										<gml:posList>10 0 3  10 8 3  10 8 6  10 0 6  10 0 3</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>

							<!-- north wall, y = 8, outward normal +Y: lower and upper part -->
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case12_poly_north_low">
									<gml:exterior><gml:LinearRing>
										<gml:posList>10 8 0  0 8 0  0 8 3  10 8 3  10 8 0</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case12_poly_north_up">
									<gml:exterior><gml:LinearRing>
										<gml:posList>10 8 3  0 8 3  0 8 6  10 8 6  10 8 3</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>

							<!-- west wall, x = 0, outward normal -X: lower and upper part -->
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case12_poly_west_low">
									<gml:exterior><gml:LinearRing>
										<gml:posList>0 8 0  0 0 0  0 0 3  0 8 3  0 8 0</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case12_poly_west_up">
									<gml:exterior><gml:LinearRing>
										<gml:posList>0 8 3  0 0 3  0 0 6  0 8 6  0 8 3</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>

						</gml:CompositeSurface>
					</gml:exterior>
				</gml:Solid>
			</bldg:lod1Solid>

			<!-- ===== thermal zone 1: the lower storey, z = 0 .. 3 ===== -->
			<nrg3:thermalZone>
				<nrg3:ThermalZone gml:id="Case12_zone_lower">
					<gml:name>Case 1.2 lower thermal zone</gml:name>

					<!-- ONE averaged construction for this zone's whole hull (Table 2, case 1.2) -->
					<nrg3:layeredConstruction>
						<nrg3:LayeredConstruction gml:id="Case12_constr_lower">
							<gml:name>Averaged lower-zone construction U=0.50</gml:name>
							<nrg3:uValue uom="W/(K*m^2)">0.5</nrg3:uValue>
						</nrg3:LayeredConstruction>
					</nrg3:layeredConstruction>

					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:value uom="m^3">240</nrg3:value>
							<nrg3:type codeSpace="http://www.sig3d.org/citygml/2.0/energy/3.0/VolumeTypeValue">grossVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>

					<!-- the zone's own LoD1 solid: exterior faces are XLinks to the building's
					     polygons; the slab is this zone's own polygon -->
					<nrg3:lod1Solid>
						<gml:Solid gml:id="Case12_zone_lower_solid">
							<gml:exterior>
								<gml:CompositeSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember xlink:href="#Case12_poly_ground"/>
									<gml:surfaceMember xlink:href="#Case12_poly_south_low"/>
									<gml:surfaceMember xlink:href="#Case12_poly_east_low"/>
									<gml:surfaceMember xlink:href="#Case12_poly_north_low"/>
									<gml:surfaceMember xlink:href="#Case12_poly_west_low"/>
									<!-- the shared slab, z = 3, seen from this zone: normal +Z (up) -->
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case12_poly_slab_of_lower">
											<gml:exterior><gml:LinearRing>
												<gml:posList>0 0 3  10 0 3  10 8 3  0 8 3  0 0 3</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:CompositeSurface>
							</gml:exterior>
						</gml:Solid>
					</nrg3:lod1Solid>

					<nrg3:infiltrationRate uom="1/h">0.3</nrg3:infiltrationRate>
					<nrg3:isCooled>false</nrg3:isCooled>
					<nrg3:isHeated>true</nrg3:isHeated>
					<nrg3:coincidesWithLod2Hull>false</nrg3:coincidesWithLod2Hull>
					<nrg3:coincidesWithLod3Hull>false</nrg3:coincidesWithLod3Hull>
					<!-- NO nrg3:thermalBoundary: forbidden in LoD1. -->
				</nrg3:ThermalZone>
			</nrg3:thermalZone>

			<!-- ===== thermal zone 2: the upper storey, z = 3 .. 6 ===== -->
			<nrg3:thermalZone>
				<nrg3:ThermalZone gml:id="Case12_zone_upper">
					<gml:name>Case 1.2 upper thermal zone</gml:name>

					<nrg3:layeredConstruction>
						<nrg3:LayeredConstruction gml:id="Case12_constr_upper">
							<gml:name>Averaged upper-zone construction U=0.40</gml:name>
							<nrg3:uValue uom="W/(K*m^2)">0.4</nrg3:uValue>
						</nrg3:LayeredConstruction>
					</nrg3:layeredConstruction>

					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:value uom="m^3">240</nrg3:value>
							<nrg3:type codeSpace="http://www.sig3d.org/citygml/2.0/energy/3.0/VolumeTypeValue">grossVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>

					<nrg3:lod1Solid>
						<gml:Solid gml:id="Case12_zone_upper_solid">
							<gml:exterior>
								<gml:CompositeSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember xlink:href="#Case12_poly_roof"/>
									<gml:surfaceMember xlink:href="#Case12_poly_south_up"/>
									<gml:surfaceMember xlink:href="#Case12_poly_east_up"/>
									<gml:surfaceMember xlink:href="#Case12_poly_north_up"/>
									<gml:surfaceMember xlink:href="#Case12_poly_west_up"/>
									<!-- the shared slab, z = 3, seen from this zone: normal -Z (down) -->
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case12_poly_slab_of_upper">
											<gml:exterior><gml:LinearRing>
												<gml:posList>0 0 3  0 8 3  10 8 3  10 0 3  0 0 3</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:CompositeSurface>
							</gml:exterior>
						</gml:Solid>
					</nrg3:lod1Solid>

					<nrg3:infiltrationRate uom="1/h">0.3</nrg3:infiltrationRate>
					<nrg3:isCooled>false</nrg3:isCooled>
					<nrg3:isHeated>true</nrg3:isHeated>
					<nrg3:coincidesWithLod2Hull>false</nrg3:coincidesWithLod2Hull>
					<nrg3:coincidesWithLod3Hull>false</nrg3:coincidesWithLod3Hull>
					<!-- NO nrg3:thermalBoundary: forbidden in LoD1. -->
				</nrg3:ThermalZone>
			</nrg3:thermalZone>
		</bldg:Building>
	</core:cityObjectMember>
</core:CityModel>
