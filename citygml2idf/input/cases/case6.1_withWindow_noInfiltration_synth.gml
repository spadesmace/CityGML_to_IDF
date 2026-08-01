<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================================
  SUPPORT SAMPLE (not an Energy ADE Table-2 case) - the AIRTIGHT TWIN of
  case6.1_lod3_1zone_hull_win_SpecificationADE.gml.
  SYNTHETIC, self-contained (every reference resolves inside this file).
  ============================================================================

  WHY THIS FILE EXISTS
    To make "what does infiltration do?" a CONTROLLED experiment. This is case 6.1
    with nrg3:infiltrationRate deleted from the ThermalZone AND NOTHING ELSE
    CHANGED: same box, same 6 surfaces, same 2 windows, same constructions, same
    coincidesWithLod3Hull zoning.

    INTENT: a real free-float model SHOULD always carry infiltration - a sealed
    zone behaves like a thermos flask. This file is a DIAGNOSTIC that shows how
    far that single number moves the answer. It is NOT a template to copy.

  WHAT WAS REMOVED - and only this
    * nrg3:infiltrationRate from the ThermalZone. XSD ThermalZoneType declares it
      minOccurs="0", so omitting it is schema-valid; the rest of the sequence
      (isCooled, isHeated, coincidesWithLod2Hull, coincidesWithLod3Hull,
      thermalBoundary) is untouched and still in schema order.
    * bldg:Building gml:id -> Case61_NoInfiltration, so run.py writes a SEPARATE
      output/runs/ folder. Every OTHER gml:id is UNCHANGED, so the two runs pair
      up zone-by-zone and surface-by-surface.

  PARSE PATH (the PREDICTION this sample tests)
    geometry / physics / zoning / openings : ALL IDENTICAL to case 6.1
                (6 surfaces, TIER 1 layers, hull zoning, 2 explicit windows).
    infiltration : zones.infiltration_air_changes() finds nothing ->
                   Zone.infiltration_ach = None, provenance status "absent",
                   and a WARNING is printed naming the zone.
                   The IDF must contain NO ZoneInfiltration:DesignFlowRate, and
                   therefore NO "Zone Infiltration ..." Output:Variable either -
                   writer.add_infiltration requests those ONLY when it wrote an
                   object, because asking E+ for a variable it cannot produce
                   raises a warning and would dirty the clean-.err gate.

  GEOMETRY - unchanged 10 (x) x 8 (y) x 3 (z) box, 2 windows (3.00 + 1.44 m2).

  TEST AIM - RUN 1 (case 6.1, 0.3 1/h) vs RUN 3 (this file, sealed), same weather
    * "Zone Infiltration Air Change Rate" exists in RUN 1 and is ABSENT here.
    * Expect this run WARMER in winter AND cooler-peaking in summer: a sealed zone
      is decoupled from outdoor air in BOTH directions, so its swing is NARROWER
      and it sits further from the outdoor mean.
    Measured 2026-07-30 by stripping the E+ object directly from 6.1's IDF (same
    geometry): operative T min 12.32 -> 14.24 C, max 22.60 -> 21.93 C.
    This file must reproduce that from the GML side.
