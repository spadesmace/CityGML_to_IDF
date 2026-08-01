<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================================
  Energy ADE 3.0 — Table 2, CASE 3.1
  "MULTIPLE LoD2 thermal zones, no thermal openings, some LoD2 thermal
   boundaries may have the same geometry of the corresponding building LoD2
   thematic surfaces (and others don't)"
  SYNTHETIC, self-contained (every reference resolves inside this file).
  ============================================================================

  PARSE PATH (the PREDICTION this sample tests)
    geometry  : SurfacePath.ENERGY_ADE_BOUNDARIES
                12 thermal boundaries (6 per zone). The bldg:boundedBy thematic
                shell also exists, so a double-count would give 18 surfaces.
    physics   : per-surface layeredConstruction, TIER 1 (detailed layers).
                The INTERMEDIATE FLOOR is the point of this case: ONE physical
                slab, TWO surfaces, and the second one uses a
                nrg3:ReverseLayeredConstruction of the first.
    zoning    : TWO nrg3:ThermalZone objects, each owning its 6 boundaries via
                nrg3:thermalBoundary. The two slab faces are linked by
                nrg3:relatedTo (relationType = "adjacent") -> zones.py must emit a
                RECIPROCAL EnergyPlus pair (Outside_Boundary_Condition = Surface,
                each naming the other).
    windows   : NONE -> the IDF must contain ZERO FenestrationSurface:Detailed.

  GEOMETRY — a 10 (x) x 8 (y) x 6 (z) box cut into two STACKED storeys.
      LOWER zone  z 0 -> 3      UPPER zone  z 3 -> 6
      the shared slab sits at z = 3.

      thematic shell (bldg:boundedBy, 6 surfaces, FULL height):
        ground z=0  80 m2 | roof z=6  80 m2 | walls 10x6=60 / 8x6=48 (x2 each)
      thermal boundaries (12):
        LOWER: ground 80 | 4 walls (30/24/30/24) | intermediate floor 80
        UPPER: roof   80 | 4 walls (30/24/30/24) | intermediate floor 80
      Each zone: floor area 80 m2, volume 240 m3.

  ENERGY ADE CONTENT

  (A) THE INTERZONE SLAB — one slab, two surfaces, mirrored constructions.
      EnergyPlus needs TWO real surfaces that NAME EACH OTHER (IDD
      BuildingSurface:Detailed A7: "If Surface, specify name of corresponding
      surface in adjacent zone"), so the ADE models both — we never synthesize a
      twin. Both are nrg3:IntermediateFloorSurface: the SAME ADE label on both
      faces, which is precisely why the E+ Surface Type cannot come from the name.
      It must come from the GEOMETRY, per owning zone:
          LOWER zone: the slab is ABOVE it -> outward normal +Z -> CEILING
          UPPER zone: the slab is BELOW it -> outward normal -Z -> FLOOR
      (Both faces lie exactly at the BUILDING centroid's height, so the building
      centroid cannot orient them — only the OWNING ZONE centroid can. That is
      the 2026-07-07 fix, and this case is its first purpose-built test.)

  (B) LayeredConstruction vs ReverseLayeredConstruction.
      The slab build-up is DELIBERATELY ASYMMETRIC, so a wrong order is visibly
      wrong instead of accidentally symmetric:

          UPPER ROOM
        ==================  screed        60 mm   (the upper room's floor finish)
                            concrete     200 mm
        ==================  ceiling plaster 10 mm (the lower room's ceiling finish)
          LOWER ROOM

      ADE orders layers "from the inside of the room towards the outside" — and
      "the room" is whichever room OWNS the surface:
        LOWER zone's face -> nrg3:LayeredConstruction Case31_constr_ifloor
                             inside->outside = plaster, concrete, screed (upwards)
        UPPER zone's face -> nrg3:ReverseLayeredConstruction Case31_constr_ifloor_rev
                             baseLayeredConstruction xlink -> Case31_constr_ifloor
                             It carries NO layers of its own: "same slab, other side".
                             Its inside->outside = screed, concrete, plaster (downwards)
      The writer then flips BOTH (IDD Construction: "Start with outside layer"),
      so the two IDF constructions must come out as EXACT MIRRORS:
        lower face  Outside Layer = screed   (its outside faces UP,   toward UPPER)
        upper face  Outside Layer = plaster  (its outside faces DOWN, toward LOWER)

  (C) GEOMETRY SHARED WITH THE THEMATIC SURFACES (the 2.1 rules still apply).
      Only the ground and the roof genuinely coincide with a thematic surface, so
      only they may XLink it; the eight zone walls are HALF height while the shell
      walls are full height, so they carry their own geometry ("...and others don't").
        tb_low_ground : PROPERTY-LEVEL XLINK  <bldg:lod2MultiSurface xlink:href="#..MS_ground"/>
        tb_up_roof    : MEMBER-LEVEL XLINK    <gml:surfaceMember xlink:href="#..poly_roof"/>
      tb_low_ground ALSO carries a "correspondsTo" relation to its thematic twin,
      in the same file as the "adjacent" relations on the slab — proving
      adjacency.py acts on relationType="adjacent" ONLY and does not confuse the two.

  TEST AIM
    1. XSD gate passes (CityGML 2.0 + Energy ADE 3.0 beta7).
    2. Path = ENERGY_ADE_BOUNDARIES with exactly 12 surfaces (NOT 18: the thematic
       shell must not be emitted as well).
    3. TWO E+ Zones, each owning exactly 6 surfaces (ownership = nrg3:thermalBoundary).
    4. The slab pair: both Outside_Boundary_Condition = Surface, each naming the
       OTHER; lower face = Ceiling, upper face = Floor.
    5. eplusout.eio Zone Floor Area = 80 m2 for EACH zone. (If Floor/Ceiling were
       resolved from the building centroid instead of the owning zone, the lower
       zone would report 160 m2 and E+ would warn "unenclosed zone".)
    6. The two interzone constructions are EXACT MIRRORS in the IDF (screed-first
       vs plaster-first).
    7. The 8 exterior walls stay Outdoors; ground = Ground; roof = Outdoors.
    8. ZERO windows in the IDF.
    9. EnergyPlus exit 0, 0 Severe / 0 Fatal.
-->
<core:CityModel xmlns:core="http://www.opengis.net/citygml/2.0"
                xmlns:bldg="http://www.opengis.net/citygml/building/2.0"
                xmlns:gml="http://www.opengis.net/gml"
                xmlns:nrg3="http://www.citygml.org/ade/energy/3.0"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<gml:name>Energy ADE Case 3.1 - LoD2 TWO stacked thermal zones, interzone slab, Reverse construction, no windows</gml:name>
	<gml:boundedBy>
		<gml:Envelope srsName="EPSG:28992" srsDimension="3">
			<gml:lowerCorner>0 0 0</gml:lowerCorner>
			<gml:upperCorner>10 8 6</gml:upperCorner>
		</gml:Envelope>
	</gml:boundedBy>

	<!-- ==================================================================
	     SHARED CONSTRUCTIONS (detailed layers, Tier 1). Layers are listed
	     INSIDE to OUTSIDE (ADE spec 3.8); the writer reverses them for E+.
	     ================================================================== -->
	<core:cityObjectMember>
		<nrg3:LayeredConstructionLibrary gml:id="Case31_constr_library">
			<gml:name>Case 3.1 construction library</gml:name>

			<!-- ============ exterior wall ============ -->
			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="Case31_constr_wall">
					<gml:name>Exterior wall</gml:name>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case31_layer_wall_plaster">
							<nrg3:thickness uom="m">0.015</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case31_mat_plaster">
									<gml:name>Gypsum plaster</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">0.60</nrg3:thermalConductivity>
									<nrg3:density uom="kg/m^3">1300</nrg3:density>
									<nrg3:specificHeatCapacity uom="J/(kg*K)">900</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case31_layer_wall_insulation">
							<nrg3:thickness uom="m">0.12</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case31_mat_insulation">
									<gml:name>Mineral wool</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">0.035</nrg3:thermalConductivity>
									<nrg3:density uom="kg/m^3">30</nrg3:density>
									<nrg3:specificHeatCapacity uom="J/(kg*K)">1030</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case31_layer_wall_brick">
							<nrg3:thickness uom="m">0.20</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case31_mat_brick">
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

			<!-- ============ roof ============ -->
			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="Case31_constr_roof">
					<gml:name>Flat roof</gml:name>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case31_layer_roof_board">
							<nrg3:thickness uom="m">0.02</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case31_mat_board">
									<gml:name>Plasterboard</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">0.25</nrg3:thermalConductivity>
									<nrg3:density uom="kg/m^3">900</nrg3:density>
									<nrg3:specificHeatCapacity uom="J/(kg*K)">1000</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case31_layer_roof_insulation">
							<nrg3:thickness uom="m">0.20</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case31_mat_roof_insulation">
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

			<!-- ============ ground floor ============ -->
			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="Case31_constr_ground">
					<gml:name>Ground floor</gml:name>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case31_layer_ground_screed">
							<nrg3:thickness uom="m">0.06</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case31_mat_screed">
									<gml:name>Cement screed</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">1.40</nrg3:thermalConductivity>
									<nrg3:density uom="kg/m^3">2000</nrg3:density>
									<nrg3:specificHeatCapacity uom="J/(kg*K)">1000</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case31_layer_ground_concrete">
							<nrg3:thickness uom="m">0.25</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case31_mat_concrete">
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

			<!-- ==================================================================
			     THE INTERMEDIATE FLOOR — the asymmetric slab.
			     Written INSIDE to OUTSIDE from the LOWER room: you touch the ceiling
			     plaster first, then the concrete, then the upper room's screed.
			     ================================================================== -->
			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="Case31_constr_ifloor">
					<gml:name>Intermediate floor slab, seen from the LOWER room</gml:name>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case31_layer_ifloor_plaster">
							<nrg3:thickness uom="m">0.010</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case31_mat_ifloor_plaster">
									<gml:name>Ceiling plaster (LOWER room side)</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">0.60</nrg3:thermalConductivity>
									<nrg3:density uom="kg/m^3">1300</nrg3:density>
									<nrg3:specificHeatCapacity uom="J/(kg*K)">900</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case31_layer_ifloor_concrete">
							<nrg3:thickness uom="m">0.200</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case31_mat_ifloor_concrete">
									<gml:name>Concrete slab (core)</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">1.80</nrg3:thermalConductivity>
									<nrg3:density uom="kg/m^3">2300</nrg3:density>
									<nrg3:specificHeatCapacity uom="J/(kg*K)">1000</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case31_layer_ifloor_screed">
							<nrg3:thickness uom="m">0.060</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case31_mat_ifloor_screed">
									<gml:name>Screed (UPPER room side)</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">1.40</nrg3:thermalConductivity>
									<nrg3:density uom="kg/m^3">2000</nrg3:density>
									<nrg3:specificHeatCapacity uom="J/(kg*K)">1000</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
				</nrg3:LayeredConstruction>
			</nrg3:libraryMember>

			<!-- The SAME slab, seen from the UPPER room. It carries NO layers: only a
			     pointer to the base, meaning "reverse the base's layer order". -->
			<nrg3:libraryMember>
				<nrg3:ReverseLayeredConstruction gml:id="Case31_constr_ifloor_rev">
					<gml:description>Intermediate floor slab (from inside to outside) seen from the UPPER room: reverse the layer order of the linked LayeredConstruction</gml:description>
					<gml:name>Intermediate floor slab, seen from the UPPER room</gml:name>
					<nrg3:baseLayeredConstruction xlink:href="#Case31_constr_ifloor"/>
				</nrg3:ReverseLayeredConstruction>
			</nrg3:libraryMember>
		</nrg3:LayeredConstructionLibrary>
	</core:cityObjectMember>

	<core:cityObjectMember>
		<bldg:Building gml:id="Case31_LoD2_2zone">
			<gml:name>Case 3.1 building</gml:name>
			<bldg:function codeSpace="building_function">1000</bldg:function>
			<bldg:yearOfConstruction>1985</bldg:yearOfConstruction>
			<bldg:measuredHeight uom="m">6.0</bldg:measuredHeight>

			<!-- ============ the CityGML LoD2 thematic shell (FULL height) ============
			     Only the ground and roof coincide with a thermal boundary, so only they
			     are XLinked below. NO constructions here: the boundaries own the physics. -->

			<bldg:boundedBy>
				<bldg:GroundSurface gml:id="Case31_ws_ground">
					<gml:name>Thematic ground</gml:name>
					<bldg:lod2MultiSurface>
						<gml:MultiSurface gml:id="Case31_MS_ground" srsName="EPSG:28992" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case31_poly_ground">
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
				<bldg:RoofSurface gml:id="Case31_ws_roof">
					<gml:name>Thematic roof</gml:name>
					<bldg:lod2MultiSurface>
						<gml:MultiSurface gml:id="Case31_MS_roof" srsName="EPSG:28992" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case31_poly_roof">
									<gml:exterior><gml:LinearRing>
										<gml:posList>0 0 6  10 0 6  10 8 6  0 8 6  0 0 6</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</bldg:lod2MultiSurface>
				</bldg:RoofSurface>
			</bldg:boundedBy>

			<bldg:boundedBy>
				<bldg:WallSurface gml:id="Case31_ws_wall_south">
					<gml:name>Thematic wall south (full height)</gml:name>
					<bldg:lod2MultiSurface>
						<gml:MultiSurface gml:id="Case31_MS_wall_south" srsName="EPSG:28992" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case31_poly_wall_south">
									<gml:exterior><gml:LinearRing>
										<gml:posList>0 0 0  10 0 0  10 0 6  0 0 6  0 0 0</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</bldg:lod2MultiSurface>
				</bldg:WallSurface>
			</bldg:boundedBy>

			<bldg:boundedBy>
				<bldg:WallSurface gml:id="Case31_ws_wall_east">
					<gml:name>Thematic wall east (full height)</gml:name>
					<bldg:lod2MultiSurface>
						<gml:MultiSurface gml:id="Case31_MS_wall_east" srsName="EPSG:28992" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case31_poly_wall_east">
									<gml:exterior><gml:LinearRing>
										<gml:posList>10 0 0  10 8 0  10 8 6  10 0 6  10 0 0</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</bldg:lod2MultiSurface>
				</bldg:WallSurface>
			</bldg:boundedBy>

			<bldg:boundedBy>
				<bldg:WallSurface gml:id="Case31_ws_wall_north">
					<gml:name>Thematic wall north (full height)</gml:name>
					<bldg:lod2MultiSurface>
						<gml:MultiSurface gml:id="Case31_MS_wall_north" srsName="EPSG:28992" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case31_poly_wall_north">
									<gml:exterior><gml:LinearRing>
										<gml:posList>10 8 0  0 8 0  0 8 6  10 8 6  10 8 0</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</bldg:lod2MultiSurface>
				</bldg:WallSurface>
			</bldg:boundedBy>

			<bldg:boundedBy>
				<bldg:WallSurface gml:id="Case31_ws_wall_west">
					<gml:name>Thematic wall west (full height)</gml:name>
					<bldg:lod2MultiSurface>
						<gml:MultiSurface gml:id="Case31_MS_wall_west" srsName="EPSG:28992" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case31_poly_wall_west">
									<gml:exterior><gml:LinearRing>
										<gml:posList>0 8 0  0 0 0  0 0 6  0 8 6  0 8 0</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</bldg:lod2MultiSurface>
				</bldg:WallSurface>
			</bldg:boundedBy>

			<!-- ================== LOWER thermal zone (z 0 to 3) ================== -->
			<nrg3:thermalZone>
				<nrg3:ThermalZone gml:id="Case31_zone_lower">
					<gml:name>Lower thermal zone (ground floor)</gml:name>

					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:value uom="m^3">240</nrg3:value>
							<nrg3:type codeSpace="volume_codeSpace">grossVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>

					<!-- air leakage through the fabric; E+ ZoneInfiltration:DesignFlowRate, AirChanges/Hour -->
					<nrg3:infiltrationRate uom="1/h">0.3</nrg3:infiltrationRate>
					<nrg3:isCooled>false</nrg3:isCooled>
					<nrg3:isHeated>true</nrg3:isHeated>
					<nrg3:coincidesWithLod2Hull>false</nrg3:coincidesWithLod2Hull>
					<nrg3:coincidesWithLod3Hull>false</nrg3:coincidesWithLod3Hull>

					<!-- ground: PROPERTY-LEVEL XLINK to the thematic ground geometry,
					     PLUS a "correspondsTo" relation to its thematic twin (must be
					     ignored by adjacency.py: it is NOT an adjacency). -->
					<nrg3:thermalBoundary>
						<bldg:GroundSurface gml:id="Case31_tb_low_ground">
							<gml:name>Lower zone ground (property-level xlink geometry)</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case31_constr_ground"/>
							<nrg3:relatedTo>
								<nrg3:CityObjectRelation>
									<nrg3:relationType codeSpace="relation_codeSpace">correspondsTo</nrg3:relationType>
									<nrg3:relatedTo xlink:href="#Case31_ws_ground"/>
								</nrg3:CityObjectRelation>
							</nrg3:relatedTo>
							<bldg:lod2MultiSurface xlink:href="#Case31_MS_ground"/>
						</bldg:GroundSurface>
					</nrg3:thermalBoundary>

					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="Case31_tb_low_wall_south">
							<gml:name>Lower zone wall south</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case31_constr_wall"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case31_poly_low_wall_south">
											<gml:exterior><gml:LinearRing>
												<gml:posList>0 0 0  10 0 0  10 0 3  0 0 3  0 0 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="Case31_tb_low_wall_east">
							<gml:name>Lower zone wall east</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case31_constr_wall"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case31_poly_low_wall_east">
											<gml:exterior><gml:LinearRing>
												<gml:posList>10 0 0  10 8 0  10 8 3  10 0 3  10 0 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="Case31_tb_low_wall_north">
							<gml:name>Lower zone wall north</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case31_constr_wall"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case31_poly_low_wall_north">
											<gml:exterior><gml:LinearRing>
												<gml:posList>10 8 0  0 8 0  0 8 3  10 8 3  10 8 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="Case31_tb_low_wall_west">
							<gml:name>Lower zone wall west</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case31_constr_wall"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case31_poly_low_wall_west">
											<gml:exterior><gml:LinearRing>
												<gml:posList>0 8 0  0 0 0  0 0 3  0 8 3  0 8 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

					<!-- THE SLAB, lower zone's face. Winding CCW seen from ABOVE, so its
					     normal points UP = away from the LOWER zone -> E+ Ceiling.
					     Construction = the BASE LayeredConstruction.
					     relatedTo relationType="adjacent" -> its twin in the UPPER zone. -->
					<nrg3:thermalBoundary>
						<nrg3:IntermediateFloorSurface gml:id="Case31_tb_low_ifloor">
							<gml:name>Intermediate floor, LOWER zone face (its ceiling)</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case31_constr_ifloor"/>
							<nrg3:relatedTo>
								<nrg3:CityObjectRelation>
									<nrg3:relationType codeSpace="relation_codeSpace">adjacent</nrg3:relationType>
									<nrg3:relatedTo xlink:href="#Case31_tb_up_ifloor"/>
								</nrg3:CityObjectRelation>
							</nrg3:relatedTo>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case31_poly_low_ifloor">
											<gml:exterior><gml:LinearRing>
												<gml:posList>0 0 3  10 0 3  10 8 3  0 8 3  0 0 3</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
						</nrg3:IntermediateFloorSurface>
					</nrg3:thermalBoundary>

				</nrg3:ThermalZone>
			</nrg3:thermalZone>

			<!-- ================== UPPER thermal zone (z 3 to 6) ================== -->
			<nrg3:thermalZone>
				<nrg3:ThermalZone gml:id="Case31_zone_upper">
					<gml:name>Upper thermal zone (first floor)</gml:name>

					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:value uom="m^3">240</nrg3:value>
							<nrg3:type codeSpace="volume_codeSpace">grossVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>

					<!-- air leakage through the fabric; E+ ZoneInfiltration:DesignFlowRate, AirChanges/Hour -->
					<nrg3:infiltrationRate uom="1/h">0.3</nrg3:infiltrationRate>
					<nrg3:isCooled>false</nrg3:isCooled>
					<nrg3:isHeated>true</nrg3:isHeated>
					<nrg3:coincidesWithLod2Hull>false</nrg3:coincidesWithLod2Hull>
					<nrg3:coincidesWithLod3Hull>false</nrg3:coincidesWithLod3Hull>

					<!-- THE SLAB, upper zone's face. Winding CCW seen from BELOW, so its
					     normal points DOWN = away from the UPPER zone -> E+ Floor.
					     Construction = the REVERSE construction (same slab, other side). -->
					<nrg3:thermalBoundary>
						<nrg3:IntermediateFloorSurface gml:id="Case31_tb_up_ifloor">
							<gml:name>Intermediate floor, UPPER zone face (its floor)</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case31_constr_ifloor_rev"/>
							<nrg3:relatedTo>
								<nrg3:CityObjectRelation>
									<nrg3:relationType codeSpace="relation_codeSpace">adjacent</nrg3:relationType>
									<nrg3:relatedTo xlink:href="#Case31_tb_low_ifloor"/>
								</nrg3:CityObjectRelation>
							</nrg3:relatedTo>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case31_poly_up_ifloor">
											<gml:exterior><gml:LinearRing>
												<gml:posList>0 0 3  0 8 3  10 8 3  10 0 3  0 0 3</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
						</nrg3:IntermediateFloorSurface>
					</nrg3:thermalBoundary>

					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="Case31_tb_up_wall_south">
							<gml:name>Upper zone wall south</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case31_constr_wall"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case31_poly_up_wall_south">
											<gml:exterior><gml:LinearRing>
												<gml:posList>0 0 3  10 0 3  10 0 6  0 0 6  0 0 3</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="Case31_tb_up_wall_east">
							<gml:name>Upper zone wall east</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case31_constr_wall"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case31_poly_up_wall_east">
											<gml:exterior><gml:LinearRing>
												<gml:posList>10 0 3  10 8 3  10 8 6  10 0 6  10 0 3</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="Case31_tb_up_wall_north">
							<gml:name>Upper zone wall north</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case31_constr_wall"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case31_poly_up_wall_north">
											<gml:exterior><gml:LinearRing>
												<gml:posList>10 8 3  0 8 3  0 8 6  10 8 6  10 8 3</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="Case31_tb_up_wall_west">
							<gml:name>Upper zone wall west</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case31_constr_wall"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case31_poly_up_wall_west">
											<gml:exterior><gml:LinearRing>
												<gml:posList>0 8 3  0 0 3  0 0 6  0 8 6  0 8 3</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

					<!-- roof: MEMBER-LEVEL XLINK to the thematic roof polygon -->
					<nrg3:thermalBoundary>
						<bldg:RoofSurface gml:id="Case31_tb_up_roof">
							<gml:name>Upper zone roof (member-level xlink geometry)</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case31_constr_roof"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember xlink:href="#Case31_poly_roof"/>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
						</bldg:RoofSurface>
					</nrg3:thermalBoundary>

				</nrg3:ThermalZone>
			</nrg3:thermalZone>
		</bldg:Building>
	</core:cityObjectMember>
</core:CityModel>
