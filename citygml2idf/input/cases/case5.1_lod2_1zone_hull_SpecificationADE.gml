<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================================
  Energy ADE 3.0 — Table 2, SPECIAL CASE 5.1
  "Single LoD2 thermal zone, no thermal openings. ALL LoD2 thermal boundaries
   coincide EXACTLY with the building LoD2 thematic surfaces"
  SYNTHETIC, self-contained (every reference resolves inside this file).
  ============================================================================

  WHAT MAKES 5.1 DIFFERENT FROM 2.1
    The spec says: when the thermal zone coincides exactly with the hull formed by
    the union of the LoD2 thematic surfaces, set coincidesWithLod2Hull = TRUE and
    model NO thermal boundaries at all. The "normal" thematic surfaces are used
    DIRECTLY in lieu of thermal boundaries, so no duplicate objects exist, and the
    LayeredConstruction objects hang off the THEMATIC SURFACES instead.

    This file is therefore the SAME BUILDING as case 2.1 — same 10 x 8 x 3 m box,
    same three detailed constructions — expressed in the other legal style. The
    IDF must come out THERMALLY IDENTICAL to case 2.1 (same 6 surfaces, same areas,
    same constructions, same materials); only the surface NAMES differ. That
    equivalence is the strongest possible check that the path switch is correct.

  PARSE PATH (the PREDICTION this sample tests)
    geometry  : SurfacePath.CITYGML_BUILDING_SHELL  <- THE SWITCH
                The zone exposes NO nrg3:thermalBoundary, so select_surface_path()
                falls through the ADE-boundary rung and reads the bldg:boundedBy
                thematic surfaces instead. (coincidesWithLodXHull is NOT a separate
                path — a hull-coincident zone simply has no boundaries to find.)
    physics   : per-surface — each THEMATIC surface carries its own
                nrg3:layeredConstruction (xlink) -> TIER 1 (detailed layers).
    zoning    : zones.py pass 1, ownership source = coincidesWithLodXHull -> the
                single zone owns the WHOLE SHELL (all 6 surfaces). This is the rung
                ABOVE the LoD1 whole-hull rule and ABOVE nrg3:thermalBoundary.
    windows   : NONE -> the IDF must contain ZERO FenestrationSurface:Detailed.

  GEOMETRY
    The same 10 (x) x 8 (y) x 3 (z) box as cases 1.1 and 2.1. CCW seen from OUTSIDE.
      ground z=0   80 m2  |  roof z=3   80 m2
      south  y=0   30 m2  |  north y=8  30 m2
      east   x=10  24 m2  |  west  x=0  24 m2
    Total envelope = 268 m2.  Zone volume = 240 m3.

  ENERGY ADE CONTENT
    * ONE nrg3:ThermalZone with coincidesWithLod2Hull = TRUE.
    * NO nrg3:thermalBoundary (the spec forbids them in this special case).
    * The 6 bldg:boundedBy thematic surfaces carry the nrg3:layeredConstruction.
    * OPTIONAL zone lod2Solid, XLinking the homologous polygons of the thematic
      surfaces (spec bullet) — must NOT be read as envelope geometry, so it must
      not produce a 7th..12th surface.
    * Constructions are byte-for-byte the same three as case 2.1, including the
      same deliberate gaps and non-SI units, so the two cases can be compared
      directly:
        wall  : plaster (1.5 cm; NO cp) | insulation (NO density; cp in kJ) | brick (g/cm3)
        roof  : plasterboard | nrg3:Gas air gap (rValue) | insulation (NO conductivity)
        ground: screed | concrete   (both complete)

  TEST AIM
    1. XSD gate passes (CityGML 2.0 + Energy ADE 3.0 beta7).
    2. Path SWITCHES to CITYGML_BUILDING_SHELL (not ENERGY_ADE_BOUNDARIES), with
       exactly 6 surfaces.
    3. Zone ownership comes from coincidesWithLodXHull and covers all 6 surfaces —
       NOT the orphan fallback (zero "in no ThermalZone" warnings).
    4. Constructions resolve from the THEMATIC surfaces (Tier 1, citygml_layers),
       never DEFAULT_CONSTRUCTION.
    5. ZERO windows in the IDF.
    6. The IDF is thermally identical to case 2.1 (6 surfaces, same areas, same 3
       constructions, same 8 materials).
    7. EnergyPlus exit 0, 0 Severe / 0 Fatal.
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
							<nrg3:type codeSpace="volume_codeSpace">grossVolume</nrg3:type>
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
