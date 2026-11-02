<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================================
  Energy ADE 3.0, Table 2, CASE 4.1
  "Multiple LoD3 thermal zones with thermal openings, some LoD3 thermal
   boundaries have the same geometry of the corresponding building LoD3
   thematic surfaces/opening (and others don't)"
  SYNTHETIC, self-contained (every reference resolves inside this file).
  ============================================================================

  PARSE PATH (what the reader must do with this file)
    geometry      : the 12 thermal boundaries (6 per zone), read in LoD3. The building's
                    own LoD3 shell (6 surfaces, 4 windows) also exists and must not be read
                    as well (12 surfaces, not 18).
    zones         : TWO nrg3:ThermalZone objects (stacked storeys), both hull flags false,
                    each owning its 6 boundaries.
    constructions : detailed layers per boundary. The shared slab: the lower face uses a
                    LayeredConstruction, the upper face a ReverseLayeredConstruction of it.
                    Every window carries its own glazing construction.
    shared slab   : the two slab faces point at each other with nrg3:relatedTo,
                    relationType "adjacentTo" (codelist RelationTypeValue).
                    Default (fast) run: interior faces are Adiabatic.
                    With run.py's detailed-interior option: an EnergyPlus Surface pair, each
                    face naming the other.
    windows       : 4 thermal openings, one bldg:Window in the south and the north wall of
                    each zone, 2.0 x 1.5 m each.
    infiltration  : 0.3 1/h per zone -> 0.3 ACH each.

  GEOMETRY
    A 10 (x) x 8 (y) x 6 (z) box cut into two stacked storeys; every face is
    counter-clockwise seen from outside ITS OWN zone.
      LOWER zone z 0 to 3  |  UPPER zone z 3 to 6  |  shared slab at z = 3
      building shell (LoD3, full height): ground 80 | roof 80 | south and north walls 60
        with two holes each | east and west walls 48
      building windows: in the south and the north wall, one per storey,
        x 4 to 6 and z 1 to 2.5 (lower storey), z 4 to 5.5 (upper storey)
      thermal boundaries (12, LoD3):
        LOWER: ground 80 | walls 30/24/30/24 | slab 80, normal UP (out of the lower zone)
        UPPER: roof 80   | walls 30/24/30/24 | slab 80, normal DOWN (out of the upper zone)
      The south and north wall of each zone has one hole, filled by its thermal opening.

  ENERGY ADE CONTENT
    (A) Thermal boundaries that coincide with a building surface use an XLink to it:
          tb_low_ground : PROPERTY-level XLink to the building's ground
          tb_up_roof    : MEMBER-level XLink to the building's roof polygon
        The 8 zone walls are half height, so they carry their own geometry.
    (B) Thermal openings that coincide with a building window use an XLink to it:
          win_low_south, win_low_north : PROPERTY-level XLink to the building window
          win_up_south                 : MEMBER-level XLink to the building window polygon
          win_up_north                 : its OWN polygon at the same place ("and others don't")
    (C) The slab, as in case 3.1: one slab, two nrg3:IntermediateFloorSurface faces (one per
        zone), each pointing at the other with relatedTo adjacentTo; LayeredConstruction for
        the lower face, its ReverseLayeredConstruction for the upper face.
    (D) Glazing on every window: U 1.4 W/(m2 K), g 0.6, visible transmittance 0.75.

  TEST AIM
    1. XSD gate passes (CityGML 2.0 + Energy ADE 3.0 beta7).
    2. LoD3 is chosen; exactly 12 surfaces (not 18); two E+ Zones with 6 each.
    3. 4 windows of 3.0 m2, each in its own zone wall and facing like it; glazing U 1.4,
       SHGC 0.6, visible transmittance 0.75.
    4. Lower slab face = Ceiling, upper = Floor. Default run: both Adiabatic; with the
       detailed-interior option: both Surface, each naming the other.
    5. EnergyPlus exit 0, 0 Severe / 0 Fatal, 0 warnings.
-->
<core:CityModel xmlns:core="http://www.opengis.net/citygml/2.0"
                xmlns:bldg="http://www.opengis.net/citygml/building/2.0"
                xmlns:gml="http://www.opengis.net/gml"
                xmlns:nrg3="http://www.citygml.org/ade/energy/3.0"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<gml:name>Energy ADE Case 4.1 - LoD3 TWO stacked thermal zones with thermal openings, interzone slab</gml:name>
	<gml:boundedBy>
		<gml:Envelope srsName="EPSG:28992" srsDimension="3">
			<gml:lowerCorner>0 0 0</gml:lowerCorner>
			<gml:upperCorner>10 8 6</gml:upperCorner>
		</gml:Envelope>
	</gml:boundedBy>

	<!-- ==================================================================
	     SHARED CONSTRUCTIONS. Layers are listed INSIDE to OUTSIDE
	     (ADE spec 3.8); the writer reverses them for E+.
	     ================================================================== -->
	<core:cityObjectMember>
		<nrg3:LayeredConstructionLibrary gml:id="Case41_constr_library">
			<gml:name>Case 4.1 construction library</gml:name>

			<!-- ============ exterior wall ============ -->
			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="Case41_constr_wall">
					<gml:name>Exterior wall</gml:name>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case41_layer_wall_plaster">
							<nrg3:thickness uom="m">0.015</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case41_mat_plaster">
									<gml:name>Gypsum plaster</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">0.60</nrg3:thermalConductivity>
									<nrg3:density uom="kg/m^3">1300</nrg3:density>
									<nrg3:specificHeatCapacity uom="J/(kg*K)">900</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case41_layer_wall_insulation">
							<nrg3:thickness uom="m">0.12</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case41_mat_insulation">
									<gml:name>Mineral wool</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">0.035</nrg3:thermalConductivity>
									<nrg3:density uom="kg/m^3">30</nrg3:density>
									<nrg3:specificHeatCapacity uom="J/(kg*K)">1030</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case41_layer_wall_brick">
							<nrg3:thickness uom="m">0.20</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case41_mat_brick">
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
				<nrg3:LayeredConstruction gml:id="Case41_constr_roof">
					<gml:name>Flat roof</gml:name>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case41_layer_roof_board">
							<nrg3:thickness uom="m">0.02</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case41_mat_board">
									<gml:name>Plasterboard</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">0.25</nrg3:thermalConductivity>
									<nrg3:density uom="kg/m^3">900</nrg3:density>
									<nrg3:specificHeatCapacity uom="J/(kg*K)">1000</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case41_layer_roof_insulation">
							<nrg3:thickness uom="m">0.20</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case41_mat_roof_insulation">
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
				<nrg3:LayeredConstruction gml:id="Case41_constr_ground">
					<gml:name>Ground floor</gml:name>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case41_layer_ground_screed">
							<nrg3:thickness uom="m">0.06</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case41_mat_screed">
									<gml:name>Cement screed</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">1.40</nrg3:thermalConductivity>
									<nrg3:density uom="kg/m^3">2000</nrg3:density>
									<nrg3:specificHeatCapacity uom="J/(kg*K)">1000</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case41_layer_ground_concrete">
							<nrg3:thickness uom="m">0.25</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case41_mat_concrete">
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
			     THE INTERMEDIATE FLOOR, an asymmetric slab.
			     Written INSIDE to OUTSIDE from the LOWER room: you touch the ceiling
			     plaster first, then the concrete, then the upper room's screed.
			     ================================================================== -->
			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="Case41_constr_ifloor">
					<gml:name>Intermediate floor slab, seen from the LOWER room</gml:name>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case41_layer_ifloor_plaster">
							<nrg3:thickness uom="m">0.010</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case41_mat_ifloor_plaster">
									<gml:name>Ceiling plaster (LOWER room side)</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">0.60</nrg3:thermalConductivity>
									<nrg3:density uom="kg/m^3">1300</nrg3:density>
									<nrg3:specificHeatCapacity uom="J/(kg*K)">900</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case41_layer_ifloor_concrete">
							<nrg3:thickness uom="m">0.200</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case41_mat_ifloor_concrete">
									<gml:name>Concrete slab (core)</gml:name>
									<nrg3:thermalConductivity uom="W/(m*K)">1.80</nrg3:thermalConductivity>
									<nrg3:density uom="kg/m^3">2300</nrg3:density>
									<nrg3:specificHeatCapacity uom="J/(kg*K)">1000</nrg3:specificHeatCapacity>
								</nrg3:SolidMaterial>
							</nrg3:material>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="Case41_layer_ifloor_screed">
							<nrg3:thickness uom="m">0.060</nrg3:thickness>
							<nrg3:material>
								<nrg3:SolidMaterial gml:id="Case41_mat_ifloor_screed">
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
				<nrg3:ReverseLayeredConstruction gml:id="Case41_constr_ifloor_rev">
					<gml:description>Intermediate floor slab (from inside to outside) seen from the UPPER room: reverse the layer order of the linked LayeredConstruction</gml:description>
					<gml:name>Intermediate floor slab, seen from the UPPER room</gml:name>
					<nrg3:baseLayeredConstruction xlink:href="#Case41_constr_ifloor"/>
				</nrg3:ReverseLayeredConstruction>
			</nrg3:libraryMember>

			<!-- ============ glazing (every thermal opening) ============ -->
			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="Case41_constr_glazing">
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
		<bldg:Building gml:id="Case41_LoD3_2zone">
			<gml:name>Case 4.1 building</gml:name>
			<bldg:function codeSpace="building_function">1000</bldg:function>
			<bldg:yearOfConstruction>1985</bldg:yearOfConstruction>
			<bldg:measuredHeight uom="m">6.0</bldg:measuredHeight>

			<!-- ============ the CityGML LoD3 thematic shell (FULL height) ============
			     Its ground, its roof and its 4 windows coincide with thermal boundaries /
			     openings below, so those are XLinked. NO constructions here: the thermal
			     boundaries and openings own the physics. -->

			<bldg:boundedBy>
				<bldg:GroundSurface gml:id="Case41_ws_ground">
					<gml:name>Thematic ground</gml:name>
					<bldg:lod3MultiSurface>
						<gml:MultiSurface gml:id="Case41_MS_ground" srsName="EPSG:28992" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case41_poly_ground">
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
				<bldg:RoofSurface gml:id="Case41_ws_roof">
					<gml:name>Thematic roof</gml:name>
					<bldg:lod3MultiSurface>
						<gml:MultiSurface gml:id="Case41_MS_roof" srsName="EPSG:28992" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case41_poly_roof">
									<gml:exterior><gml:LinearRing>
										<gml:posList>0 0 6  10 0 6  10 8 6  0 8 6  0 0 6</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</bldg:lod3MultiSurface>
				</bldg:RoofSurface>
			</bldg:boundedBy>

			<!-- SOUTH wall y=0, outward -Y: two holes, one window per storey -->
			<bldg:boundedBy>
				<bldg:WallSurface gml:id="Case41_ws_wall_south">
					<gml:name>Thematic wall south (full height, 2 windows)</gml:name>
					<bldg:lod3MultiSurface>
						<gml:MultiSurface gml:id="Case41_MS_wall_south" srsName="EPSG:28992" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case41_poly_wall_south">
									<gml:exterior><gml:LinearRing>
										<gml:posList>0 0 0  10 0 0  10 0 6  0 0 6  0 0 0</gml:posList>
									</gml:LinearRing></gml:exterior>
									<gml:interior><gml:LinearRing>
										<gml:posList>4 0 1  4 0 2.5  6 0 2.5  6 0 1  4 0 1</gml:posList>
									</gml:LinearRing></gml:interior>
									<gml:interior><gml:LinearRing>
										<gml:posList>4 0 4  4 0 5.5  6 0 5.5  6 0 4  4 0 4</gml:posList>
									</gml:LinearRing></gml:interior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</bldg:lod3MultiSurface>
					<bldg:opening>
						<bldg:Window gml:id="Case41_bwin_south_low">
							<gml:name>Building window south, lower storey</gml:name>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface gml:id="Case41_MS_bwin_south_low" srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case41_poly_bwin_south_low">
											<gml:exterior><gml:LinearRing>
												<gml:posList>4 0 1  6 0 1  6 0 2.5  4 0 2.5  4 0 1</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
						</bldg:Window>
					</bldg:opening>
					<bldg:opening>
						<bldg:Window gml:id="Case41_bwin_south_up">
							<gml:name>Building window south, upper storey</gml:name>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface gml:id="Case41_MS_bwin_south_up" srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case41_poly_bwin_south_up">
											<gml:exterior><gml:LinearRing>
												<gml:posList>4 0 4  6 0 4  6 0 5.5  4 0 5.5  4 0 4</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
						</bldg:Window>
					</bldg:opening>
				</bldg:WallSurface>
			</bldg:boundedBy>

			<bldg:boundedBy>
				<bldg:WallSurface gml:id="Case41_ws_wall_east">
					<gml:name>Thematic wall east (full height)</gml:name>
					<bldg:lod3MultiSurface>
						<gml:MultiSurface gml:id="Case41_MS_wall_east" srsName="EPSG:28992" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case41_poly_wall_east">
									<gml:exterior><gml:LinearRing>
										<gml:posList>10 0 0  10 8 0  10 8 6  10 0 6  10 0 0</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</bldg:lod3MultiSurface>
				</bldg:WallSurface>
			</bldg:boundedBy>

			<!-- NORTH wall y=8, outward +Y: two holes, one window per storey -->
			<bldg:boundedBy>
				<bldg:WallSurface gml:id="Case41_ws_wall_north">
					<gml:name>Thematic wall north (full height, 2 windows)</gml:name>
					<bldg:lod3MultiSurface>
						<gml:MultiSurface gml:id="Case41_MS_wall_north" srsName="EPSG:28992" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case41_poly_wall_north">
									<gml:exterior><gml:LinearRing>
										<gml:posList>10 8 0  0 8 0  0 8 6  10 8 6  10 8 0</gml:posList>
									</gml:LinearRing></gml:exterior>
									<gml:interior><gml:LinearRing>
										<gml:posList>6 8 1  6 8 2.5  4 8 2.5  4 8 1  6 8 1</gml:posList>
									</gml:LinearRing></gml:interior>
									<gml:interior><gml:LinearRing>
										<gml:posList>6 8 4  6 8 5.5  4 8 5.5  4 8 4  6 8 4</gml:posList>
									</gml:LinearRing></gml:interior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</bldg:lod3MultiSurface>
					<bldg:opening>
						<bldg:Window gml:id="Case41_bwin_north_low">
							<gml:name>Building window north, lower storey</gml:name>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface gml:id="Case41_MS_bwin_north_low" srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case41_poly_bwin_north_low">
											<gml:exterior><gml:LinearRing>
												<gml:posList>6 8 1  4 8 1  4 8 2.5  6 8 2.5  6 8 1</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
						</bldg:Window>
					</bldg:opening>
					<bldg:opening>
						<bldg:Window gml:id="Case41_bwin_north_up">
							<gml:name>Building window north, upper storey</gml:name>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface gml:id="Case41_MS_bwin_north_up" srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case41_poly_bwin_north_up">
											<gml:exterior><gml:LinearRing>
												<gml:posList>6 8 4  4 8 4  4 8 5.5  6 8 5.5  6 8 4</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
						</bldg:Window>
					</bldg:opening>
				</bldg:WallSurface>
			</bldg:boundedBy>

			<bldg:boundedBy>
				<bldg:WallSurface gml:id="Case41_ws_wall_west">
					<gml:name>Thematic wall west (full height)</gml:name>
					<bldg:lod3MultiSurface>
						<gml:MultiSurface gml:id="Case41_MS_wall_west" srsName="EPSG:28992" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Case41_poly_wall_west">
									<gml:exterior><gml:LinearRing>
										<gml:posList>0 8 0  0 0 0  0 0 6  0 8 6  0 8 0</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</bldg:lod3MultiSurface>
				</bldg:WallSurface>
			</bldg:boundedBy>

			<!-- ================== LOWER thermal zone (z 0 to 3) ================== -->
			<nrg3:thermalZone>
				<nrg3:ThermalZone gml:id="Case41_zone_lower">
					<gml:name>Lower thermal zone (ground floor)</gml:name>

					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:value uom="m^3">240</nrg3:value>
							<nrg3:type codeSpace="http://www.sig3d.org/citygml/2.0/energy/3.0/VolumeTypeValue">grossVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>

					<!-- air leakage through the fabric; E+ ZoneInfiltration:DesignFlowRate, AirChanges/Hour -->
					<nrg3:infiltrationRate uom="1/h">0.3</nrg3:infiltrationRate>
					<nrg3:isCooled>false</nrg3:isCooled>
					<nrg3:isHeated>true</nrg3:isHeated>
					<nrg3:coincidesWithLod2Hull>false</nrg3:coincidesWithLod2Hull>
					<nrg3:coincidesWithLod3Hull>false</nrg3:coincidesWithLod3Hull>

					<!-- ground: PROPERTY-LEVEL XLINK to the building's ground geometry -->
					<nrg3:thermalBoundary>
						<bldg:GroundSurface gml:id="Case41_tb_low_ground">
							<gml:name>Lower zone ground (property-level xlink geometry)</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case41_constr_ground"/>
							<bldg:lod3MultiSurface xlink:href="#Case41_MS_ground"/>
						</bldg:GroundSurface>
					</nrg3:thermalBoundary>

					<!-- south wall, lower storey: own geometry with one hole; its thermal opening
					     XLinks the building's lower south window (property level) -->
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="Case41_tb_low_wall_south">
							<gml:name>Lower zone wall south (window)</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case41_constr_wall"/>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case41_poly_low_wall_south">
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
								<bldg:Window gml:id="Case41_win_low_south">
									<gml:name>Thermal opening, lower south (property-level xlink geometry)</gml:name>
									<nrg3:layeredConstruction xlink:href="#Case41_constr_glazing"/>
									<bldg:lod3MultiSurface xlink:href="#Case41_MS_bwin_south_low"/>
								</bldg:Window>
							</bldg:opening>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="Case41_tb_low_wall_east">
							<gml:name>Lower zone wall east</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case41_constr_wall"/>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case41_poly_low_wall_east">
											<gml:exterior><gml:LinearRing>
												<gml:posList>10 0 0  10 8 0  10 8 3  10 0 3  10 0 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

					<!-- north wall, lower storey: own geometry with one hole; its thermal opening
					     XLinks the building's lower north window (property level) -->
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="Case41_tb_low_wall_north">
							<gml:name>Lower zone wall north (window)</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case41_constr_wall"/>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case41_poly_low_wall_north">
											<gml:exterior><gml:LinearRing>
												<gml:posList>10 8 0  0 8 0  0 8 3  10 8 3  10 8 0</gml:posList>
											</gml:LinearRing></gml:exterior>
											<gml:interior><gml:LinearRing>
												<gml:posList>6 8 1  6 8 2.5  4 8 2.5  4 8 1  6 8 1</gml:posList>
											</gml:LinearRing></gml:interior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
							<bldg:opening>
								<bldg:Window gml:id="Case41_win_low_north">
									<gml:name>Thermal opening, lower north (property-level xlink geometry)</gml:name>
									<nrg3:layeredConstruction xlink:href="#Case41_constr_glazing"/>
									<bldg:lod3MultiSurface xlink:href="#Case41_MS_bwin_north_low"/>
								</bldg:Window>
							</bldg:opening>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="Case41_tb_low_wall_west">
							<gml:name>Lower zone wall west</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case41_constr_wall"/>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case41_poly_low_wall_west">
											<gml:exterior><gml:LinearRing>
												<gml:posList>0 8 0  0 0 0  0 0 3  0 8 3  0 8 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

					<!-- THE SLAB, lower zone's face. Winding CCW seen from ABOVE, so its
					     normal points UP = away from the LOWER zone -> E+ Ceiling.
					     Construction = the BASE LayeredConstruction.
					     relatedTo relationType="adjacentTo" -> its twin in the UPPER zone. -->
					<nrg3:thermalBoundary>
						<nrg3:IntermediateFloorSurface gml:id="Case41_tb_low_ifloor">
							<gml:name>Intermediate floor, LOWER zone face (its ceiling)</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case41_constr_ifloor"/>
							<nrg3:relatedTo>
								<nrg3:CityObjectRelation>
									<nrg3:relationType codeSpace="http://www.sig3d.org/citygml/2.0/energy/3.0/RelationTypeValue">adjacentTo</nrg3:relationType>
									<nrg3:relatedTo xlink:href="#Case41_tb_up_ifloor"/>
								</nrg3:CityObjectRelation>
							</nrg3:relatedTo>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case41_poly_low_ifloor">
											<gml:exterior><gml:LinearRing>
												<gml:posList>0 0 3  10 0 3  10 8 3  0 8 3  0 0 3</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
						</nrg3:IntermediateFloorSurface>
					</nrg3:thermalBoundary>

				</nrg3:ThermalZone>
			</nrg3:thermalZone>

			<!-- ================== UPPER thermal zone (z 3 to 6) ================== -->
			<nrg3:thermalZone>
				<nrg3:ThermalZone gml:id="Case41_zone_upper">
					<gml:name>Upper thermal zone (first floor)</gml:name>

					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:value uom="m^3">240</nrg3:value>
							<nrg3:type codeSpace="http://www.sig3d.org/citygml/2.0/energy/3.0/VolumeTypeValue">grossVolume</nrg3:type>
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
					     Construction = the REVERSE construction (same slab, other side).
					     relatedTo relationType="adjacentTo" -> its twin in the LOWER zone. -->
					<nrg3:thermalBoundary>
						<nrg3:IntermediateFloorSurface gml:id="Case41_tb_up_ifloor">
							<gml:name>Intermediate floor, UPPER zone face (its floor)</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case41_constr_ifloor_rev"/>
							<nrg3:relatedTo>
								<nrg3:CityObjectRelation>
									<nrg3:relationType codeSpace="http://www.sig3d.org/citygml/2.0/energy/3.0/RelationTypeValue">adjacentTo</nrg3:relationType>
									<nrg3:relatedTo xlink:href="#Case41_tb_low_ifloor"/>
								</nrg3:CityObjectRelation>
							</nrg3:relatedTo>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case41_poly_up_ifloor">
											<gml:exterior><gml:LinearRing>
												<gml:posList>0 0 3  0 8 3  10 8 3  10 0 3  0 0 3</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
						</nrg3:IntermediateFloorSurface>
					</nrg3:thermalBoundary>

					<!-- south wall, upper storey: own geometry with one hole; its thermal opening
					     XLinks the building's upper south window POLYGON (member level) -->
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="Case41_tb_up_wall_south">
							<gml:name>Upper zone wall south (window)</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case41_constr_wall"/>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case41_poly_up_wall_south">
											<gml:exterior><gml:LinearRing>
												<gml:posList>0 0 3  10 0 3  10 0 6  0 0 6  0 0 3</gml:posList>
											</gml:LinearRing></gml:exterior>
											<gml:interior><gml:LinearRing>
												<gml:posList>4 0 4  4 0 5.5  6 0 5.5  6 0 4  4 0 4</gml:posList>
											</gml:LinearRing></gml:interior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
							<bldg:opening>
								<bldg:Window gml:id="Case41_win_up_south">
									<gml:name>Thermal opening, upper south (member-level xlink geometry)</gml:name>
									<nrg3:layeredConstruction xlink:href="#Case41_constr_glazing"/>
									<bldg:lod3MultiSurface>
										<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
											<gml:surfaceMember xlink:href="#Case41_poly_bwin_south_up"/>
										</gml:MultiSurface>
									</bldg:lod3MultiSurface>
								</bldg:Window>
							</bldg:opening>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="Case41_tb_up_wall_east">
							<gml:name>Upper zone wall east</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case41_constr_wall"/>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case41_poly_up_wall_east">
											<gml:exterior><gml:LinearRing>
												<gml:posList>10 0 3  10 8 3  10 8 6  10 0 6  10 0 3</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

					<!-- north wall, upper storey: own geometry with one hole; its thermal opening
					     carries its OWN polygon at the same place as the building's window -->
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="Case41_tb_up_wall_north">
							<gml:name>Upper zone wall north (window)</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case41_constr_wall"/>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case41_poly_up_wall_north">
											<gml:exterior><gml:LinearRing>
												<gml:posList>10 8 3  0 8 3  0 8 6  10 8 6  10 8 3</gml:posList>
											</gml:LinearRing></gml:exterior>
											<gml:interior><gml:LinearRing>
												<gml:posList>6 8 4  6 8 5.5  4 8 5.5  4 8 4  6 8 4</gml:posList>
											</gml:LinearRing></gml:interior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
							<bldg:opening>
								<bldg:Window gml:id="Case41_win_up_north">
									<gml:name>Thermal opening, upper north (own geometry)</gml:name>
									<nrg3:layeredConstruction xlink:href="#Case41_constr_glazing"/>
									<bldg:lod3MultiSurface>
										<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
											<gml:surfaceMember>
												<gml:Polygon gml:id="Case41_poly_win_up_north">
													<gml:exterior><gml:LinearRing>
														<gml:posList>6 8 4  4 8 4  4 8 5.5  6 8 5.5  6 8 4</gml:posList>
													</gml:LinearRing></gml:exterior>
												</gml:Polygon>
											</gml:surfaceMember>
										</gml:MultiSurface>
									</bldg:lod3MultiSurface>
								</bldg:Window>
							</bldg:opening>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="Case41_tb_up_wall_west">
							<gml:name>Upper zone wall west</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case41_constr_wall"/>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Case41_poly_up_wall_west">
											<gml:exterior><gml:LinearRing>
												<gml:posList>0 8 3  0 0 3  0 0 6  0 8 6  0 8 3</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>

					<!-- roof: MEMBER-LEVEL XLINK to the building's roof polygon -->
					<nrg3:thermalBoundary>
						<bldg:RoofSurface gml:id="Case41_tb_up_roof">
							<gml:name>Upper zone roof (member-level xlink geometry)</gml:name>
							<nrg3:layeredConstruction xlink:href="#Case41_constr_roof"/>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember xlink:href="#Case41_poly_roof"/>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
						</bldg:RoofSurface>
					</nrg3:thermalBoundary>

				</nrg3:ThermalZone>
			</nrg3:thermalZone>
		</bldg:Building>
	</core:cityObjectMember>
</core:CityModel>
