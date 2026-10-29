<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================================
  SUPPORT SAMPLE (not a Table-2 case): LoD2, single thermal zone, windows from the
  OPENING RATIO, detailed-layer constructions with missing fields.
  SYNTHETIC, self-contained (every reference resolves inside this file).
  ============================================================================

  PARSE PATH (what the reader must do with this file)
    geometry      : the 6 nrg3:thermalBoundary surfaces (there is no thematic shell).
    zones         : one ThermalZone owning its 6 boundaries.
    constructions : detailed layers (SolidMaterial + one Gas air gap). Three fields are
                    missing on purpose and get the default; every given value is kept.
    windows       : each wall states nrg3:bdgBdrySurfOpeningToSurfaceRatio 0.3, so each
                    gets ONE centred window of 0.3 x 30 = 9.0 m2 (the wall shrunk about
                    its centre) with the default glazing (U 2.8, SHGC 0.7). LoD2 has no
                    opening objects, so the ratio is the window source.
    infiltration  : nrg3:infiltrationRate 0.3 1/h -> ZoneInfiltration 0.3 ACH.

  GEOMETRY
    A 10 (x) x 10 (y) x 3 (z) box; every face counter-clockwise seen from outside.
      ground 100 m2  |  roof 100 m2  |  4 walls of 10 x 3 = 30 m2
    Zone volume 300 m3 (= the stated nrg3:volume).

  ENERGY ADE CONTENT
    * One ThermalZone (hull flags false, optional zone lod2Solid) with 6 thermal
      boundaries, each XLinking its construction.
    * nrg3:bdgBdrySurfOpeningToSurfaceRatio 0.3 (uom "unit interval") on every wall.
    * Missing fields, each in a different material so they cannot hide each other:
        wall insulation : no density
        wall plaster    : no specificHeatCapacity
        roof insulation : no thermalConductivity
    * Roof air gap: nrg3:Gas with rValue 0.15 m^2*K/W.

  TEST AIM
    1. XSD gate passes (CityGML 2.0 + Energy ADE 3.0 beta7).
    2. 6 surfaces; 4 windows of 9.0 m2, one per wall, centred and facing like the wall.
    3. The given material values are kept; only the 3 missing fields are defaulted.
    4. ZoneInfiltration 0.3 ACH, taken from the file.
    5. EnergyPlus exit 0, 0 Severe / 0 Fatal, 0 warnings.
