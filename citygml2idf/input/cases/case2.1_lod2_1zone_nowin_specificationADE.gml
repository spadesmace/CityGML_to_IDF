<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================================
  Energy ADE 3.0 — Table 2, CASE 2.1
  "Single LoD2 thermal zone, no thermal openings, SOME LoD2 thermal boundaries
   may have the SAME GEOMETRY as the corresponding building LoD2 thematic
   surfaces (and others don't)"
  SYNTHETIC, self-contained (every reference resolves inside this file).
  ============================================================================

  PARSE PATH (the PREDICTION this sample tests)
    geometry  : SurfacePath.ENERGY_ADE_BOUNDARIES
                The building has BOTH bldg:boundedBy thematic surfaces AND a
                ThermalZone with nrg3:thermalBoundary. select_surface_path() must
                pick the thermal boundaries (most detailed first) and must NOT
                also emit the 6 thematic surfaces -> exactly 6 surfaces, not 12.
    physics   : per-surface — each thermalBoundary xlinks its own
                nrg3:layeredConstruction -> TIER 1 (DETAILED LAYERS), not Tier 2.
                Case 1.1 already proved the averaged-uValue path (Material:NoMass);
                THIS case proves the detailed path: real nrg3:SolidMaterial layers
                -> E+ Material (+ one nrg3:Gas -> Material:AirGap).
                The THEMATIC surfaces carry NO construction ON PURPOSE: if the
                parser ever read the shell instead, the constructions would fall
                to DEFAULT and the mistake would be immediately visible.
    zoning    : one nrg3:ThermalZone owning all 6 boundaries via thermalBoundary.
    windows   : NONE. LoD2 forbids thermal openings, and no ADE opening ratio /
                area attribute is present -> the IDF must contain ZERO
                FenestrationSurface:Detailed objects.

  GEOMETRY
    The same 10 (x) x 8 (y) x 3 (z) box as case 1.1, so the numbers are directly
    comparable. Faces wound CCW seen from OUTSIDE.
      ground z=0   80 m2  |  roof z=3   80 m2
      south  y=0   30 m2  |  north y=8  30 m2
      east   x=10  24 m2  |  west  x=0  24 m2
    Total envelope = 268 m2.  Zone volume = 240 m3.

  ENERGY ADE CONTENT — TWO things are under test at once, on two different axes.

  (A) HOW A THERMAL BOUNDARY GETS ITS GEOMETRY. The spec allows an XLink to the
      corresponding thematic surface's LoD2 geometry when the two coincide. This
      sample deliberately uses ALL THREE legal forms, so one file proves the
      parser handles each:
        tb_wall_south : PROPERTY-LEVEL XLINK
                        <bldg:lod2MultiSurface xlink:href="#..._MS_wall_south"/>
                        The property element is EMPTY — its geometry lives elsewhere.
        tb_wall_east  : MEMBER-LEVEL XLINK
                        own <gml:MultiSurface> whose <gml:surfaceMember> XLinks the
                        thematic surface's <gml:Polygon>.
        tb_ground / tb_roof / tb_wall_north / tb_wall_west : OWN INLINE GEOMETRY
                        ("...and others don't")

      tb_wall_north also carries an nrg3:relatedTo / CityObjectRelation with
      relationType = "correspondsTo", pointing at its thematic twin — the spec's
      "RelationToCityObject" bullet. This is a BOOKKEEPING note ("same wall, two
      views"), NOT an adjacency. adjacency.py must IGNORE it (it acts only on
      relationType = "adjacent"), so the wall must stay Outdoors, never Adiabatic.

  (B) DETAILED-LAYER CONSTRUCTIONS, with DELIBERATE GAPS + NON-SI UNITS, to prove
      PER-FIELD resolution: every value the file gives is KEPT (converted when its
      uom needs it) and ONLY the truly missing field is defaulted. Never a
      whole-material default because one number is absent.

        UNIT CONVERSIONS the parser must perform (units.py):
          wall plaster thickness  1.5 cm          -> 0.015 m
          wall brick   density    1.8 g/cm^3      -> 1800 kg/m3
          wall insul.  cp         1.03 kJ/(kg*K)  -> 1030 J/(kg-K)

        MISSING FIELDS the parser must default (materials.py), one per material,
        each in a DIFFERENT material so they cannot mask each other:
          wall plaster    : NO specificHeatCapacity -> default 900  J/(kg-K)
          wall insulation : NO density              -> default 1000 kg/m3
          roof insulation : NO thermalConductivity  -> default 1.0  W/(m-K)

        CONTROLS (complete materials — must come through untouched):
          wall brick, roof plasterboard, ground screed, ground concrete
        GAS layer (roof air gap): nrg3:Gas with a real rValue -> Material:AirGap.

      LAYER ORDER: the ADE lists layers INSIDE -> OUTSIDE (spec §3.8); EnergyPlus
      CONSTRUCTION wants OUTSIDE first. The writer reverses them, so in the IDF the
      wall's Outside_Layer must be the BRICK and the last layer the PLASTER.

  TEST AIM
    1. XSD gate passes (CityGML 2.0 + Energy ADE 3.0 beta7).
    2. Path = ENERGY_ADE_BOUNDARIES, with exactly 6 surfaces (no double-count of
       the thematic shell).
    3. ALL THREE geometry-reference forms resolve: every one of the 6 boundaries
       yields a real polygon with the area listed above. A silently DROPPED
       surface (5 faces instead of 6) is the failure mode we are hunting.
    4. Constructions come from the BOUNDARIES and are TIER 1 (citygml_layers),
       never DEFAULT_CONSTRUCTION and never Tier 2.
    5. Per-field resolution: the 3 conversions above are applied, the 3 missing
       fields are defaulted, and the control materials keep their real values.
    6. IDF layer order is reversed (outside-first).
    7. relationType="correspondsTo" does NOT turn the north wall Adiabatic.
    8. ZERO windows in the IDF.
    9. EnergyPlus exit 0, 0 Severe / 0 Fatal. (Unlike case 1.1 this model HAS
       thermal mass, so the "no thermal mass" warning must NOT appear.)
-->
<core:CityModel xmlns:core="http://www.opengis.net/citygml/2.0"
                xmlns:bldg="http://www.opengis.net/citygml/building/2.0"
                xmlns:gml="http://www.opengis.net/gml"
                xmlns:nrg3="http://www.citygml.org/ade/energy/3.0"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<gml:name>Energy ADE Case 2.1 - LoD2 single zone, thermal boundaries (mixed xlink/inline geometry), detailed layers, no windows</gml:name>
	<gml:boundedBy>
		<gml:Envelope srsName="EPSG:28992" srsDimension="3">
			<gml:lowerCorner>0 0 0</gml:lowerCorner>
			<gml:upperCorner>10 8 3</gml:upperCorner>
		</gml:Envelope>
	</gml:boundedBy>

	<!-- ==================================================================
	     SHARED CONSTRUCTIONS — DETAILED LAYERS (Tier 1), referenced by
	     within-file xlink (like Alderaan). Layers are listed INSIDE -> OUTSIDE
	     (ADE spec §3.8); the writer reverses them for EnergyPlus.
	     ================================================================== -->
	<core:cityObjectMember>
		<nrg3:LayeredConstructionLibrary gml:id="Case21_constr_library">
			<gml:name>Case 2.1 construction library</gml:name>

			<!-- ================ WALL: plaster | insulation | brick ================ -->
			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="Case21_constr_wall">
					<gml:name>Wall - detailed layers</gml:name>

					<!-- inner layer. thickness in CENTIMETRES -> must become 0.015 m.
					     Material has NO specificHeatCapacity -> must default to 900. -->
					<nrg3:layer>
						<nrg3:Layer gml:id="Case21_layer_wall_plaster">
							<nrg3:thickness uom="cm">1.5</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case21_mat_plaster">
									<gml:name>Gypsum plaster (cp MISSING on purpose)</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">0.60</nrg3:thermalConductivity>
									<nrg3:density uom="kg/m^3">1300</nrg3:density>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>

					<!-- middle layer. Material has NO density -> must default to 1000.
					     cp is given in kJ/(kg*K) -> must become 1030 J/(kg-K). -->
					<nrg3:layer>
						<nrg3:Layer gml:id="Case21_layer_wall_insulation">
							<nrg3:thickness uom="m">0.12</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case21_mat_insulation">
									<gml:name>Mineral wool (density MISSING on purpose, cp in kJ)</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">0.035</nrg3:thermalConductivity>
									<nrg3:specificHeatCapacity uom="kJ/(kg*K)">1.03</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>

					<!-- outer layer = CONTROL: complete material, but density in g/cm^3
					     -> must become 1800 kg/m3. Nothing here may be defaulted. -->
					<nrg3:layer>
						<nrg3:Layer gml:id="Case21_layer_wall_brick">
							<nrg3:thickness uom="m">0.20</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case21_mat_brick">
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

			<!-- ============= ROOF: plasterboard | AIR GAP (Gas) | insulation ============= -->
			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="Case21_constr_roof">
					<gml:name>Roof - detailed layers with an air gap</gml:name>

					<!-- CONTROL: complete material -->
					<nrg3:layer>
						<nrg3:Layer gml:id="Case21_layer_roof_board">
							<nrg3:thickness uom="m">0.02</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case21_mat_board">
									<gml:name>Plasterboard (COMPLETE control material)</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">0.25</nrg3:thermalConductivity>
									<nrg3:density uom="kg/m^3">900</nrg3:density>
									<nrg3:specificHeatCapacity uom="J/(kg*K)">1000</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>

					<!-- nrg3:Gas -> EnergyPlus Material:AirGap, keeping the real rValue -->
					<nrg3:layer>
						<nrg3:Layer gml:id="Case21_layer_roof_airgap">
							<nrg3:thickness uom="m">0.05</nrg3:thickness>
							<nrg3:material>
								<nrg3:Gas gml:id="Case21_mat_airgap">
									<gml:name>Unventilated air gap</gml:name>
									<nrg3:isVentilated>false</nrg3:isVentilated>
									<nrg3:rValue uom="m^2*K/W">0.18</nrg3:rValue>
								</nrg3:Gas>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>

					<!-- Material has NO thermalConductivity -> must default to 1.0 W/(m-K).
					     (Physically silly for insulation — that is the POINT: the default
					     must be plainly visible in the middle layer's provenance.) -->
					<nrg3:layer>
						<nrg3:Layer gml:id="Case21_layer_roof_insulation">
							<nrg3:thickness uom="m">0.16</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case21_mat_roof_insulation">
									<gml:name>Roof insulation (thermalConductivity MISSING on purpose)</gml:name>
									<nrg3:density uom="kg/m^3">30</nrg3:density>
									<nrg3:specificHeatCapacity uom="J/(kg*K)">1030</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
				</nrg3:LayeredConstruction>
			</nrg3:libraryMember>

			<!-- ============= GROUND: screed | concrete — both COMPLETE (control) ============= -->
			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="Case21_constr_ground">
					<gml:name>Ground floor - detailed layers (all values complete)</gml:name>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case21_layer_ground_screed">
							<nrg3:thickness uom="m">0.06</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case21_mat_screed">
									<gml:name>Cement screed</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">1.40</nrg3:thermalConductivity>
									<nrg3:density uom="kg/m^3">2000</nrg3:density>
									<nrg3:specificHeatCapacity uom="J/(kg*K)">1000</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case21_layer_ground_concrete">
							<nrg3:thickness uom="m">0.25</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case21_mat_concrete">
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
		<bldg:Building gml:id="Case21_LoD2_1zone">
			<gml:name>Case 2.1 building</gml:name>
			<bldg:function codeSpace="building_function">1000</bldg:function>
			<bldg:yearOfConstruction>1985</bldg:yearOfConstruction>
			<bldg:measuredHeight uom="m">3.0</bldg:measuredHeight>

			<!-- ================= the CityGML LoD2 thematic surfaces =================
			     The normal building shell (Example 3 in the spec). NO construction on
			     these on purpose — the thermal boundaries own the physics in case 2.1.
			     Both the gml:MultiSurface and each gml:Polygon carry a gml:id so the
			     thermal boundaries can XLink either level. -->

			<bldg:boundedBy>
				<bldg:GroundSurface gml:id="Case21_ws_ground">
					<gml:name>Thematic ground</gml:name>
					<bldg:lod2MultiSurface>
						<gml:MultiSurface gml:id="Case21_MS_ground" srsName="EPSG:28992" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case21_poly_ground">
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
				<bldg:RoofSurface gml:id="Case21_ws_roof">
					<gml:name>Thematic roof</gml:name>
					<bldg:lod2MultiSurface>
						<gml:MultiSurface gml:id="Case21_MS_roof" srsName="EPSG:28992" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case21_poly_roof">
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
				<bldg:WallSurface gml:id="Case21_ws_wall_south">
					<gml:name>Thematic wall south</gml:name>
					<bldg:lod2MultiSurface>
						<gml:MultiSurface gml:id="Case21_MS_wall_south" srsName="EPSG:28992" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case21_poly_wall_south">
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
				<bldg:WallSurface gml:id="Case21_ws_wall_east">
					<gml:name>Thematic wall east</gml:name>
					<bldg:lod2MultiSurface>
						<gml:MultiSurface gml:id="Case21_MS_wall_east" srsName="EPSG:28992" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case21_poly_wall_east">
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
				<bldg:WallSurface gml:id="Case21_ws_wall_north">
					<gml:name>Thematic wall north</gml:name>
					<bldg:lod2MultiSurface>
						<gml:MultiSurface gml:id="Case21_MS_wall_north" srsName="EPSG:28992" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case21_poly_wall_north">
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
				<bldg:WallSurface gml:id="Case21_ws_wall_west">
					<gml:name>Thematic wall west</gml:name>
					<bldg:lod2MultiSurface>
						<gml:MultiSurface gml:id="Case21_MS_wall_west" srsName="EPSG:28992" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case21_poly_wall_west">
									<gml:exterior><gml:LinearRing>
										<gml:posList>0 8 0  0 0 0  0 0 3  0 8 3  0 8 0</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</bldg:lod2MultiSurface>
				</bldg:WallSurface>
			</bldg:boundedBy>

			<!-- ===================== the single thermal zone ===================== -->
			<nrg3:thermalZone>
				<nrg3:ThermalZone gml:id="Case21_zone">
					<gml:name>Case 2.1 thermal zone</gml:name>

					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:value uom="m^3">240</nrg3:value>
							<nrg3:type codeSpace="volume_codeSpace">grossVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>

					<!-- OPTIONAL zone solid (spec: "the thermal zone can optionally be
					     modelled as a LoD2 solid geometry"). XLinks the thematic polygons
					     instead of duplicating them; the parser must NOT read it as
					     envelope geometry (it reads bldg: geometry only). -->
					<nrg3:lod2Solid>
						<gml:Solid gml:id="Case21_zone_solid">
							<gml:exterior>
								<gml:CompositeSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember xlink:href="#Case21_poly_ground"/>
									<gml:surfaceMember xlink:href="#Case21_poly_roof"/>
									<gml:surfaceMember xlink:href="#Case21_poly_wall_south"/>
									<gml:surfaceMember xlink:href="#Case21_poly_wall_east"/>
									<gml:surfaceMember xlink:href="#Case21_poly_wall_north"/>
									<gml:surfaceMember xlink:href="#Case21_poly_wall_west"/>
								</gml:CompositeSurface>
							</gml:exterior>
						</gml:Solid>
					</nrg3:lod2Solid>

					<nrg3:isCooled>false</nrg3:isCooled>
					<nrg3:isHeated>true</nrg3:isHeated>
					<!-- FALSE: the thermal boundaries below are modelled explicitly, so this
					     is the NORMAL case 2.1 path, not the 5.1 hull special case. -->
					<nrg3:coincidesWithLod2Hull>false</nrg3:coincidesWithLod2Hull>
					<nrg3:coincidesWithLod3Hull>false</nrg3:coincidesWithLod3Hull>

					<!-- ==== tb ground: OWN INLINE GEOMETRY ==== -->
					<nrg3:thermalBoundary>
						<bldg:GroundSurface gml:id="Case21_tb_ground">
							<gml:name>Thermal boundary ground (own geometry)</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case21_constr_ground"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case21_tb_poly_ground">
											<gml:exterior><gml:LinearRing>
												<gml:posList>0 0 0  0 8 0  10 8 0  10 0 0  0 0 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
						</bldg:GroundSurface>
					</nrg3:thermalBoundary>

					<!-- ==== tb roof: OWN INLINE GEOMETRY ==== -->
					<nrg3:thermalBoundary>
						<bldg:RoofSurface gml:id="Case21_tb_roof">
							<gml:name>Thermal boundary roof (own geometry)</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case21_constr_roof"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case21_tb_poly_roof">
											<gml:exterior><gml:LinearRing>
												<gml:posList>0 0 3  10 0 3  10 8 3  0 8 3  0 0 3</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
						</bldg:RoofSurface>
					</nrg3:thermalBoundary>

					<!-- ==== tb wall SOUTH: PROPERTY-LEVEL XLINK ====
					     The geometry property itself is an xlink to the thematic surface's
					     gml:MultiSurface. The element has NO children. This is the form the
					     spec means by "XLinks to the corresponding geometry of thematic
					     surfaces are allowed". -->
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="Case21_tb_wall_south">
							<gml:name>Thermal boundary wall south (property-level xlink)</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case21_constr_wall"/>
							<bldg:lod2MultiSurface xlink:href="#Case21_MS_wall_south"/>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

					<!-- ==== tb wall EAST: MEMBER-LEVEL XLINK ====
					     Own gml:MultiSurface, but its surfaceMember xlinks the thematic
					     surface's gml:Polygon. -->
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="Case21_tb_wall_east">
							<gml:name>Thermal boundary wall east (member-level xlink)</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case21_constr_wall"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember xlink:href="#Case21_poly_wall_east"/>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

					<!-- ==== tb wall NORTH: OWN INLINE GEOMETRY + RelationToCityObject ====
					     relationType = "correspondsTo" says "I am the same wall as that
					     thematic surface". It is NOT an adjacency: this wall must stay
					     Outdoors. adjacency.py acts only on relationType = "adjacent". -->
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="Case21_tb_wall_north">
							<gml:name>Thermal boundary wall north (own geometry + correspondsTo relation)</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case21_constr_wall"/>
							<nrg3:relatedTo>
								<nrg3:CityObjectRelation>
									<nrg3:relationType codeSpace="relation_codeSpace">correspondsTo</nrg3:relationType>
									<nrg3:relatedTo xlink:href="#Case21_ws_wall_north"/>
								</nrg3:CityObjectRelation>
							</nrg3:relatedTo>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case21_tb_poly_wall_north">
											<gml:exterior><gml:LinearRing>
												<gml:posList>10 8 0  0 8 0  0 8 3  10 8 3  10 8 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

					<!-- ==== tb wall WEST: OWN INLINE GEOMETRY ==== -->
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="Case21_tb_wall_west">
							<gml:name>Thermal boundary wall west (own geometry)</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case21_constr_wall"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case21_tb_poly_wall_west">
											<gml:exterior><gml:LinearRing>
												<gml:posList>0 8 0  0 0 0  0 0 3  0 8 3  0 8 0</gml:posList>
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
