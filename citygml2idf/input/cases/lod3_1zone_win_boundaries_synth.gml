<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================================
  SUPPORT SAMPLE (not a Table-2 case): LoD3, single thermal zone, thermal
  boundaries WITH openings. Case 6.1 is the same building written with
  coincidesWithLod3Hull instead of thermal boundaries.
  SYNTHETIC, self-contained (every reference resolves inside this file).
  ============================================================================

  PARSE PATH (what the reader must do with this file)
    geometry      : the 6 nrg3:thermalBoundary surfaces (bldg:lod3MultiSurface).
    zones         : one ThermalZone owning its 6 boundaries.
    constructions : detailed layers per boundary.
    windows       : from each boundary wall's own bldg:Window objects. In LoD3 windows
                    come only from opening objects, never from a ratio (this file has
                    no ratio or area attributes).
    glazing       : the window's own LayeredConstruction: uValue -> U-Factor,
                    gValue -> SHGC, visible transmittance -> Visible Transmittance.
    infiltration  : 0.3 1/h -> ZoneInfiltration 0.3 ACH.

  GEOMETRY
  A 10 (x) x 8 (y) x 3 (z) box at the origin; every face counter-clockwise seen
  from outside (its normal points out).
    ground z=0   80 m2  |  roof  z=3   80 m2
    south  y=0   30 m2  |  north y=8   30 m2  |  east x=10  24 m2  |  west x=0  24 m2
  Total envelope 268 m2; zone volume 240 m3 (= the stated nrg3:volume).
  In LoD3 a surface carries the HOLE and the opening FILLS it: each wall with an
  opening has a gml:interior ring, and the window ring is that hole REVERSED (GML3
  winds a hole opposite to its surface, while the window is its own surface facing
  outdoors like the wall). Wall areas stay GROSS (south 30 m2, not 27).

  ENERGY ADE CONTENT
    * One ThermalZone (hull flags false) with 6 thermal boundaries, each with its own
      detailed construction.
    * The openings:
    south  bldg:Window 2.0 x 1.5 = 3.00 m2 with its own glazing construction
           (uValue 1.4, gValue 0.6, visible transmittance 0.75, solar 0.55). The
           gValue must win over the solar transmittance, so SHGC = 0.6.
    east   bldg:Window 1.2 x 1.2 = 1.44 m2 with no construction -> default glazing
           (U 2.8, SHGC 0.7, no visible transmittance: the IDD field is optional).
    north  bldg:Door: doors are not written yet, so the wall stays opaque there.
    west   no opening (control).

  TEST AIM
    1. XSD gate passes (CityGML 2.0 + Energy ADE 3.0 beta7).
    2. 6 surfaces, gross wall areas (south = 30 m2).
    3. Exactly 2 windows (3.00 and 1.44 m2), each on its correct wall, facing like it
       straight from the file (no "re-wound" warning).
    4. South glazing U 1.4 / SHGC 0.6 (gValue beats the 0.55 solar band) / VT 0.75;
       east = the default glazing, VT omitted.
    5. EnergyPlus exit 0, 0 Severe / 0 Fatal, 0 warnings. A window outside its wall
       would give the warning "Base surface does not surround subsurface".
