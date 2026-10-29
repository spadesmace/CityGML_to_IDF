<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================================
  Energy ADE 3.0, Table 2, SPECIAL CASE 5.1
  "Single LoD2 thermal zone, no thermal openings. All LoD2 thermal boundaries
   coincide exactly with the building LoD2 thematic surfaces"
  SYNTHETIC, self-contained (every reference resolves inside this file).
  ============================================================================

  PARSE PATH (what the reader must do with this file)
    geometry      : the 6 bldg:boundedBy thematic surfaces. The zone states
                    coincidesWithLod2Hull = TRUE and has no thermal boundaries, so the
                    thematic shell IS the zone's envelope.
    zones         : one zone; the hull flag makes it own the whole shell (all 6).
    constructions : each thematic surface carries its own detailed LayeredConstruction.
    windows       : none.
    infiltration  : 0.3 1/h -> ZoneInfiltration 0.3 ACH.

  GEOMETRY
  A 10 (x) x 8 (y) x 3 (z) box at the origin; every face counter-clockwise seen
  from outside (its normal points out).
    ground z=0   80 m2  |  roof  z=3   80 m2
    south  y=0   30 m2  |  north y=8   30 m2  |  east x=10  24 m2  |  west x=0  24 m2
  Total envelope 268 m2; zone volume 240 m3 (= the stated nrg3:volume).

  ENERGY ADE CONTENT
    * One ThermalZone with coincidesWithLod2Hull = TRUE.
    * NO nrg3:thermalBoundary. Table 2: "None the LoD2 thermal boundaries must be
      modelled. The corresponding building LoD2 thematic surfaces must be used instead".
    * The 6 thematic surfaces carry the nrg3:layeredConstruction.
    * An optional zone lod2Solid XLinks the thematic polygons (not read as extra faces).
    * The same three constructions as case 2.1, with the same gaps and units: the two
      files describe the SAME building in the two legal styles.

  TEST AIM
    1. XSD gate passes (CityGML 2.0 + Energy ADE 3.0 beta7).
    2. Exactly 6 surfaces, from the thematic shell; the zone owns all 6.
    3. Constructions come from the thematic surfaces (detailed layers), never the default.
    4. Zero windows; ZoneInfiltration 0.3 ACH.
    5. The IDF is thermally the same as case 2.1 (same areas, constructions and
       materials); only the names differ.
    6. EnergyPlus exit 0, 0 Severe / 0 Fatal, 0 warnings.
