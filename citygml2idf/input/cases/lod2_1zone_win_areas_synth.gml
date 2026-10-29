<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================================
  SUPPORT SAMPLE (not a Table-2 case): LoD2, single thermal zone, windows from the
  TOTAL and OPAQUE surface AREAS.
  SYNTHETIC, self-contained (every reference resolves inside this file).
  ============================================================================

  PARSE PATH (what the reader must do with this file)
    geometry, zones and constructions : as LoD2_1Zone_window_WWR_synth.gml (same box,
                    same layers, same missing fields).
    windows       : no opening ratio here. Each wall states
                    nrg3:bdgBdrySurfTotalSurfaceArea and nrg3:bdgBdrySurfOpaqueSurfaceArea,
                    so ratio = (total - opaque) / total = 0.30 -> one centred 9.0 m2
                    window per wall with the default glazing.
    infiltration  : nrg3:infiltrationRate 0.0001 1/s = 0.36 1/h -> ZoneInfiltration
                    0.36 ACH (a unit-conversion test).

  GEOMETRY
    A 10 (x) x 10 (y) x 3 (z) box; every face counter-clockwise seen from outside.
    Every wall is 10 x 3 = 30 m2 gross. Zone volume 300 m3 (= the stated nrg3:volume).

  ENERGY ADE CONTENT
    Both areas are gml:AreaType, so any area unit is legal. The four walls state the
    same physical areas in four ways:
        south  30 m^2         / 21 m^2          same unit, same spelling
        east   30 m^2         / 21 m2           same unit, other spelling
        north  30 m^2         / 210000 cm^2     different units
        west   322.9173 ft^2  / 226.0421 ft^2   imperial
    Each area is converted to m2 BEFORE the subtraction.

  TEST AIM
    1. XSD gate passes (CityGML 2.0 + Energy ADE 3.0 beta7).
    2. All four walls give ratio 0.30 -> a 9.0 m2 window each.
    3. ZoneInfiltration 0.36 ACH (0.0001 1/s converted).
    4. EnergyPlus exit 0, 0 Severe / 0 Fatal, 0 warnings.
