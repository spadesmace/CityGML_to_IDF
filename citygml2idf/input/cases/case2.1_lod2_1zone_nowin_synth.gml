<?xml version="1.0" encoding="UTF-8"?>
<!--
  Energy ADE Table-2 CASE 2.1 — Single LoD2 thermal zone, NO windows, thermal boundaries.
  Self-contained: one building, one nrg3:ThermalZone, six nrg3:thermalBoundary surfaces
  (4 walls + roof + ground) of a simple 10 x 10 x 3 m box. Constructions are shared
  LayeredConstruction members referenced by WITHIN-FILE xlink (like Alderaan); each carries
  only a uValue (Tier-2 -> Material:NoMass, R = 1/U). No openings. coincidesWithLodXHull = false
  so the parser uses the thermalBoundary path (not the hull path).
-->
<core:CityModel xmlns:app="http://www.opengis.net/citygml/appearance/2.0" xmlns:bldg="http://www.opengis.net/citygml/building/2.0" xmlns:brid="http://www.opengis.net/citygml/bridge/2.0" xmlns:core="http://www.opengis.net/citygml/2.0" xmlns:dem="http://www.opengis.net/citygml/relief/2.0" xmlns:frn="http://www.opengis.net/citygml/cityfurniture/2.0" xmlns:gen="http://www.opengis.net/citygml/generics/2.0" xmlns:gml="http://www.opengis.net/gml" xmlns:grp="http://www.opengis.net/citygml/cityobjectgroup/2.0" xmlns:luse="http://www.opengis.net/citygml/landuse/2.0" xmlns:nrg3="http://www.citygml.org/ade/energy/3.0" xmlns:pbase="http://www.opengis.net/citygml/profiles/base/2.0" xmlns:tex="http://www.opengis.net/citygml/texturedsurface/2.0" xmlns:tran="http://www.opengis.net/citygml/transportation/2.0" xmlns:tun="http://www.opengis.net/citygml/tunnel/2.0" xmlns:veg="http://www.opengis.net/citygml/vegetation/2.0" xmlns:wtr="http://www.opengis.net/citygml/waterbody/2.0" xmlns:xAL="urn:oasis:names:tc:ciq:xsdschema:xAL:2.0" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<gml:name>Energy ADE Case 2.1 - LoD2 single zone, thermal boundaries, no windows</gml:name>
	<gml:boundedBy>
		<gml:Envelope srsName="EPSG:28992" srsDimension="3">
			<gml:lowerCorner>0 0 0</gml:lowerCorner>
			<gml:upperCorner>10 10 3</gml:upperCorner>
		</gml:Envelope>
	</gml:boundedBy>

	<!-- ===== shared constructions (referenced by within-file xlink) ===== -->
	<core:cityObjectMember>
		<nrg3:LayeredConstructionLibrary gml:id="Case21_constr_library">
			<gml:name>Case 2.1 construction library</gml:name>
			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="Case21_constr_wall">
					<gml:name>Wall U=0.30</gml:name>
					<nrg3:libraryCode codeSpace="case21_codeSpace">wall_u030</nrg3:libraryCode>
					<nrg3:uValue uom="W/(K*m^2)">0.3</nrg3:uValue>
				</nrg3:LayeredConstruction>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="Case21_constr_roof">
					<gml:name>Roof U=0.20</gml:name>
					<nrg3:libraryCode codeSpace="case21_codeSpace">roof_u020</nrg3:libraryCode>
					<nrg3:uValue uom="W/(K*m^2)">0.2</nrg3:uValue>
				</nrg3:LayeredConstruction>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="Case21_constr_ground">
					<gml:name>Ground U=0.40</gml:name>
					<nrg3:libraryCode codeSpace="case21_codeSpace">ground_u040</nrg3:libraryCode>
					<nrg3:uValue uom="W/(K*m^2)">0.4</nrg3:uValue>
				</nrg3:LayeredConstruction>
			</nrg3:libraryMember>
		</nrg3:LayeredConstructionLibrary>
	</core:cityObjectMember>

	<!-- ===== the building: one thermal zone, six thermal boundaries ===== -->
	<core:cityObjectMember>
		<bldg:Building gml:id="Case21_LoD2_1zone">
			<gml:name>Case 2.1 building</gml:name>
			<nrg3:thermalZone>
				<nrg3:ThermalZone gml:id="Case21_zone">
					<gml:name>Case 2.1 thermal zone</gml:name>
					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:value uom="m^3">300</nrg3:value>
							<nrg3:type codeSpace="volume_codeSpace">grossVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>
					<nrg3:isCooled>false</nrg3:isCooled>
					<nrg3:isHeated>true</nrg3:isHeated>
					<nrg3:coincidesWithLod2Hull>false</nrg3:coincidesWithLod2Hull>
					<nrg3:coincidesWithLod3Hull>false</nrg3:coincidesWithLod3Hull>

					<!-- floor / ground (z = 0) -->
					<nrg3:thermalBoundary>
						<bldg:GroundSurface gml:id="Case21_ground">
							<gml:name>Ground</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case21_constr_ground"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case21_poly_ground">
											<gml:exterior><gml:LinearRing>
												<gml:posList>0 0 0 10 0 0 10 10 0 0 10 0 0 0 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
						</bldg:GroundSurface>
					</nrg3:thermalBoundary>

					<!-- flat roof (z = 3) -->
					<nrg3:thermalBoundary>
						<bldg:RoofSurface gml:id="Case21_roof">
							<gml:name>Roof</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case21_constr_roof"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case21_poly_roof">
											<gml:exterior><gml:LinearRing>
												<gml:posList>0 0 3 10 0 3 10 10 3 0 10 3 0 0 3</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
						</bldg:RoofSurface>
					</nrg3:thermalBoundary>

					<!-- wall south (y = 0) -->
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="Case21_wall_south">
							<gml:name>Wall South</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case21_constr_wall"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case21_poly_wall_south">
											<gml:exterior><gml:LinearRing>
												<gml:posList>0 0 0 10 0 0 10 0 3 0 0 3 0 0 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

					<!-- wall east (x = 10) -->
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="Case21_wall_east">
							<gml:name>Wall East</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case21_constr_wall"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case21_poly_wall_east">
											<gml:exterior><gml:LinearRing>
												<gml:posList>10 0 0 10 10 0 10 10 3 10 0 3 10 0 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

					<!-- wall north (y = 10) -->
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="Case21_wall_north">
							<gml:name>Wall North</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case21_constr_wall"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case21_poly_wall_north">
											<gml:exterior><gml:LinearRing>
												<gml:posList>10 10 0 0 10 0 0 10 3 10 10 3 10 10 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

					<!-- wall west (x = 0) -->
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="Case21_wall_west">
							<gml:name>Wall West</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case21_constr_wall"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case21_poly_wall_west">
											<gml:exterior><gml:LinearRing>
												<gml:posList>0 10 0 0 0 0 0 0 3 0 10 3 0 10 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

				</nrg3:ThermalZone>
			</nrg3:thermalZone>
		</bldg:Building>
	</core:cityObjectMember>
</core:CityModel>