-->
<core:CityModel xmlns:core="http://www.opengis.net/citygml/2.0"
                xmlns:bldg="http://www.opengis.net/citygml/building/2.0"
                xmlns:gml="http://www.opengis.net/gml"
                xmlns:nrg3="http://www.citygml.org/ade/energy/3.0"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<gml:name>Energy ADE Case 5.1 - LoD2 single zone, coincidesWithLod2Hull, thematic surfaces used directly, no windows</gml:name>
	<gml:boundedBy>
		<gml:Envelope srsName="EPSG:28992" srsDimension="3">
			<gml:lowerCorner>0 0 0</gml:lowerCorner>
			<gml:upperCorner>10 8 3</gml:upperCorner>
		</gml:Envelope>
	</gml:boundedBy>

	<!-- ==================================================================
	     SHARED CONSTRUCTIONS = the same three as case 2.1 (detailed layers,
	     same deliberate gaps + non-SI units), so the two cases are comparable.
	     Layers listed INSIDE to OUTSIDE (ADE spec 3.8); the writer reverses them.
	     ================================================================== -->
	<core:cityObjectMember>
		<nrg3:LayeredConstructionLibrary gml:id="Case51_constr_library">
			<gml:name>Case 5.1 construction library</gml:name>

			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="Case51_constr_wall">
					<gml:name>Wall - detailed layers</gml:name>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case51_layer_wall_plaster">
							<nrg3:thickness uom="cm">1.5</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case51_mat_plaster">
									<gml:name>Gypsum plaster (cp MISSING on purpose)</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">0.60</nrg3:thermalConductivity>
									<nrg3:density uom="kg/m^3">1300</nrg3:density>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case51_layer_wall_insulation">
							<nrg3:thickness uom="m">0.12</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case51_mat_insulation">
									<gml:name>Mineral wool (density MISSING on purpose, cp in kJ)</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">0.035</nrg3:thermalConductivity>
									<nrg3:specificHeatCapacity uom="kJ/(kg*K)">1.03</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case51_layer_wall_brick">
							<nrg3:thickness uom="m">0.20</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case51_mat_brick">
									<gml:name>Brick (COMPLETE control material, density in g/cm3)</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">0.90</nrg3:thermalConductivity>
									<nrg3:density uom="g/cm^3">1.8</nrg3:density>
									<nrg3:specificHeatCapacity uom="J/(kg*K)">900</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
				</nrg3:LayeredConstruction>
			</nrg3:libraryMember>

			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="Case51_constr_roof">
					<gml:name>Roof - detailed layers with an air gap</gml:name>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case51_layer_roof_board">
							<nrg3:thickness uom="m">0.02</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case51_mat_board">
									<gml:name>Plasterboard (COMPLETE control material)</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">0.25</nrg3:thermalConductivity>
									<nrg3:density uom="kg/m^3">900</nrg3:density>
									<nrg3:specificHeatCapacity uom="J/(kg*K)">1000</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case51_layer_roof_airgap">
							<nrg3:thickness uom="m">0.05</nrg3:thickness>
							<nrg3:material>
								<nrg3:Gas gml:id="Case51_mat_airgap">
									<gml:name>Unventilated air gap</gml:name>
									<nrg3:isVentilated>false</nrg3:isVentilated>
									<nrg3:rValue uom="m^2*K/W">0.18</nrg3:rValue>
								</nrg3:Gas>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case51_layer_roof_insulation">
							<nrg3:thickness uom="m">0.16</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case51_mat_roof_insulation">
									<gml:name>Roof insulation (thermalConductivity MISSING on purpose)</gml:name>
									<nrg3:density uom="kg/m^3">30</nrg3:density>
									<nrg3:specificHeatCapacity uom="J/(kg*K)">1030</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
				</nrg3:LayeredConstruction>
			</nrg3:libraryMember>

			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="Case51_constr_ground">
					<gml:name>Ground floor - detailed layers (all values complete)</gml:name>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case51_layer_ground_screed">
							<nrg3:thickness uom="m">0.06</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case51_mat_screed">
									<gml:name>Cement screed</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">1.40</nrg3:thermalConductivity>
									<nrg3:density uom="kg/m^3">2000</nrg3:density>
									<nrg3:specificHeatCapacity uom="J/(kg*K)">1000</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case51_layer_ground_concrete">
							<nrg3:thickness uom="m">0.25</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case51_mat_concrete">
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
		</nrg3:LayeredConstructionLibrary>
	</core:cityObjectMember>

	<core:cityObjectMember>
		<bldg:Building gml:id="Case51_LoD2_1zone_hull">
			<gml:name>Case 5.1 building</gml:name>
			<bldg:function codeSpace="building_function">1000</bldg:function>
			<bldg:yearOfConstruction>1985</bldg:yearOfConstruction>
			<bldg:measuredHeight uom="m">3.0</bldg:measuredHeight>

			<!-- ============ the LoD2 thematic surfaces ARE the thermal boundaries ============
			     5.1 special case: no duplicate thermal objects are created, so the
			     LayeredConstruction hangs off the THEMATIC surface itself. -->

			<bldg:boundedBy>
				<bldg:GroundSurface gml:id="Case51_ws_ground">
					<gml:name>Ground</gml:name>
					<nrg3:layeredConstruction xlink:href="#Case51_constr_ground"/>
					<bldg:lod2MultiSurface>
						<gml:MultiSurface gml:id="Case51_MS_ground" srsName="EPSG:28992" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case51_poly_ground">
									<gml:exterior><gml:LinearRing>
										<gml:posList>0 0 0  0 8 0  10 8 0  10 0 0  0 0 0</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</bldg:lod2MultiSurface>
				</bldg:GroundSurface>
			</bldg:boundedBy>

			<bldg:boundedBy>
				<bldg:RoofSurface gml:id="Case51_ws_roof">
					<gml:name>Roof</gml:name>
					<nrg3:layeredConstruction xlink:href="#Case51_constr_roof"/>
					<bldg:lod2MultiSurface>
						<gml:MultiSurface gml:id="Case51_MS_roof" srsName="EPSG:28992" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case51_poly_roof">
									<gml:exterior><gml:LinearRing>
										<gml:posList>0 0 3  10 0 3  10 8 3  0 8 3  0 0 3</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</bldg:lod2MultiSurface>
				</bldg:RoofSurface>
			</bldg:boundedBy>

			<bldg:boundedBy>
				<bldg:WallSurface gml:id="Case51_ws_wall_south">
					<gml:name>Wall south</gml:name>
					<nrg3:layeredConstruction xlink:href="#Case51_constr_wall"/>
					<bldg:lod2MultiSurface>
						<gml:MultiSurface gml:id="Case51_MS_wall_south" srsName="EPSG:28992" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case51_poly_wall_south">
									<gml:exterior><gml:LinearRing>
										<gml:posList>0 0 0  10 0 0  10 0 3  0 0 3  0 0 0</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</bldg:lod2MultiSurface>
				</bldg:WallSurface>
			</bldg:boundedBy>

			<bldg:boundedBy>
				<bldg:WallSurface gml:id="Case51_ws_wall_east">
					<gml:name>Wall east</gml:name>
					<nrg3:layeredConstruction xlink:href="#Case51_constr_wall"/>
					<bldg:lod2MultiSurface>
						<gml:MultiSurface gml:id="Case51_MS_wall_east" srsName="EPSG:28992" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case51_poly_wall_east">
									<gml:exterior><gml:LinearRing>
										<gml:posList>10 0 0  10 8 0  10 8 3  10 0 3  10 0 0</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</bldg:lod2MultiSurface>
				</bldg:WallSurface>
			</bldg:boundedBy>

			<bldg:boundedBy>
				<bldg:WallSurface gml:id="Case51_ws_wall_north">
					<gml:name>Wall north</gml:name>
					<nrg3:layeredConstruction xlink:href="#Case51_constr_wall"/>
					<bldg:lod2MultiSurface>
						<gml:MultiSurface gml:id="Case51_MS_wall_north" srsName="EPSG:28992" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case51_poly_wall_north">
									<gml:exterior><gml:LinearRing>
										<gml:posList>10 8 0  0 8 0  0 8 3  10 8 3  10 8 0</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</bldg:lod2MultiSurface>
				</bldg:WallSurface>
			</bldg:boundedBy>

			<bldg:boundedBy>
				<bldg:WallSurface gml:id="Case51_ws_wall_west">
					<gml:name>Wall west</gml:name>
					<nrg3:layeredConstruction xlink:href="#Case51_constr_wall"/>
					<bldg:lod2MultiSurface>
						<gml:MultiSurface gml:id="Case51_MS_wall_west" srsName="EPSG:28992" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case51_poly_wall_west">
									<gml:exterior><gml:LinearRing>
										<gml:posList>0 8 0  0 0 0  0 0 3  0 8 3  0 8 0</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</bldg:lod2MultiSurface>
				</bldg:WallSurface>
			</bldg:boundedBy>

			<!-- ===================== the single thermal zone =====================
			     coincidesWithLod2Hull = TRUE and NO thermalBoundary: the zone IS the
			     hull formed by the union of the thematic surfaces above. -->
			<nrg3:thermalZone>
				<nrg3:ThermalZone gml:id="Case51_zone">
					<gml:name>Case 5.1 thermal zone</gml:name>

					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:value uom="m^3">240</nrg3:value>
							<nrg3:type codeSpace="http://www.sig3d.org/citygml/2.0/energy/3.0/VolumeTypeValue">grossVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>

					<!-- OPTIONAL zone solid, XLinking the homologous polygons of the LoD2
					     thematic surfaces (spec bullet 2). Must NOT be read as envelope
					     geometry: the parser reads bldg: geometry only. -->
					<nrg3:lod2Solid>
						<gml:Solid gml:id="Case51_zone_solid">
							<gml:exterior>
								<gml:CompositeSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember xlink:href="#Case51_poly_ground"/>
									<gml:surfaceMember xlink:href="#Case51_poly_roof"/>
									<gml:surfaceMember xlink:href="#Case51_poly_wall_south"/>
									<gml:surfaceMember xlink:href="#Case51_poly_wall_east"/>
									<gml:surfaceMember xlink:href="#Case51_poly_wall_north"/>
									<gml:surfaceMember xlink:href="#Case51_poly_wall_west"/>
								</gml:CompositeSurface>
							</gml:exterior>
						</gml:Solid>
					</nrg3:lod2Solid>

					<!-- air leakage through the fabric; E+ ZoneInfiltration:DesignFlowRate, AirChanges/Hour -->
					<nrg3:infiltrationRate uom="1/h">0.3</nrg3:infiltrationRate>
					<nrg3:isCooled>false</nrg3:isCooled>
					<nrg3:isHeated>true</nrg3:isHeated>
					<!-- THE FLAG. TRUE -> use the thematic surfaces directly; no thermal
					     boundaries may be modelled. -->
					<nrg3:coincidesWithLod2Hull>true</nrg3:coincidesWithLod2Hull>
					<nrg3:coincidesWithLod3Hull>false</nrg3:coincidesWithLod3Hull>

					<!-- NO nrg3:thermalBoundary: forbidden in the 5.1 special case. -->
				</nrg3:ThermalZone>
			</nrg3:thermalZone>
		</bldg:Building>
	</core:cityObjectMember>
</core:CityModel>