-->
<core:CityModel xmlns:app="http://www.opengis.net/citygml/appearance/2.0" xmlns:bldg="http://www.opengis.net/citygml/building/2.0" xmlns:brid="http://www.opengis.net/citygml/bridge/2.0" xmlns:core="http://www.opengis.net/citygml/2.0" xmlns:dem="http://www.opengis.net/citygml/relief/2.0" xmlns:frn="http://www.opengis.net/citygml/cityfurniture/2.0" xmlns:gen="http://www.opengis.net/citygml/generics/2.0" xmlns:gml="http://www.opengis.net/gml" xmlns:grp="http://www.opengis.net/citygml/cityobjectgroup/2.0" xmlns:luse="http://www.opengis.net/citygml/landuse/2.0" xmlns:nrg3="http://www.citygml.org/ade/energy/3.0" xmlns:pbase="http://www.opengis.net/citygml/profiles/base/2.0" xmlns:tex="http://www.opengis.net/citygml/texturedsurface/2.0" xmlns:tran="http://www.opengis.net/citygml/transportation/2.0" xmlns:tun="http://www.opengis.net/citygml/tunnel/2.0" xmlns:veg="http://www.opengis.net/citygml/vegetation/2.0" xmlns:wtr="http://www.opengis.net/citygml/waterbody/2.0" xmlns:xAL="urn:oasis:names:tc:ciq:xsdschema:xAL:2.0" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<gml:name>LoD2 single zone, thermal boundaries, windows from the opening ratio</gml:name>
	<gml:boundedBy>
		<gml:Envelope srsName="EPSG:28992" srsDimension="3">
			<gml:lowerCorner>0 0 0</gml:lowerCorner>
			<gml:upperCorner>10 10 3</gml:upperCorner>
		</gml:Envelope>
	</gml:boundedBy>

	<!-- ===== shared constructions: DETAILED LAYERS (real materials -> thermal mass) =====
	     Some SolidMaterial fields are DELIBERATELY omitted to exercise per-field defaulting. -->
	<core:cityObjectMember>
		<nrg3:LayeredConstructionLibrary gml:id="Case22_constr_library">
			<gml:name>Case construction library (layered)</gml:name>

			<!-- WALL: brick (full) + insulation (NO density) + plaster (NO specificHeat) -->
			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="Case22_constr_wall">
					<gml:name>Wall (brick + insulation + plaster)</gml:name>
					<nrg3:libraryCode codeSpace="case22_codeSpace">wall_layered</nrg3:libraryCode>
					<nrg3:layer><nrg3:Layer gml:id="Case22_wall_L1">
						<nrg3:thickness uom="mm">240</nrg3:thickness>
						<nrg3:material><nrg3:SolidMaterial gml:id="Case22_mat_brick">
							<gml:name>Brick</gml:name>
							<nrg3:thermalConductivity uom="W/(K*m)">0.79</nrg3:thermalConductivity>
							<nrg3:density uom="kg/m^3">1800</nrg3:density>
							<nrg3:specificHeatCapacity uom="J/(kg*K)">1000</nrg3:specificHeatCapacity>
						</nrg3:SolidMaterial></nrg3:material>
					</nrg3:Layer></nrg3:layer>
					<nrg3:layer><nrg3:Layer gml:id="Case22_wall_L2">
						<nrg3:thickness uom="mm">80</nrg3:thickness>
						<nrg3:material><nrg3:SolidMaterial gml:id="Case22_mat_insulation">
							<gml:name>Insulation (no density)</gml:name>
							<nrg3:thermalConductivity uom="W/(K*m)">0.035</nrg3:thermalConductivity>
							<nrg3:specificHeatCapacity uom="J/(kg*K)">1450</nrg3:specificHeatCapacity>
						</nrg3:SolidMaterial></nrg3:material>
					</nrg3:Layer></nrg3:layer>
					<nrg3:layer><nrg3:Layer gml:id="Case22_wall_L3">
						<nrg3:thickness uom="mm">15</nrg3:thickness>
						<nrg3:material><nrg3:SolidMaterial gml:id="Case22_mat_plaster">
							<gml:name>Plaster (no specificHeat)</gml:name>
							<nrg3:thermalConductivity uom="W/(K*m)">0.7</nrg3:thermalConductivity>
							<nrg3:density uom="kg/m^3">1400</nrg3:density>
						</nrg3:SolidMaterial></nrg3:material>
					</nrg3:Layer></nrg3:layer>
				</nrg3:LayeredConstruction>
			</nrg3:libraryMember>

			<!-- ROOF: concrete (full) + air gap (Gas) + insulation (NO conductivity) -->
			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="Case22_constr_roof">
					<gml:name>Roof (concrete + air gap + insulation)</gml:name>
					<nrg3:libraryCode codeSpace="case22_codeSpace">roof_layered</nrg3:libraryCode>
					<nrg3:layer><nrg3:Layer gml:id="Case22_roof_L1">
						<nrg3:thickness uom="mm">200</nrg3:thickness>
						<nrg3:material><nrg3:SolidMaterial gml:id="Case22_mat_concrete">
							<gml:name>Concrete</gml:name>
							<nrg3:thermalConductivity uom="W/(K*m)">2.3</nrg3:thermalConductivity>
							<nrg3:density uom="kg/m^3">2300</nrg3:density>
							<nrg3:specificHeatCapacity uom="J/(kg*K)">1000</nrg3:specificHeatCapacity>
						</nrg3:SolidMaterial></nrg3:material>
					</nrg3:Layer></nrg3:layer>
					<nrg3:layer><nrg3:Layer gml:id="Case22_roof_L2">
						<nrg3:thickness uom="mm">30</nrg3:thickness>
						<nrg3:material><nrg3:Gas gml:id="Case22_mat_airgap">
							<gml:name>Air gap</gml:name>
							<nrg3:isVentilated>false</nrg3:isVentilated>
							<nrg3:rValue uom="m^2*K/W">0.15</nrg3:rValue>
						</nrg3:Gas></nrg3:material>
					</nrg3:Layer></nrg3:layer>
					<nrg3:layer><nrg3:Layer gml:id="Case22_roof_L3">
						<nrg3:thickness uom="mm">120</nrg3:thickness>
						<nrg3:material><nrg3:SolidMaterial gml:id="Case22_mat_roofinsul">
							<gml:name>Roof insulation (no conductivity)</gml:name>
							<nrg3:density uom="kg/m^3">30</nrg3:density>
							<nrg3:specificHeatCapacity uom="J/(kg*K)">1450</nrg3:specificHeatCapacity>
						</nrg3:SolidMaterial></nrg3:material>
					</nrg3:Layer></nrg3:layer>
				</nrg3:LayeredConstruction>
			</nrg3:libraryMember>

			<!-- GROUND: concrete slab (full) -->
			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="Case22_constr_ground">
					<gml:name>Ground (concrete slab)</gml:name>
					<nrg3:libraryCode codeSpace="case22_codeSpace">ground_layered</nrg3:libraryCode>
					<nrg3:layer><nrg3:Layer gml:id="Case22_ground_L1">
						<nrg3:thickness uom="mm">300</nrg3:thickness>
						<nrg3:material><nrg3:SolidMaterial gml:id="Case22_mat_slab">
							<gml:name>Concrete slab</gml:name>
							<nrg3:thermalConductivity uom="W/(K*m)">2.3</nrg3:thermalConductivity>
							<nrg3:density uom="kg/m^3">2300</nrg3:density>
							<nrg3:specificHeatCapacity uom="J/(kg*K)">1000</nrg3:specificHeatCapacity>
						</nrg3:SolidMaterial></nrg3:material>
					</nrg3:Layer></nrg3:layer>
				</nrg3:LayeredConstruction>
			</nrg3:libraryMember>

		</nrg3:LayeredConstructionLibrary>
	</core:cityObjectMember>

	<!-- ===== the building: one thermal zone, six thermal boundaries ===== -->
	<core:cityObjectMember>
		<bldg:Building gml:id="Case22_LoD2_1zone_window">
			<gml:name>Case 2.2 building</gml:name>
			<nrg3:thermalZone>
				<nrg3:ThermalZone gml:id="Case22_zone">
					<gml:name>Case 2.2 thermal zone</gml:name>
					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:value uom="m^3">300</nrg3:value>
							<nrg3:type codeSpace="http://www.sig3d.org/citygml/2.0/energy/3.0/VolumeTypeValue">grossVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>
					<nrg3:infiltrationRate uom="1/h">0.3</nrg3:infiltrationRate>
					<nrg3:isCooled>false</nrg3:isCooled>
					<nrg3:isHeated>true</nrg3:isHeated>
					<nrg3:coincidesWithLod2Hull>false</nrg3:coincidesWithLod2Hull>
					<nrg3:coincidesWithLod3Hull>false</nrg3:coincidesWithLod3Hull>

					<!-- floor / ground (z = 0) -->
					<nrg3:thermalBoundary>
						<bldg:GroundSurface gml:id="Case22_ground">
							<gml:name>Ground</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case22_constr_ground"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case22_poly_ground">
											<gml:exterior><gml:LinearRing>
												<gml:posList>0 0 0 0 10 0 10 10 0 10 0 0 0 0 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
						</bldg:GroundSurface>
					</nrg3:thermalBoundary>

					<!-- flat roof (z = 3) -->
					<nrg3:thermalBoundary>
						<bldg:RoofSurface gml:id="Case22_roof">
							<gml:name>Roof</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case22_constr_roof"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case22_poly_roof">
											<gml:exterior><gml:LinearRing>
												<gml:posList>0 0 3 10 0 3 10 10 3 0 10 3 0 0 3</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
						</bldg:RoofSurface>
					</nrg3:thermalBoundary>

					<!-- wall south (y = 0) — WWR 0.3 -> synthesized window -->
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="Case22_wall_south">
							<gml:name>Wall South</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case22_constr_wall"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case22_poly_wall_south">
											<gml:exterior><gml:LinearRing>
												<gml:posList>0 0 0 10 0 0 10 0 3 0 0 3 0 0 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
							<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0.3</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

					<!-- wall east (x = 10) — WWR 0.3 -->
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="Case22_wall_east">
							<gml:name>Wall East</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case22_constr_wall"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case22_poly_wall_east">
											<gml:exterior><gml:LinearRing>
												<gml:posList>10 0 0 10 10 0 10 10 3 10 0 3 10 0 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
							<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0.3</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

					<!-- wall north (y = 10) — WWR 0.3 -->
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="Case22_wall_north">
							<gml:name>Wall North</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case22_constr_wall"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case22_poly_wall_north">
											<gml:exterior><gml:LinearRing>
												<gml:posList>10 10 0 0 10 0 0 10 3 10 10 3 10 10 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
							<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0.3</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

					<!-- wall west (x = 0) — WWR 0.3 -->
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="Case22_wall_west">
							<gml:name>Wall West</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case22_constr_wall"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case22_poly_wall_west">
											<gml:exterior><gml:LinearRing>
												<gml:posList>0 10 0 0 0 0 0 0 3 0 10 3 0 10 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
							<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0.3</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

				</nrg3:ThermalZone>
			</nrg3:thermalZone>
		</bldg:Building>
	</core:cityObjectMember>
</core:CityModel>