-->
<core:CityModel xmlns:core="http://www.opengis.net/citygml/2.0"
                xmlns:bldg="http://www.opengis.net/citygml/building/2.0"
                xmlns:gml="http://www.opengis.net/gml"
                xmlns:nrg3="http://www.citygml.org/ade/energy/3.0"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<gml:name>Energy ADE Case 6.1 - LoD3 single zone, coincidesWithLod3Hull, thematic surfaces AND openings used directly</gml:name>
	<gml:boundedBy>
		<gml:Envelope srsName="EPSG:28992" srsDimension="3">
			<gml:lowerCorner>0 0 0</gml:lowerCorner>
			<gml:upperCorner>10 8 3</gml:upperCorner>
		</gml:Envelope>
	</gml:boundedBy>

	<core:cityObjectMember>
		<nrg3:LayeredConstructionLibrary gml:id="Case61_constr_library">
			<gml:name>Case 6.1 construction library</gml:name>

			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="Case61_constr_wall">
					<gml:name>Exterior wall</gml:name>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case61_layer_wall_plaster">
							<nrg3:thickness uom="m">0.015</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case61_mat_plaster">
									<gml:name>Gypsum plaster</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">0.60</nrg3:thermalConductivity>
									<nrg3:density uom="kg/m^3">1300</nrg3:density>
									<nrg3:specificHeatCapacity uom="J/(kg*K)">900</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case61_layer_wall_insulation">
							<nrg3:thickness uom="m">0.12</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case61_mat_insulation">
									<gml:name>Mineral wool</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">0.035</nrg3:thermalConductivity>
									<nrg3:density uom="kg/m^3">30</nrg3:density>
									<nrg3:specificHeatCapacity uom="J/(kg*K)">1030</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case61_layer_wall_brick">
							<nrg3:thickness uom="m">0.20</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case61_mat_brick">
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
				<nrg3:LayeredConstruction gml:id="Case61_constr_roof">
					<gml:name>Flat roof</gml:name>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case61_layer_roof_board">
							<nrg3:thickness uom="m">0.02</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case61_mat_board">
									<gml:name>Plasterboard</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">0.25</nrg3:thermalConductivity>
									<nrg3:density uom="kg/m^3">900</nrg3:density>
									<nrg3:specificHeatCapacity uom="J/(kg*K)">1000</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case61_layer_roof_insulation">
							<nrg3:thickness uom="m">0.20</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case61_mat_roof_insulation">
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
				<nrg3:LayeredConstruction gml:id="Case61_constr_ground">
					<gml:name>Ground floor</gml:name>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case61_layer_ground_screed">
							<nrg3:thickness uom="m">0.06</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case61_mat_screed">
									<gml:name>Cement screed</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">1.40</nrg3:thermalConductivity>
									<nrg3:density uom="kg/m^3">2000</nrg3:density>
									<nrg3:specificHeatCapacity uom="J/(kg*K)">1000</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case61_layer_ground_concrete">
							<nrg3:thickness uom="m">0.25</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case61_mat_concrete">
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

			<!-- GLAZING (the "g value" the spec bullet mentions). gValue AND a solar
			     transmittance are both present on purpose: gValue must WIN. -->
			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="Case61_constr_glazing">
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
		<bldg:Building gml:id="Case61_NoInfiltration">
			<gml:name>Case 6.1 building</gml:name>
			<bldg:function codeSpace="building_function">1000</bldg:function>
			<bldg:yearOfConstruction>1985</bldg:yearOfConstruction>
			<bldg:measuredHeight uom="m">3.0</bldg:measuredHeight>

			<!-- ================================================================
			     The LoD3 THEMATIC surfaces ARE the thermal boundaries, and their
			     OWN openings ARE the thermal openings. So the LayeredConstruction
			     hangs HERE, and on the windows.
			     ================================================================ -->

			<bldg:boundedBy>
				<bldg:GroundSurface gml:id="Case61_ws_ground">
					<gml:name>Ground</gml:name>
					<nrg3:layeredConstruction xlink:href="#Case61_constr_ground"/>
					<bldg:lod3MultiSurface>
						<gml:MultiSurface gml:id="Case61_MS_ground" srsName="EPSG:28992" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case61_poly_ground">
									<gml:exterior><gml:LinearRing>
										<gml:posList>0 0 0  0 8 0  10 8 0  10 0 0  0 0 0</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</bldg:lod3MultiSurface>
				</bldg:GroundSurface>
			</bldg:boundedBy>

			<bldg:boundedBy>
				<bldg:RoofSurface gml:id="Case61_ws_roof">
					<gml:name>Roof</gml:name>
					<nrg3:layeredConstruction xlink:href="#Case61_constr_roof"/>
					<bldg:lod3MultiSurface>
						<gml:MultiSurface gml:id="Case61_MS_roof" srsName="EPSG:28992" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case61_poly_roof">
									<gml:exterior><gml:LinearRing>
										<gml:posList>0 0 3  10 0 3  10 8 3  0 8 3  0 0 3</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</bldg:lod3MultiSurface>
				</bldg:RoofSurface>
			</bldg:boundedBy>

			<!-- SOUTH wall y=0, outward -Y. HOLE + window with its OWN glazing. -->
			<bldg:boundedBy>
				<bldg:WallSurface gml:id="Case61_ws_wall_south">
					<gml:name>Wall south (window)</gml:name>
					<nrg3:layeredConstruction xlink:href="#Case61_constr_wall"/>
					<bldg:lod3MultiSurface>
						<gml:MultiSurface gml:id="Case61_MS_wall_south" srsName="EPSG:28992" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case61_poly_wall_south">
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
						<bldg:Window gml:id="Case61_win_south">
							<gml:name>South window 2.0 x 1.5</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case61_constr_glazing"/>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case61_poly_win_south">
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
			</bldg:boundedBy>

			<!-- EAST wall x=10, outward +X. HOLE + window with NO construction
			     -> must fall back to DEFAULT_WINDOW. -->
			<bldg:boundedBy>
				<bldg:WallSurface gml:id="Case61_ws_wall_east">
					<gml:name>Wall east (window, no glazing construction)</gml:name>
					<nrg3:layeredConstruction xlink:href="#Case61_constr_wall"/>
					<bldg:lod3MultiSurface>
						<gml:MultiSurface gml:id="Case61_MS_wall_east" srsName="EPSG:28992" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case61_poly_wall_east">
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
						<bldg:Window gml:id="Case61_win_east">
							<gml:name>East window 1.2 x 1.2</gml:name>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case61_poly_win_east">
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
			</bldg:boundedBy>

			<!-- NORTH wall y=8, outward +Y. HOLE + a DOOR: must be SKIPPED. -->
			<bldg:boundedBy>
				<bldg:WallSurface gml:id="Case61_ws_wall_north">
					<gml:name>Wall north (door, must be skipped)</gml:name>
					<nrg3:layeredConstruction xlink:href="#Case61_constr_wall"/>
					<bldg:lod3MultiSurface>
						<gml:MultiSurface gml:id="Case61_MS_wall_north" srsName="EPSG:28992" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case61_poly_wall_north">
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
						<bldg:Door gml:id="Case61_door_north">
							<gml:name>North door 1.0 x 2.1</gml:name>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case61_poly_door_north">
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
			</bldg:boundedBy>

			<!-- WEST wall x=0, outward -X. No opening (control). -->
			<bldg:boundedBy>
				<bldg:WallSurface gml:id="Case61_ws_wall_west">
					<gml:name>Wall west (no opening)</gml:name>
					<nrg3:layeredConstruction xlink:href="#Case61_constr_wall"/>
					<bldg:lod3MultiSurface>
						<gml:MultiSurface gml:id="Case61_MS_wall_west" srsName="EPSG:28992" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case61_poly_wall_west">
									<gml:exterior><gml:LinearRing>
										<gml:posList>0 8 0  0 0 0  0 0 3  0 8 3  0 8 0</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</bldg:lod3MultiSurface>
				</bldg:WallSurface>
			</bldg:boundedBy>

			<!-- ===================== the single thermal zone =====================
			     coincidesWithLod3Hull = TRUE and NO thermalBoundary / thermal opening:
			     the zone IS the hull of the thematic surfaces above. -->
			<nrg3:thermalZone>
				<nrg3:ThermalZone gml:id="Case61_zone">
					<gml:name>Case 6.1 thermal zone</gml:name>

					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:value uom="m^3">240</nrg3:value>
							<nrg3:type codeSpace="volume_codeSpace">grossVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>

					<!-- OPTIONAL zone solid, XLinking the homologous polygons of the LoD3
					     thematic surfaces (spec bullet 3). Must NOT be read as envelope
					     geometry: the parser reads bldg: geometry only. -->
					<nrg3:lod3Solid>
						<gml:Solid gml:id="Case61_zone_solid">
							<gml:exterior>
								<gml:CompositeSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember xlink:href="#Case61_poly_ground"/>
									<gml:surfaceMember xlink:href="#Case61_poly_roof"/>
									<gml:surfaceMember xlink:href="#Case61_poly_wall_south"/>
									<gml:surfaceMember xlink:href="#Case61_poly_wall_east"/>
									<gml:surfaceMember xlink:href="#Case61_poly_wall_north"/>
									<gml:surfaceMember xlink:href="#Case61_poly_wall_west"/>
								</gml:CompositeSurface>
							</gml:exterior>
						</gml:Solid>
					</nrg3:lod3Solid>

					<nrg3:isCooled>false</nrg3:isCooled>
					<nrg3:isHeated>true</nrg3:isHeated>
					<nrg3:coincidesWithLod2Hull>false</nrg3:coincidesWithLod2Hull>
					<!-- THE FLAG -->
					<nrg3:coincidesWithLod3Hull>true</nrg3:coincidesWithLod3Hull>

					<!-- NO nrg3:thermalBoundary, NO thermal openings: forbidden in 6.1. -->
				</nrg3:ThermalZone>
			</nrg3:thermalZone>
		</bldg:Building>
	</core:cityObjectMember>
</core:CityModel>