-->
<core:CityModel xmlns:core="http://www.opengis.net/citygml/2.0"
                xmlns:bldg="http://www.opengis.net/citygml/building/2.0"
                xmlns:gml="http://www.opengis.net/gml"
                xmlns:nrg3="http://www.citygml.org/ade/energy/3.0"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<gml:name>LoD3 single zone, thermal boundaries with explicit window/door openings</gml:name>
	<gml:boundedBy>
		<gml:Envelope srsName="EPSG:28992" srsDimension="3">
			<gml:lowerCorner>0 0 0</gml:lowerCorner>
			<gml:upperCorner>10 8 3</gml:upperCorner>
		</gml:Envelope>
	</gml:boundedBy>

	<core:cityObjectMember>
		<nrg3:LayeredConstructionLibrary gml:id="L3_constr_library">
			<gml:name>LoD3 construction library</gml:name>

			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="L3_constr_wall">
					<gml:name>Exterior wall</gml:name>
					<nrg3:layer>
						<nrg3:Layer gml:id="L3_layer_wall_plaster">
							<nrg3:thickness uom="m">0.015</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="L3_mat_plaster">
									<gml:name>Gypsum plaster</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">0.60</nrg3:thermalConductivity>
									<nrg3:density uom="kg/m^3">1300</nrg3:density>
									<nrg3:specificHeatCapacity uom="J/(kg*K)">900</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="L3_layer_wall_insulation">
							<nrg3:thickness uom="m">0.12</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="L3_mat_insulation">
									<gml:name>Mineral wool</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">0.035</nrg3:thermalConductivity>
									<nrg3:density uom="kg/m^3">30</nrg3:density>
									<nrg3:specificHeatCapacity uom="J/(kg*K)">1030</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="L3_layer_wall_brick">
							<nrg3:thickness uom="m">0.20</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="L3_mat_brick">
									<gml:name>Brick</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">0.90</nrg3:thermalConductivity>
									<nrg3:density uom="kg/m^3">1800</nrg3:density>
									<nrg3:specificHeatCapacity uom="J/(kg*K)">900</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
				</nrg3:LayeredConstruction>
			</nrg3:libraryMember>

			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="L3_constr_roof">
					<gml:name>Flat roof</gml:name>
					<nrg3:layer>
						<nrg3:Layer gml:id="L3_layer_roof_board">
							<nrg3:thickness uom="m">0.02</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="L3_mat_board">
									<gml:name>Plasterboard</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">0.25</nrg3:thermalConductivity>
									<nrg3:density uom="kg/m^3">900</nrg3:density>
									<nrg3:specificHeatCapacity uom="J/(kg*K)">1000</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="L3_layer_roof_insulation">
							<nrg3:thickness uom="m">0.20</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="L3_mat_roof_insulation">
									<gml:name>Roof insulation</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">0.04</nrg3:thermalConductivity>
									<nrg3:density uom="kg/m^3">35</nrg3:density>
									<nrg3:specificHeatCapacity uom="J/(kg*K)">1030</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
				</nrg3:LayeredConstruction>
			</nrg3:libraryMember>

			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="L3_constr_ground">
					<gml:name>Ground floor</gml:name>
					<nrg3:layer>
						<nrg3:Layer gml:id="L3_layer_ground_screed">
							<nrg3:thickness uom="m">0.06</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="L3_mat_screed">
									<gml:name>Cement screed</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">1.40</nrg3:thermalConductivity>
									<nrg3:density uom="kg/m^3">2000</nrg3:density>
									<nrg3:specificHeatCapacity uom="J/(kg*K)">1000</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="L3_layer_ground_concrete">
							<nrg3:thickness uom="m">0.25</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="L3_mat_concrete">
									<gml:name>Reinforced concrete</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">1.80</nrg3:thermalConductivity>
									<nrg3:density uom="kg/m^3">2300</nrg3:density>
									<nrg3:specificHeatCapacity uom="J/(kg*K)">1000</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
				</nrg3:LayeredConstruction>
			</nrg3:libraryMember>

			<!-- GLAZING. gValue AND a solar transmittance are both present on purpose:
			     the SHGC waterfall is gValue FIRST, so SHGC must be 0.6, never 0.55. -->
			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="L3_constr_glazing">
					<gml:name>Double glazing, low-e</gml:name>
					<nrg3:uValue uom="W/(K*m^2)">1.4</nrg3:uValue>
					<nrg3:gValue uom="unit interval">0.6</nrg3:gValue>
					<nrg3:transmittance>
						<nrg3:Transmittance>
							<nrg3:fraction uom="unit interval">0.55</nrg3:fraction>
							<nrg3:wavelengthRange>solar</nrg3:wavelengthRange>
						</nrg3:Transmittance>
					</nrg3:transmittance>
					<nrg3:transmittance>
						<nrg3:Transmittance>
							<nrg3:fraction uom="unit interval">0.75</nrg3:fraction>
							<nrg3:wavelengthRange>visible</nrg3:wavelengthRange>
						</nrg3:Transmittance>
					</nrg3:transmittance>
				</nrg3:LayeredConstruction>
			</nrg3:libraryMember>
		</nrg3:LayeredConstructionLibrary>
	</core:cityObjectMember>

	<core:cityObjectMember>
		<bldg:Building gml:id="L3_1zone_win">
			<gml:name>LoD3 building with openings</gml:name>
			<bldg:function codeSpace="building_function">1000</bldg:function>
			<bldg:yearOfConstruction>1985</bldg:yearOfConstruction>
			<bldg:measuredHeight uom="m">3.0</bldg:measuredHeight>

			<nrg3:thermalZone>
				<nrg3:ThermalZone gml:id="L3_zone">
					<gml:name>LoD3 thermal zone</gml:name>

					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:value uom="m^3">240</nrg3:value>
							<nrg3:type codeSpace="http://www.sig3d.org/citygml/2.0/energy/3.0/VolumeTypeValue">grossVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>

					<!-- air leakage through the fabric; E+ ZoneInfiltration:DesignFlowRate, AirChanges/Hour -->
					<nrg3:infiltrationRate uom="ach">0.3</nrg3:infiltrationRate>
					<nrg3:isCooled>false</nrg3:isCooled>
					<nrg3:isHeated>true</nrg3:isHeated>
					<nrg3:coincidesWithLod2Hull>false</nrg3:coincidesWithLod2Hull>
					<nrg3:coincidesWithLod3Hull>false</nrg3:coincidesWithLod3Hull>

					<!-- ground z=0, no opening -->
					<nrg3:thermalBoundary>
						<bldg:GroundSurface gml:id="L3_tb_ground">
							<gml:name>Ground</gml:name>
							<nrg3:layeredConstruction xlink:href="#L3_constr_ground"/>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="L3_poly_ground">
											<gml:exterior><gml:LinearRing>
												<gml:posList>0 0 0  0 8 0  10 8 0  10 0 0  0 0 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
						</bldg:GroundSurface>
					</nrg3:thermalBoundary>

					<!-- roof z=3, no opening -->
					<nrg3:thermalBoundary>
						<bldg:RoofSurface gml:id="L3_tb_roof">
							<gml:name>Roof</gml:name>
							<nrg3:layeredConstruction xlink:href="#L3_constr_roof"/>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="L3_poly_roof">
											<gml:exterior><gml:LinearRing>
												<gml:posList>0 0 3  10 0 3  10 8 3  0 8 3  0 0 3</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
						</bldg:RoofSurface>
					</nrg3:thermalBoundary>

					<!-- SOUTH wall y=0, outward -Y. HOLE + window (correct winding). -->
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="L3_tb_wall_south">
							<gml:name>Wall south (window, correctly wound)</gml:name>
							<nrg3:layeredConstruction xlink:href="#L3_constr_wall"/>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="L3_poly_wall_south">
											<gml:exterior><gml:LinearRing>
												<gml:posList>0 0 0  10 0 0  10 0 3  0 0 3  0 0 0</gml:posList>
											</gml:LinearRing></gml:exterior>
											<gml:interior><gml:LinearRing>
												<gml:posList>4 0 1  4 0 2.5  6 0 2.5  6 0 1  4 0 1</gml:posList>
											</gml:LinearRing></gml:interior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
							<bldg:opening>
								<bldg:Window gml:id="L3_win_south">
									<gml:name>South window 2.0 x 1.5</gml:name>
									<nrg3:layeredConstruction xlink:href="#L3_constr_glazing"/>
									<bldg:lod3MultiSurface>
										<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
											<gml:surfaceMember>
												<gml:Polygon gml:id="L3_poly_win_south">
													<gml:exterior><gml:LinearRing>
														<gml:posList>4 0 1  6 0 1  6 0 2.5  4 0 2.5  4 0 1</gml:posList>
													</gml:LinearRing></gml:exterior>
												</gml:Polygon>
											</gml:surfaceMember>
										</gml:MultiSurface>
									</bldg:lod3MultiSurface>
								</bldg:Window>
							</bldg:opening>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

					<!-- EAST wall x=10, outward +X. HOLE + window WOUND BACKWARDS on purpose,
					     and with NO construction (so it must use DEFAULT_WINDOW). -->
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="L3_tb_wall_east">
							<gml:name>Wall east (window wound BACKWARDS, no glazing construction)</gml:name>
							<nrg3:layeredConstruction xlink:href="#L3_constr_wall"/>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="L3_poly_wall_east">
											<gml:exterior><gml:LinearRing>
												<gml:posList>10 0 0  10 8 0  10 8 3  10 0 3  10 0 0</gml:posList>
											</gml:LinearRing></gml:exterior>
											<gml:interior><gml:LinearRing>
												<gml:posList>10 3.4 0.9  10 3.4 2.1  10 4.6 2.1  10 4.6 0.9  10 3.4 0.9</gml:posList>
											</gml:LinearRing></gml:interior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
							<bldg:opening>
								<bldg:Window gml:id="L3_win_east">
									<gml:name>East window 1.2 x 1.2</gml:name>
									<bldg:lod3MultiSurface>
										<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
											<gml:surfaceMember>
												<gml:Polygon gml:id="L3_poly_win_east">
													<gml:exterior><gml:LinearRing>
														<gml:posList>10 3.4 0.9  10 4.6 0.9  10 4.6 2.1  10 3.4 2.1  10 3.4 0.9</gml:posList>
													</gml:LinearRing></gml:exterior>
												</gml:Polygon>
											</gml:surfaceMember>
										</gml:MultiSurface>
									</bldg:lod3MultiSurface>
								</bldg:Window>
							</bldg:opening>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

					<!-- NORTH wall y=8, outward +Y. HOLE + a DOOR: must be SKIPPED. -->
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="L3_tb_wall_north">
							<gml:name>Wall north (door, must be skipped)</gml:name>
							<nrg3:layeredConstruction xlink:href="#L3_constr_wall"/>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="L3_poly_wall_north">
											<gml:exterior><gml:LinearRing>
												<gml:posList>10 8 0  0 8 0  0 8 3  10 8 3  10 8 0</gml:posList>
											</gml:LinearRing></gml:exterior>
											<gml:interior><gml:LinearRing>
												<gml:posList>4 8 0  5 8 0  5 8 2.1  4 8 2.1  4 8 0</gml:posList>
											</gml:LinearRing></gml:interior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
							<bldg:opening>
								<bldg:Door gml:id="L3_door_north">
									<gml:name>North door 1.0 x 2.1</gml:name>
									<bldg:lod3MultiSurface>
										<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
											<gml:surfaceMember>
												<gml:Polygon gml:id="L3_poly_door_north">
													<gml:exterior><gml:LinearRing>
														<gml:posList>5 8 0  4 8 0  4 8 2.1  5 8 2.1  5 8 0</gml:posList>
													</gml:LinearRing></gml:exterior>
												</gml:Polygon>
											</gml:surfaceMember>
										</gml:MultiSurface>
									</bldg:lod3MultiSurface>
								</bldg:Door>
							</bldg:opening>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

					<!-- WEST wall x=0, outward -X. No opening (control). -->
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="L3_tb_wall_west">
							<gml:name>Wall west (no opening)</gml:name>
							<nrg3:layeredConstruction xlink:href="#L3_constr_wall"/>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="L3_poly_wall_west">
											<gml:exterior><gml:LinearRing>
												<gml:posList>0 8 0  0 0 0  0 0 3  0 8 3  0 8 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

				</nrg3:ThermalZone>
			</nrg3:thermalZone>
		</bldg:Building>
	</core:cityObjectMember>
</core:CityModel>