-->
<core:CityModel xmlns:app="http://www.opengis.net/citygml/appearance/2.0" xmlns:bldg="http://www.opengis.net/citygml/building/2.0" xmlns:brid="http://www.opengis.net/citygml/bridge/2.0" xmlns:core="http://www.opengis.net/citygml/2.0" xmlns:dem="http://www.opengis.net/citygml/relief/2.0" xmlns:frn="http://www.opengis.net/citygml/cityfurniture/2.0" xmlns:gen="http://www.opengis.net/citygml/generics/2.0" xmlns:gml="http://www.opengis.net/gml" xmlns:grp="http://www.opengis.net/citygml/cityobjectgroup/2.0" xmlns:luse="http://www.opengis.net/citygml/landuse/2.0" xmlns:nrg3="http://www.citygml.org/ade/energy/3.0" xmlns:pbase="http://www.opengis.net/citygml/profiles/base/2.0" xmlns:tex="http://www.opengis.net/citygml/texturedsurface/2.0" xmlns:tran="http://www.opengis.net/citygml/transportation/2.0" xmlns:tun="http://www.opengis.net/citygml/tunnel/2.0" xmlns:veg="http://www.opengis.net/citygml/vegetation/2.0" xmlns:wtr="http://www.opengis.net/citygml/waterbody/2.0" xmlns:xAL="urn:oasis:names:tc:ciq:xsdschema:xAL:2.0" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<gml:name>LoD2 single zone, thermal boundaries, windows from total and opaque areas</gml:name>
	<gml:boundedBy>
		<gml:Envelope srsName="EPSG:28992" srsDimension="3">
			<gml:lowerCorner>0 0 0</gml:lowerCorner>
			<gml:upperCorner>10 10 3</gml:upperCorner>
		</gml:Envelope>
	</gml:boundedBy>

	<!-- ===== shared constructions: DETAILED LAYERS (real materials -> thermal mass) =====
	     Some SolidMaterial fields are DELIBERATELY omitted to exercise per-field defaulting. -->
	<core:cityObjectMember>
		<nrg3:LayeredConstructionLibrary gml:id="CaseC_constr_library">
			<gml:name>Case construction library (layered)</gml:name>

			<!-- WALL: brick (full) + insulation (NO density) + plaster (NO specificHeat) -->
			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="CaseC_constr_wall">
					<gml:name>Wall (brick + insulation + plaster)</gml:name>
					<nrg3:libraryCode codeSpace="case22_codeSpace">wall_layered</nrg3:libraryCode>
					<nrg3:layer><nrg3:Layer gml:id="CaseC_wall_L1">
						<nrg3:thickness uom="mm">240</nrg3:thickness>
						<nrg3:material><nrg3:SolidMaterial gml:id="CaseC_mat_brick">
							<gml:name>Brick</gml:name>
							<nrg3:thermalConductivity uom="W/(K*m)">0.79</nrg3:thermalConductivity>
							<nrg3:density uom="kg/m^3">1800</nrg3:density>
							<nrg3:specificHeatCapacity uom="J/(kg*K)">1000</nrg3:specificHeatCapacity>
						</nrg3:SolidMaterial></nrg3:material>
					</nrg3:Layer></nrg3:layer>
					<nrg3:layer><nrg3:Layer gml:id="CaseC_wall_L2">
						<nrg3:thickness uom="mm">80</nrg3:thickness>
						<nrg3:material><nrg3:SolidMaterial gml:id="CaseC_mat_insulation">
							<gml:name>Insulation (no density)</gml:name>
							<nrg3:thermalConductivity uom="W/(K*m)">0.035</nrg3:thermalConductivity>
							<nrg3:specificHeatCapacity uom="J/(kg*K)">1450</nrg3:specificHeatCapacity>
						</nrg3:SolidMaterial></nrg3:material>
					</nrg3:Layer></nrg3:layer>
					<nrg3:layer><nrg3:Layer gml:id="CaseC_wall_L3">
						<nrg3:thickness uom="mm">15</nrg3:thickness>
						<nrg3:material><nrg3:SolidMaterial gml:id="CaseC_mat_plaster">
							<gml:name>Plaster (no specificHeat)</gml:name>
							<nrg3:thermalConductivity uom="W/(K*m)">0.7</nrg3:thermalConductivity>
							<nrg3:density uom="kg/m^3">1400</nrg3:density>
						</nrg3:SolidMaterial></nrg3:material>
					</nrg3:Layer></nrg3:layer>
				</nrg3:LayeredConstruction>
			</nrg3:libraryMember>

			<!-- ROOF: concrete (full) + air gap (Gas) + insulation (NO conductivity) -->
			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="CaseC_constr_roof">
					<gml:name>Roof (concrete + air gap + insulation)</gml:name>
					<nrg3:libraryCode codeSpace="case22_codeSpace">roof_layered</nrg3:libraryCode>
					<nrg3:layer><nrg3:Layer gml:id="CaseC_roof_L1">
						<nrg3:thickness uom="mm">200</nrg3:thickness>
						<nrg3:material><nrg3:SolidMaterial gml:id="CaseC_mat_concrete">
							<gml:name>Concrete</gml:name>
							<nrg3:thermalConductivity uom="W/(K*m)">2.3</nrg3:thermalConductivity>
							<nrg3:density uom="kg/m^3">2300</nrg3:density>
							<nrg3:specificHeatCapacity uom="J/(kg*K)">1000</nrg3:specificHeatCapacity>
						</nrg3:SolidMaterial></nrg3:material>
					</nrg3:Layer></nrg3:layer>
					<nrg3:layer><nrg3:Layer gml:id="CaseC_roof_L2">
						<nrg3:thickness uom="mm">30</nrg3:thickness>
						<nrg3:material><nrg3:Gas gml:id="CaseC_mat_airgap">
							<gml:name>Air gap</gml:name>
							<nrg3:isVentilated>false</nrg3:isVentilated>
							<nrg3:rValue uom="m^2*K/W">0.15</nrg3:rValue>
						</nrg3:Gas></nrg3:material>
					</nrg3:Layer></nrg3:layer>
					<nrg3:layer><nrg3:Layer gml:id="CaseC_roof_L3">
						<nrg3:thickness uom="mm">120</nrg3:thickness>
						<nrg3:material><nrg3:SolidMaterial gml:id="CaseC_mat_roofinsul">
							<gml:name>Roof insulation (no conductivity)</gml:name>
							<nrg3:density uom="kg/m^3">30</nrg3:density>
							<nrg3:specificHeatCapacity uom="J/(kg*K)">1450</nrg3:specificHeatCapacity>
						</nrg3:SolidMaterial></nrg3:material>
					</nrg3:Layer></nrg3:layer>
				</nrg3:LayeredConstruction>
			</nrg3:libraryMember>

			<!-- GROUND: concrete slab (full) -->
			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="CaseC_constr_ground">
					<gml:name>Ground (concrete slab)</gml:name>
					<nrg3:libraryCode codeSpace="case22_codeSpace">ground_layered</nrg3:libraryCode>
					<nrg3:layer><nrg3:Layer gml:id="CaseC_ground_L1">
						<nrg3:thickness uom="mm">300</nrg3:thickness>
						<nrg3:material><nrg3:SolidMaterial gml:id="CaseC_mat_slab">
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
		<bldg:Building gml:id="CaseC_LoD2_1zone_window">
			<gml:name>Case 2.2 building</gml:name>
			<nrg3:thermalZone>
				<nrg3:ThermalZone gml:id="CaseC_zone">
					<gml:name>Case 2.2 thermal zone</gml:name>
					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:value uom="m^3">300</nrg3:value>
							<nrg3:type codeSpace="http://www.sig3d.org/citygml/2.0/energy/3.0/VolumeTypeValue">grossVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>
					<!-- air leakage through the fabric; E+ ZoneInfiltration:DesignFlowRate, AirChanges/Hour -->
					<nrg3:infiltrationRate uom="1/s">0.0001</nrg3:infiltrationRate>
					<nrg3:isCooled>false</nrg3:isCooled>
					<nrg3:isHeated>true</nrg3:isHeated>
					<nrg3:coincidesWithLod2Hull>false</nrg3:coincidesWithLod2Hull>
					<nrg3:coincidesWithLod3Hull>false</nrg3:coincidesWithLod3Hull>

					<!-- floor / ground (z = 0) -->
					<nrg3:thermalBoundary>
						<bldg:GroundSurface gml:id="CaseC_ground">
							<gml:name>Ground</gml:name>
							<nrg3:layeredConstruction xlink:href="#CaseC_constr_ground"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="CaseC_poly_ground">
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
						<bldg:RoofSurface gml:id="CaseC_roof">
							<gml:name>Roof</gml:name>
							<nrg3:layeredConstruction xlink:href="#CaseC_constr_roof"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="CaseC_poly_roof">
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
						<bldg:WallSurface gml:id="CaseC_wall_south">
							<gml:name>Wall South</gml:name>
							<nrg3:layeredConstruction xlink:href="#CaseC_constr_wall"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="CaseC_poly_wall_south">
											<gml:exterior><gml:LinearRing>
												<gml:posList>0 0 0 10 0 0 10 0 3 0 0 3 0 0 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
							<!-- path C (baseline: same unit, same spelling) -->
							<nrg3:bdgBdrySurfTotalSurfaceArea uom="m^2">30</nrg3:bdgBdrySurfTotalSurfaceArea>
							<nrg3:bdgBdrySurfOpaqueSurfaceArea uom="m^2">21</nrg3:bdgBdrySurfOpaqueSurfaceArea>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

					<!-- wall east (x = 10) — WWR 0.3 -->
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="CaseC_wall_east">
							<gml:name>Wall East</gml:name>
							<nrg3:layeredConstruction xlink:href="#CaseC_constr_wall"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="CaseC_poly_wall_east">
											<gml:exterior><gml:LinearRing>
												<gml:posList>10 0 0 10 10 0 10 10 3 10 0 3 10 0 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
							<!-- path C (same unit, DIFFERENT spelling) -->
							<nrg3:bdgBdrySurfTotalSurfaceArea uom="m^2">30</nrg3:bdgBdrySurfTotalSurfaceArea>
							<nrg3:bdgBdrySurfOpaqueSurfaceArea uom="m2">21</nrg3:bdgBdrySurfOpaqueSurfaceArea>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

					<!-- wall north (y = 10) — WWR 0.3 -->
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="CaseC_wall_north">
							<gml:name>Wall North</gml:name>
							<nrg3:layeredConstruction xlink:href="#CaseC_constr_wall"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="CaseC_poly_wall_north">
											<gml:exterior><gml:LinearRing>
												<gml:posList>10 10 0 0 10 0 0 10 3 10 10 3 10 10 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
							<!-- path C (DIFFERENT area units) -->
							<nrg3:bdgBdrySurfTotalSurfaceArea uom="m^2">30</nrg3:bdgBdrySurfTotalSurfaceArea>
							<nrg3:bdgBdrySurfOpaqueSurfaceArea uom="cm^2">210000</nrg3:bdgBdrySurfOpaqueSurfaceArea>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

					<!-- wall west (x = 0) — WWR 0.3 -->
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="CaseC_wall_west">
							<gml:name>Wall West</gml:name>
							<nrg3:layeredConstruction xlink:href="#CaseC_constr_wall"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="CaseC_poly_wall_west">
											<gml:exterior><gml:LinearRing>
												<gml:posList>0 10 0 0 0 0 0 0 3 0 10 3 0 10 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
							<!-- path C (imperial, both sides) -->
							<nrg3:bdgBdrySurfTotalSurfaceArea uom="ft^2">322.9173</nrg3:bdgBdrySurfTotalSurfaceArea>
							<nrg3:bdgBdrySurfOpaqueSurfaceArea uom="ft^2">226.0421</nrg3:bdgBdrySurfOpaqueSurfaceArea>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

				</nrg3:ThermalZone>
			</nrg3:thermalZone>
		</bldg:Building>
	</core:cityObjectMember>
</core:CityModel>
