<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================================
  Energy ADE 3.0 - LoD3, SINGLE thermal zone, thermal boundaries WITH openings
  (the LoD3 analogue of case 2.1; case 6.1 is the coincidesWithLod3Hull variant)
  SYNTHETIC, self-contained (every reference resolves inside this file).
  ============================================================================

  PARSE PATH (the PREDICTION this sample tests)
    geometry  : SurfacePath.ENERGY_ADE_BOUNDARIES  (6 thermal boundaries)
    physics   : per-surface nrg3:layeredConstruction -> TIER 1 detailed layers.
    openings  : LoD3 EXPLICIT geometry. openings.py branch A:
                wall -> bldg:opening -> bldg:Window -> bldg:lod3MultiSurface.
                NOT the LoD2 ratio branches (no bdgBdrySurf* ratio/area here).
    glazing   : each window's OWN nrg3:layeredConstruction -> uValue -> U-Factor,
                gValue -> SHGC, visible transmittance -> Visible Transmittance,
                emitted as E+ WindowMaterial:SimpleGlazingSystem.
    zoning    : one nrg3:ThermalZone owning all 6 boundaries.

  GEOMETRY - the usual 10 (x) x 8 (y) x 3 (z) box. Faces CCW seen from OUTSIDE.
    ground z=0  80 m2 | roof z=3  80 m2
    south  y=0  30 m2 | north y=8  30 m2 | east x=10  24 m2 | west x=0  24 m2

    In LoD3 the spec REQUIRES the thematic surface to carry the HOLE and the
    opening geometry to FILL it. So the walls that have an opening carry a
    gml:interior ring, and the bldg:Window/bldg:Door polygon matches it exactly.

    WALL AREAS STAY GROSS. read_pos_list takes the EXTERIOR ring only, so a wall
    with a hole still measures its full area (south = 30 m2, not 27 m2). That is
    what EnergyPlus wants: the base surface is the whole wall and E+ subtracts the
    fenestration itself. This sample is the FIRST test of a polygon with a hole.

  THE OPENINGS
    south  window 2.0 x 1.5 = 3.00 m2, x 4..6, z 1..2.5
           HAS its own glazing construction (uValue 1.4, gValue 0.6,
           visible transmittance 0.75, solar transmittance 0.55).
           The solar band is present ON PURPOSE: gValue must WIN over it
           (the SHGC waterfall is gValue -> solar transmittance -> default),
           so the IDF must show SHGC = 0.6, never 0.55.
           WOUND CORRECTLY: its normal agrees with the wall's (-Y).
    east   window 1.2 x 1.2 = 1.44 m2, y 3.4..4.6, z 0.9..2.1
           NO construction -> must fall back to DEFAULT_WINDOW (U 2.8, SHGC 0.7,
           visible transmittance OMITTED - IDD N3 is optional).
           *** WOUND BACKWARDS ON PURPOSE ***  Its vertices run the other way, so
           its normal points -X (INTO the room) while its wall points +X (outdoors).
           WHY: walls are re-oriented outward by rings.orient_outward, but
           openings.explicit_windows takes the window ring EXACTLY AS WRITTEN. The
           writer declares GlobalGeometryRules Vertex_Entry_Direction =
           Counterclockwise ("surfaces are specified as viewed from OUTSIDE the
           surface" - IDD), so a backwards window BREAKS that promise. Nothing in
           the CityGML schema forces a winding, so a real file may do this.
           This sample MEASURES what EnergyPlus does about it, and then proves the
           fix: a window must face the same way as the wall it sits in.
    north  a bldg:DOOR (1.0 x 2.1). Doors are SKIPPED -> the hole stays opaque
           wall, and NO fenestration is emitted for it.
    west   no opening (control).

  TEST AIM
    1. XSD gate passes (CityGML 2.0 + Energy ADE 3.0 beta7).
    2. Path = ENERGY_ADE_BOUNDARIES, 6 surfaces, wall areas GROSS (south = 30 m2).
    3. EXACTLY 2 FenestrationSurface:Detailed (the door is skipped, not 3).
    4. Window areas exactly 3.0 and 1.44 m2, computed from the vertices.
    5. South glazing: U=1.4, SHGC=0.6 (gValue BEATS the 0.55 solar band), VT=0.75.
       East  glazing: DEFAULT_WINDOW U=2.8, SHGC=0.7, VT omitted.
    6. Each window's Building_Surface_Name is its CORRECT parent wall.
    7. Both windows end up with the SAME outward normal as their wall (this is the
       assertion that fails before the winding fix).
    8. EnergyPlus exit 0, 0 Severe / 0 Fatal. A window that is not exactly in the
       plane of its parent wall, or not inside its outline, is a SEVERE in E+ - so
       passing proves the opening really does fill the hole.
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
							<nrg3:type codeSpace="volume_codeSpace">grossVolume</nrg3:type>
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
									<gml:name>East window 1.2 x 1.2 (vertices run the WRONG way)</gml:name>
									<bldg:lod3MultiSurface>
										<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
											<gml:surfaceMember>
												<gml:Polygon gml:id="L3_poly_win_east">
													<gml:exterior><gml:LinearRing>
														<gml:posList>10 3.4 0.9  10 3.4 2.1  10 4.6 2.1  10 4.6 0.9  10 3.4 0.9</gml:posList>
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
