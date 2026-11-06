<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================================
  REPORT SAMPLE (not one Table-2 case): FOUR buildings in ONE file, written so
  their results compare cleanly. Every zone is the same box with the same
  materials and the same air leakage; only the way the file describes it changes.
  SYNTHETIC, self-contained (every reference resolves inside this file).
  ============================================================================

  THE FOUR BUILDINGS (each one becomes its own IDF)
    B1_LoD1_1zone  Table 2 case 1.1: LoD1 block, one zone, ONE construction for the
                   whole hull, no openings (LoD1 allows none).
    B2_LoD2_1zone  Table 2 case 2.1: LoD2, one zone, 6 thermal boundaries; windows from
                   nrg3:bdgBdrySurfOpeningToSurfaceRatio (LoD2 has no opening objects).
    B3_LoD3_1zone  LoD3, one zone, 6 thermal boundaries with thermal openings (the
                   Table 1 LoD3 rules; case 4.1 with a single zone): each window is a
                   bldg:Window that fills the hole in its wall.
    B4_LoD2_2zone  Table 2 case 3.1: LoD2, two stacked zones (10 x 8 x 6 m); the slab
                   between them is written twice, one face per zone, and the two faces
                   name each other with nrg3:relatedTo adjacentTo; windows from the ratio.

  KEPT EQUAL ON PURPOSE (so the differences come from the LoD only)
    * Geometry: every zone is a 10 (x) x 8 (y) x 3 (z) box: floor 80 m2, volume 240 m3,
      walls south / north 30 m2, east / west 24 m2. The buildings stand apart along x;
      each IDF holds one building, so they do not shade each other.
    * ONE envelope construction for EVERY opaque face of every building (walls, roof,
      ground): LoD1 can carry only one construction for the whole hull (Table 2,
      case 1.1), so B2, B3 and B4 use the same one everywhere. Its layers are the
      EnergyPlus DataSets wall "Medium Exterior Wall" (ASHRAE_2005_HOF_Materials.idf),
      values unchanged, listed inside to outside ("the order of the layers follows the
      direction of the normal vector", spec LayeredConstruction):
        G01a 19mm gypsum board   0.019 m    k 0.16   rho 800    cp 1090
        F04 wall air space       R 0.15 m2-K/W (nrg3:Gas)
        I02 50mm insulation      0.0508 m   k 0.03   rho 43     cp 1210
        M01 100mm brick          0.1016 m   k 0.89   rho 1920   cp 790
      U about 0.45 W/m2-K with surface films (an older house). The XSD requires a
      thickness on every Layer; the air gap states 0.02 m, which does not change the
      result (an air gap is read as its R value only).
    * Windows, the same ratio on the same wall in B2, B3 and B4: south 0.30, east 0.15,
      west 0.15, north 0.10; no roof windows. Window areas: south 9.0 m2, east 3.6 m2,
      west 3.6 m2, north 3.0 m2 (19.2 m2 per zone).
        B2 (and B4): the converter draws one window per wall from the ratio: the wall
            shrunk about its centre by sqrt(ratio), with its default glazing
            U 2.8 W/m2-K, g 0.7.
        B3: the bldg:Window polygons are EXACTLY those rectangles (6 decimals), and
            their glazing construction states the same U 2.8 and g 0.7.
      So B2 and B3 describe the same building and must give the same result; B1 has
      no windows (LoD1), so B1 against B2 shows what the windows do.
    * Infiltration 0.3 1/h in every zone.

  LIBRARIES (spec Rules 7 and 8)
    Every material sits in ONE nrg3:MaterialLibrary and every construction in ONE
    nrg3:LayeredConstructionLibrary, both top level. Each Layer is inline in its
    construction and points to its material by XLink (spec 4.8.4); every zone,
    surface and window points to its construction by XLink (spec 4.2.7).

  PARSE PATH (what the reader must do with this file)
    B1  geometry: the 6 polygons of bldg:lod1Solid. The zone's own LoD1 solid XLinks
        them, so the zone owns the whole hull. Construction: the zone's (XLink).
    B2  geometry: the 6 boundaries (bldg:lod2MultiSurface), construction per boundary.
        Windows: 4, from the ratio.
    B3  geometry: the 6 boundaries (bldg:lod3MultiSurface). A wall with a window has
        the hole as a gml:interior ring (ignored: EnergyPlus wants the gross wall);
        the window ring is that hole reversed, so it faces outdoors like its wall.
        Windows: 4, from the bldg:Window objects, glazing from their construction.
    B4  geometry: 12 boundaries, 6 per zone. The slab: the lower zone's face points up
        (its CEILING), the upper zone's face points down (its FLOOR); both are
        nrg3:IntermediateFloorSurface. Slab construction = the DataSets "Medium
        Floor" layers, listed from the lower room upwards:
          F16 acoustic tile                 0.0191 m   k 0.06   rho 368    cp 590
          F05 ceiling air space             R 0.18 m2-K/W (nrg3:Gas, 0.05 m stated)
          M14a 100mm heavyweight concrete   0.1016 m   k 1.95   rho 2240   cp 900
        The upper face uses a ReverseLayeredConstruction of it.
        Default (fast) run: both slab faces Adiabatic. With run.py's detailed-interior
        option: an EnergyPlus Surface pair, each face naming the other.
        Windows: 8 (the B2 set on each storey).

  GEOMETRY (local coordinates in metres: x east, y north, z up; every face is
  counter-clockwise seen from outside its zone, so its normal points out)
    B1 x 0 to 10  |  B2 x 30 to 40  |  B3 x 60 to 70  |  B4 x 90 to 100, z 0 to 6
    every building y 0 to 8

  TEST AIM
    1. XSD gate passes (CityGML 2.0 + Energy ADE 3.0 beta7).
    2. 4 IDFs: B1 6 surfaces, 0 windows | B2 6 surfaces, 4 windows | B3 6 surfaces,
       4 windows | B4 12 surfaces in 2 zones, 8 windows.
    3. Every opaque face uses the envelope construction (in the IDF outside layer
       first: brick, insulation, air gap, gypsum); no default construction anywhere.
    4. B2 and B3 windows have the same corners and areas; B3 glazing comes from the
       file (U 2.8, SHGC 0.7), B2 from the default with the same values.
    5. B4 slab: Adiabatic in the default run, a Surface pair with the detailed-interior
       option; the two slab constructions are exact mirrors.
    6. ZoneInfiltration 0.3 ACH in all 5 zones.
    7. EnergyPlus exit 0, 0 Severe / 0 Fatal, 0 warnings for all 4, in both runs.
-->
<core:CityModel xmlns:core="http://www.opengis.net/citygml/2.0"
                xmlns:bldg="http://www.opengis.net/citygml/building/2.0"
                xmlns:gml="http://www.opengis.net/gml"
                xmlns:nrg3="http://www.citygml.org/ade/energy/3.0"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<gml:name>Report sample: four buildings (LoD1, LoD2, LoD3, LoD2 two zones) with equal physics</gml:name>
	<gml:boundedBy>
		<gml:Envelope srsName="EPSG:28992" srsDimension="3">
			<gml:lowerCorner>0 0 0</gml:lowerCorner>
			<gml:upperCorner>100 8 6</gml:upperCorner>
		</gml:Envelope>
	</gml:boundedBy>

	<!-- ===== shared materials: the EnergyPlus DataSets values, unchanged =====
	     Every material sits in ONE MaterialLibrary (spec Rule 7); the layers of the
	     constructions below point to them by XLink (spec 4.8.4). -->
	<core:cityObjectMember>
		<nrg3:MaterialLibrary gml:id="R_material_library">
			<gml:name>Report sample material library</gml:name>

			<!-- the envelope layers (E+ DataSets Medium Exterior Wall) -->
			<nrg3:libraryMember>
				<nrg3:SolidMaterial gml:id="R_mat_gypsum">
					<gml:name>G01a 19mm gypsum board</gml:name>
					<nrg3:thermalConductivity uom="W/(m*K)">0.16</nrg3:thermalConductivity>
					<nrg3:density uom="kg/m^3">800</nrg3:density>
					<nrg3:specificHeatCapacity uom="J/(kg*K)">1090</nrg3:specificHeatCapacity>
				</nrg3:SolidMaterial>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:Gas gml:id="R_mat_wall_airspace">
					<gml:name>F04 Wall air space resistance</gml:name>
					<nrg3:isVentilated>false</nrg3:isVentilated>
					<nrg3:rValue uom="m^2*K/W">0.15</nrg3:rValue>
				</nrg3:Gas>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:SolidMaterial gml:id="R_mat_insulation">
					<gml:name>I02 50mm insulation board</gml:name>
					<nrg3:thermalConductivity uom="W/(m*K)">0.03</nrg3:thermalConductivity>
					<nrg3:density uom="kg/m^3">43</nrg3:density>
					<nrg3:specificHeatCapacity uom="J/(kg*K)">1210</nrg3:specificHeatCapacity>
				</nrg3:SolidMaterial>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:SolidMaterial gml:id="R_mat_brick">
					<gml:name>M01 100mm brick</gml:name>
					<nrg3:thermalConductivity uom="W/(m*K)">0.89</nrg3:thermalConductivity>
					<nrg3:density uom="kg/m^3">1920</nrg3:density>
					<nrg3:specificHeatCapacity uom="J/(kg*K)">790</nrg3:specificHeatCapacity>
				</nrg3:SolidMaterial>
			</nrg3:libraryMember>

			<!-- the slab layers (E+ DataSets Medium Floor) -->
			<nrg3:libraryMember>
				<nrg3:SolidMaterial gml:id="R_mat_tile">
					<gml:name>F16 Acoustic tile</gml:name>
					<nrg3:thermalConductivity uom="W/(m*K)">0.06</nrg3:thermalConductivity>
					<nrg3:density uom="kg/m^3">368</nrg3:density>
					<nrg3:specificHeatCapacity uom="J/(kg*K)">590</nrg3:specificHeatCapacity>
				</nrg3:SolidMaterial>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:Gas gml:id="R_mat_ceiling_airspace">
					<gml:name>F05 Ceiling air space resistance</gml:name>
					<nrg3:isVentilated>false</nrg3:isVentilated>
					<nrg3:rValue uom="m^2*K/W">0.18</nrg3:rValue>
				</nrg3:Gas>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:SolidMaterial gml:id="R_mat_concrete">
					<gml:name>M14a 100mm heavyweight concrete</gml:name>
					<nrg3:thermalConductivity uom="W/(m*K)">1.95</nrg3:thermalConductivity>
					<nrg3:density uom="kg/m^3">2240</nrg3:density>
					<nrg3:specificHeatCapacity uom="J/(kg*K)">900</nrg3:specificHeatCapacity>
				</nrg3:SolidMaterial>
			</nrg3:libraryMember>
		</nrg3:MaterialLibrary>
	</core:cityObjectMember>

	<!-- ===== shared constructions (spec Rule 8) =====
	     Layers are listed INSIDE to OUTSIDE; the converter reverses them for E+. -->
	<core:cityObjectMember>
		<nrg3:LayeredConstructionLibrary gml:id="R_constr_library">
			<gml:name>Report sample construction library</gml:name>

			<!-- envelope: every opaque face of every building (E+ DataSets Medium Exterior Wall) -->
			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="R_constr_envelope">
					<gml:name>Envelope (Medium Exterior Wall)</gml:name>
					<nrg3:layer>
						<nrg3:Layer gml:id="R_layer_env_1">
							<nrg3:thickness uom="m">0.019</nrg3:thickness>
							<nrg3:material xlink:href="#R_mat_gypsum"/>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="R_layer_env_2">
							<nrg3:thickness uom="m">0.02</nrg3:thickness>
							<nrg3:material xlink:href="#R_mat_wall_airspace"/>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="R_layer_env_3">
							<nrg3:thickness uom="m">0.0508</nrg3:thickness>
							<nrg3:material xlink:href="#R_mat_insulation"/>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="R_layer_env_4">
							<nrg3:thickness uom="m">0.1016</nrg3:thickness>
							<nrg3:material xlink:href="#R_mat_brick"/>
						</nrg3:Layer>
					</nrg3:layer>
				</nrg3:LayeredConstruction>
			</nrg3:libraryMember>

			<!-- slab between the two B4 zones (E+ DataSets Medium Floor), from the LOWER room upwards -->
			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="R_constr_slab">
					<gml:name>Intermediate slab (Medium Floor), seen from the lower room</gml:name>
					<nrg3:layer>
						<nrg3:Layer gml:id="R_layer_slab_1">
							<nrg3:thickness uom="m">0.0191</nrg3:thickness>
							<nrg3:material xlink:href="#R_mat_tile"/>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="R_layer_slab_2">
							<nrg3:thickness uom="m">0.05</nrg3:thickness>
							<nrg3:material xlink:href="#R_mat_ceiling_airspace"/>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="R_layer_slab_3">
							<nrg3:thickness uom="m">0.1016</nrg3:thickness>
							<nrg3:material xlink:href="#R_mat_concrete"/>
						</nrg3:Layer>
					</nrg3:layer>
				</nrg3:LayeredConstruction>
			</nrg3:libraryMember>

			<!-- the SAME slab seen from the UPPER room: no layers of its own, only its base -->
			<nrg3:libraryMember>
				<nrg3:ReverseLayeredConstruction gml:id="R_constr_slab_rev">
					<gml:name>Intermediate slab, seen from the upper room</gml:name>
					<nrg3:baseLayeredConstruction xlink:href="#R_constr_slab"/>
				</nrg3:ReverseLayeredConstruction>
			</nrg3:libraryMember>

			<!-- glazing of the B3 windows: the same values as the converter's default glazing -->
			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="R_constr_glazing">
					<gml:name>Window glazing U 2.8, g 0.7</gml:name>
					<nrg3:uValue uom="W/(K*m^2)">2.8</nrg3:uValue>
					<nrg3:gValue uom="unit interval">0.7</nrg3:gValue>
				</nrg3:LayeredConstruction>
			</nrg3:libraryMember>
		</nrg3:LayeredConstructionLibrary>
	</core:cityObjectMember>

	<!-- ===== B1: LoD1 block (Table 2 case 1.1) ===== -->
	<core:cityObjectMember>
		<bldg:Building gml:id="B1_LoD1_1zone">
			<gml:name>B1: LoD1 block, one zone</gml:name>
			<bldg:function codeSpace="building_function">1000</bldg:function>
			<bldg:yearOfConstruction>1985</bldg:yearOfConstruction>
			<bldg:measuredHeight uom="m">3.0</bldg:measuredHeight>
			<bldg:lod1Solid>
				<gml:Solid gml:id="B1_solid">
					<gml:exterior>
						<gml:CompositeSurface srsName="EPSG:28992" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="B1_poly_ground">
									<gml:exterior><gml:LinearRing>
										<gml:posList>0 0 0  0 8 0  10 8 0  10 0 0  0 0 0</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
							<gml:surfaceMember>
								<gml:Polygon gml:id="B1_poly_roof">
									<gml:exterior><gml:LinearRing>
										<gml:posList>0 0 3  10 0 3  10 8 3  0 8 3  0 0 3</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
							<gml:surfaceMember>
								<gml:Polygon gml:id="B1_poly_south">
									<gml:exterior><gml:LinearRing>
										<gml:posList>0 0 0  10 0 0  10 0 3  0 0 3  0 0 0</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
							<gml:surfaceMember>
								<gml:Polygon gml:id="B1_poly_east">
									<gml:exterior><gml:LinearRing>
										<gml:posList>10 0 0  10 8 0  10 8 3  10 0 3  10 0 0</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
							<gml:surfaceMember>
								<gml:Polygon gml:id="B1_poly_north">
									<gml:exterior><gml:LinearRing>
										<gml:posList>10 8 0  0 8 0  0 8 3  10 8 3  10 8 0</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
							<gml:surfaceMember>
								<gml:Polygon gml:id="B1_poly_west">
									<gml:exterior><gml:LinearRing>
										<gml:posList>0 8 0  0 0 0  0 0 3  0 8 3  0 8 0</gml:posList>
									</gml:LinearRing></gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:CompositeSurface>
					</gml:exterior>
				</gml:Solid>
			</bldg:lod1Solid>
			<nrg3:thermalZone>
				<nrg3:ThermalZone gml:id="B1_zone">
					<gml:name>B1 thermal zone</gml:name>
					<!-- ONE construction for the whole thermal hull (Table 2, case 1.1) -->
					<nrg3:layeredConstruction xlink:href="#R_constr_envelope"/>
					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:value uom="m^3">240</nrg3:value>
							<nrg3:type codeSpace="http://www.sig3d.org/citygml/2.0/energy/3.0/VolumeTypeValue">grossVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>
					<!-- optional zone solid: XLinks to the homologous polygons of the building solid -->
					<nrg3:lod1Solid>
						<gml:Solid gml:id="B1_zone_solid">
							<gml:exterior>
								<gml:CompositeSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember xlink:href="#B1_poly_ground"/>
									<gml:surfaceMember xlink:href="#B1_poly_roof"/>
									<gml:surfaceMember xlink:href="#B1_poly_south"/>
									<gml:surfaceMember xlink:href="#B1_poly_east"/>
									<gml:surfaceMember xlink:href="#B1_poly_north"/>
									<gml:surfaceMember xlink:href="#B1_poly_west"/>
								</gml:CompositeSurface>
							</gml:exterior>
						</gml:Solid>
					</nrg3:lod1Solid>
					<nrg3:infiltrationRate uom="1/h">0.3</nrg3:infiltrationRate>
					<nrg3:isCooled>false</nrg3:isCooled>
					<nrg3:isHeated>true</nrg3:isHeated>
					<nrg3:coincidesWithLod2Hull>false</nrg3:coincidesWithLod2Hull>
					<nrg3:coincidesWithLod3Hull>false</nrg3:coincidesWithLod3Hull>
					<!-- no nrg3:thermalBoundary and no openings: neither is allowed in LoD1 -->
				</nrg3:ThermalZone>
			</nrg3:thermalZone>
		</bldg:Building>
	</core:cityObjectMember>

	<!-- ===== B2: LoD2, one zone, windows from the opening ratio (Table 2 case 2.1) ===== -->
	<core:cityObjectMember>
		<bldg:Building gml:id="B2_LoD2_1zone">
			<gml:name>B2: LoD2, one zone, ratio windows</gml:name>
			<bldg:function codeSpace="building_function">1000</bldg:function>
			<bldg:yearOfConstruction>1985</bldg:yearOfConstruction>
			<bldg:measuredHeight uom="m">3.0</bldg:measuredHeight>
			<nrg3:thermalZone>
				<nrg3:ThermalZone gml:id="B2_zone">
					<gml:name>B2 thermal zone</gml:name>
					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:value uom="m^3">240</nrg3:value>
							<nrg3:type codeSpace="http://www.sig3d.org/citygml/2.0/energy/3.0/VolumeTypeValue">grossVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>
					<nrg3:infiltrationRate uom="1/h">0.3</nrg3:infiltrationRate>
					<nrg3:isCooled>false</nrg3:isCooled>
					<nrg3:isHeated>true</nrg3:isHeated>
					<nrg3:coincidesWithLod2Hull>false</nrg3:coincidesWithLod2Hull>
					<nrg3:coincidesWithLod3Hull>false</nrg3:coincidesWithLod3Hull>
					<nrg3:thermalBoundary>
						<bldg:GroundSurface gml:id="B2_tb_ground">
							<gml:name>Ground</gml:name>
							<nrg3:layeredConstruction xlink:href="#R_constr_envelope"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="B2_poly_ground">
											<gml:exterior><gml:LinearRing>
												<gml:posList>30 0 0  30 8 0  40 8 0  40 0 0  30 0 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
						</bldg:GroundSurface>
					</nrg3:thermalBoundary>
					<nrg3:thermalBoundary>
						<bldg:RoofSurface gml:id="B2_tb_roof">
							<gml:name>Roof</gml:name>
							<nrg3:layeredConstruction xlink:href="#R_constr_envelope"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="B2_poly_roof">
											<gml:exterior><gml:LinearRing>
												<gml:posList>30 0 3  40 0 3  40 8 3  30 8 3  30 0 3</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
						</bldg:RoofSurface>
					</nrg3:thermalBoundary>
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="B2_tb_wall_south">
							<gml:name>Wall south, opening ratio 0.3</gml:name>
							<nrg3:layeredConstruction xlink:href="#R_constr_envelope"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="B2_poly_wall_south">
											<gml:exterior><gml:LinearRing>
												<gml:posList>30 0 0  40 0 0  40 0 3  30 0 3  30 0 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
							<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0.3</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="B2_tb_wall_east">
							<gml:name>Wall east, opening ratio 0.15</gml:name>
							<nrg3:layeredConstruction xlink:href="#R_constr_envelope"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="B2_poly_wall_east">
											<gml:exterior><gml:LinearRing>
												<gml:posList>40 0 0  40 8 0  40 8 3  40 0 3  40 0 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
							<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0.15</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="B2_tb_wall_north">
							<gml:name>Wall north, opening ratio 0.1</gml:name>
							<nrg3:layeredConstruction xlink:href="#R_constr_envelope"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="B2_poly_wall_north">
											<gml:exterior><gml:LinearRing>
												<gml:posList>40 8 0  30 8 0  30 8 3  40 8 3  40 8 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
							<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0.1</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="B2_tb_wall_west">
							<gml:name>Wall west, opening ratio 0.15</gml:name>
							<nrg3:layeredConstruction xlink:href="#R_constr_envelope"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="B2_poly_wall_west">
											<gml:exterior><gml:LinearRing>
												<gml:posList>30 8 0  30 0 0  30 0 3  30 8 3  30 8 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
							<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0.15</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>
				</nrg3:ThermalZone>
			</nrg3:thermalZone>
		</bldg:Building>
	</core:cityObjectMember>

	<!-- ===== B3: LoD3, one zone, bldg:Window objects (Table 1 LoD3 rules) ===== -->
	<core:cityObjectMember>
		<bldg:Building gml:id="B3_LoD3_1zone">
			<gml:name>B3: LoD3, one zone, window objects</gml:name>
			<bldg:function codeSpace="building_function">1000</bldg:function>
			<bldg:yearOfConstruction>1985</bldg:yearOfConstruction>
			<bldg:measuredHeight uom="m">3.0</bldg:measuredHeight>
			<nrg3:thermalZone>
				<nrg3:ThermalZone gml:id="B3_zone">
					<gml:name>B3 thermal zone</gml:name>
					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:value uom="m^3">240</nrg3:value>
							<nrg3:type codeSpace="http://www.sig3d.org/citygml/2.0/energy/3.0/VolumeTypeValue">grossVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>
					<nrg3:infiltrationRate uom="1/h">0.3</nrg3:infiltrationRate>
					<nrg3:isCooled>false</nrg3:isCooled>
					<nrg3:isHeated>true</nrg3:isHeated>
					<nrg3:coincidesWithLod2Hull>false</nrg3:coincidesWithLod2Hull>
					<nrg3:coincidesWithLod3Hull>false</nrg3:coincidesWithLod3Hull>
					<nrg3:thermalBoundary>
						<bldg:GroundSurface gml:id="B3_tb_ground">
							<gml:name>Ground</gml:name>
							<nrg3:layeredConstruction xlink:href="#R_constr_envelope"/>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="B3_poly_ground">
											<gml:exterior><gml:LinearRing>
												<gml:posList>60 0 0  60 8 0  70 8 0  70 0 0  60 0 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
						</bldg:GroundSurface>
					</nrg3:thermalBoundary>
					<nrg3:thermalBoundary>
						<bldg:RoofSurface gml:id="B3_tb_roof">
							<gml:name>Roof</gml:name>
							<nrg3:layeredConstruction xlink:href="#R_constr_envelope"/>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="B3_poly_roof">
											<gml:exterior><gml:LinearRing>
												<gml:posList>60 0 3  70 0 3  70 8 3  60 8 3  60 0 3</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
						</bldg:RoofSurface>
					</nrg3:thermalBoundary>
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="B3_tb_wall_south">
							<gml:name>Wall south, window 9.0 m2</gml:name>
							<nrg3:layeredConstruction xlink:href="#R_constr_envelope"/>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="B3_poly_wall_south">
											<gml:exterior><gml:LinearRing>
												<gml:posList>60 0 0  70 0 0  70 0 3  60 0 3  60 0 0</gml:posList>
											</gml:LinearRing></gml:exterior>
											<gml:interior><gml:LinearRing>
												<gml:posList>62.261387 0 0.678416  62.261387 0 2.321584  67.738613 0 2.321584  67.738613 0 0.678416  62.261387 0 0.678416</gml:posList>
											</gml:LinearRing></gml:interior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
							<bldg:opening>
								<bldg:Window gml:id="B3_win_south">
									<gml:name>Window south, 9.0 m2</gml:name>
									<nrg3:layeredConstruction xlink:href="#R_constr_glazing"/>
									<bldg:lod3MultiSurface>
										<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
											<gml:surfaceMember>
												<gml:Polygon gml:id="B3_poly_win_south">
													<gml:exterior><gml:LinearRing>
														<gml:posList>62.261387 0 0.678416  67.738613 0 0.678416  67.738613 0 2.321584  62.261387 0 2.321584  62.261387 0 0.678416</gml:posList>
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
						<bldg:WallSurface gml:id="B3_tb_wall_east">
							<gml:name>Wall east, window 3.6 m2</gml:name>
							<nrg3:layeredConstruction xlink:href="#R_constr_envelope"/>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="B3_poly_wall_east">
											<gml:exterior><gml:LinearRing>
												<gml:posList>70 0 0  70 8 0  70 8 3  70 0 3  70 0 0</gml:posList>
											</gml:LinearRing></gml:exterior>
											<gml:interior><gml:LinearRing>
												<gml:posList>70 2.450807 0.919052  70 2.450807 2.080948  70 5.549193 2.080948  70 5.549193 0.919052  70 2.450807 0.919052</gml:posList>
											</gml:LinearRing></gml:interior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
							<bldg:opening>
								<bldg:Window gml:id="B3_win_east">
									<gml:name>Window east, 3.6 m2</gml:name>
									<nrg3:layeredConstruction xlink:href="#R_constr_glazing"/>
									<bldg:lod3MultiSurface>
										<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
											<gml:surfaceMember>
												<gml:Polygon gml:id="B3_poly_win_east">
													<gml:exterior><gml:LinearRing>
														<gml:posList>70 2.450807 0.919052  70 5.549193 0.919052  70 5.549193 2.080948  70 2.450807 2.080948  70 2.450807 0.919052</gml:posList>
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
						<bldg:WallSurface gml:id="B3_tb_wall_north">
							<gml:name>Wall north, window 3.0 m2</gml:name>
							<nrg3:layeredConstruction xlink:href="#R_constr_envelope"/>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="B3_poly_wall_north">
											<gml:exterior><gml:LinearRing>
												<gml:posList>70 8 0  60 8 0  60 8 3  70 8 3  70 8 0</gml:posList>
											</gml:LinearRing></gml:exterior>
											<gml:interior><gml:LinearRing>
												<gml:posList>66.581139 8 1.025658  66.581139 8 1.974342  63.418861 8 1.974342  63.418861 8 1.025658  66.581139 8 1.025658</gml:posList>
											</gml:LinearRing></gml:interior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
							<bldg:opening>
								<bldg:Window gml:id="B3_win_north">
									<gml:name>Window north, 3.0 m2</gml:name>
									<nrg3:layeredConstruction xlink:href="#R_constr_glazing"/>
									<bldg:lod3MultiSurface>
										<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
											<gml:surfaceMember>
												<gml:Polygon gml:id="B3_poly_win_north">
													<gml:exterior><gml:LinearRing>
														<gml:posList>66.581139 8 1.025658  63.418861 8 1.025658  63.418861 8 1.974342  66.581139 8 1.974342  66.581139 8 1.025658</gml:posList>
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
						<bldg:WallSurface gml:id="B3_tb_wall_west">
							<gml:name>Wall west, window 3.6 m2</gml:name>
							<nrg3:layeredConstruction xlink:href="#R_constr_envelope"/>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="B3_poly_wall_west">
											<gml:exterior><gml:LinearRing>
												<gml:posList>60 8 0  60 0 0  60 0 3  60 8 3  60 8 0</gml:posList>
											</gml:LinearRing></gml:exterior>
											<gml:interior><gml:LinearRing>
												<gml:posList>60 5.549193 0.919052  60 5.549193 2.080948  60 2.450807 2.080948  60 2.450807 0.919052  60 5.549193 0.919052</gml:posList>
											</gml:LinearRing></gml:interior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
							<bldg:opening>
								<bldg:Window gml:id="B3_win_west">
									<gml:name>Window west, 3.6 m2</gml:name>
									<nrg3:layeredConstruction xlink:href="#R_constr_glazing"/>
									<bldg:lod3MultiSurface>
										<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
											<gml:surfaceMember>
												<gml:Polygon gml:id="B3_poly_win_west">
													<gml:exterior><gml:LinearRing>
														<gml:posList>60 5.549193 0.919052  60 2.450807 0.919052  60 2.450807 2.080948  60 5.549193 2.080948  60 5.549193 0.919052</gml:posList>
													</gml:LinearRing></gml:exterior>
												</gml:Polygon>
											</gml:surfaceMember>
										</gml:MultiSurface>
									</bldg:lod3MultiSurface>
								</bldg:Window>
							</bldg:opening>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>
				</nrg3:ThermalZone>
			</nrg3:thermalZone>
		</bldg:Building>
	</core:cityObjectMember>

	<!-- ===== B4: LoD2, two stacked zones (Table 2 case 3.1) ===== -->
	<core:cityObjectMember>
		<bldg:Building gml:id="B4_LoD2_2zone">
			<gml:name>B4: LoD2, two stacked zones, ratio windows</gml:name>
			<bldg:function codeSpace="building_function">1000</bldg:function>
			<bldg:yearOfConstruction>1985</bldg:yearOfConstruction>
			<bldg:measuredHeight uom="m">6.0</bldg:measuredHeight>
			<!-- ===== LOWER zone, z 0 to 3 ===== -->
			<nrg3:thermalZone>
				<nrg3:ThermalZone gml:id="B4_zone_lower">
					<gml:name>B4 lower zone (ground floor)</gml:name>
					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:value uom="m^3">240</nrg3:value>
							<nrg3:type codeSpace="http://www.sig3d.org/citygml/2.0/energy/3.0/VolumeTypeValue">grossVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>
					<nrg3:infiltrationRate uom="1/h">0.3</nrg3:infiltrationRate>
					<nrg3:isCooled>false</nrg3:isCooled>
					<nrg3:isHeated>true</nrg3:isHeated>
					<nrg3:coincidesWithLod2Hull>false</nrg3:coincidesWithLod2Hull>
					<nrg3:coincidesWithLod3Hull>false</nrg3:coincidesWithLod3Hull>
					<nrg3:thermalBoundary>
						<bldg:GroundSurface gml:id="B4_tb_low_ground">
							<gml:name>Lower zone ground</gml:name>
							<nrg3:layeredConstruction xlink:href="#R_constr_envelope"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="B4_poly_low_ground">
											<gml:exterior><gml:LinearRing>
												<gml:posList>90 0 0  90 8 0  100 8 0  100 0 0  90 0 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
						</bldg:GroundSurface>
					</nrg3:thermalBoundary>
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="B4_tb_low_wall_south">
							<gml:name>Lower zone wall south, opening ratio 0.3</gml:name>
							<nrg3:layeredConstruction xlink:href="#R_constr_envelope"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="B4_poly_low_wall_south">
											<gml:exterior><gml:LinearRing>
												<gml:posList>90 0 0  100 0 0  100 0 3  90 0 3  90 0 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
							<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0.3</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="B4_tb_low_wall_east">
							<gml:name>Lower zone wall east, opening ratio 0.15</gml:name>
							<nrg3:layeredConstruction xlink:href="#R_constr_envelope"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="B4_poly_low_wall_east">
											<gml:exterior><gml:LinearRing>
												<gml:posList>100 0 0  100 8 0  100 8 3  100 0 3  100 0 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
							<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0.15</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="B4_tb_low_wall_north">
							<gml:name>Lower zone wall north, opening ratio 0.1</gml:name>
							<nrg3:layeredConstruction xlink:href="#R_constr_envelope"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="B4_poly_low_wall_north">
											<gml:exterior><gml:LinearRing>
												<gml:posList>100 8 0  90 8 0  90 8 3  100 8 3  100 8 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
							<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0.1</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="B4_tb_low_wall_west">
							<gml:name>Lower zone wall west, opening ratio 0.15</gml:name>
							<nrg3:layeredConstruction xlink:href="#R_constr_envelope"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="B4_poly_low_wall_west">
											<gml:exterior><gml:LinearRing>
												<gml:posList>90 8 0  90 0 0  90 0 3  90 8 3  90 8 0</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
							<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0.15</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>
					<!-- the slab, lower zone's face: normal UP, away from the lower zone (its ceiling) -->
					<nrg3:thermalBoundary>
						<nrg3:IntermediateFloorSurface gml:id="B4_tb_low_ifloor">
							<gml:name>Slab, lower zone face (its ceiling)</gml:name>
							<nrg3:layeredConstruction xlink:href="#R_constr_slab"/>
							<nrg3:relatedTo>
								<nrg3:CityObjectRelation>
									<nrg3:relationType codeSpace="http://www.sig3d.org/citygml/2.0/energy/3.0/RelationTypeValue">adjacentTo</nrg3:relationType>
									<nrg3:relatedTo xlink:href="#B4_tb_up_ifloor"/>
								</nrg3:CityObjectRelation>
							</nrg3:relatedTo>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="B4_poly_low_ifloor">
											<gml:exterior><gml:LinearRing>
												<gml:posList>90 0 3  100 0 3  100 8 3  90 8 3  90 0 3</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
						</nrg3:IntermediateFloorSurface>
					</nrg3:thermalBoundary>
				</nrg3:ThermalZone>
			</nrg3:thermalZone>

			<!-- ===== UPPER zone, z 3 to 6 ===== -->
			<nrg3:thermalZone>
				<nrg3:ThermalZone gml:id="B4_zone_upper">
					<gml:name>B4 upper zone (first floor)</gml:name>
					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:value uom="m^3">240</nrg3:value>
							<nrg3:type codeSpace="http://www.sig3d.org/citygml/2.0/energy/3.0/VolumeTypeValue">grossVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>
					<nrg3:infiltrationRate uom="1/h">0.3</nrg3:infiltrationRate>
					<nrg3:isCooled>false</nrg3:isCooled>
					<nrg3:isHeated>true</nrg3:isHeated>
					<nrg3:coincidesWithLod2Hull>false</nrg3:coincidesWithLod2Hull>
					<nrg3:coincidesWithLod3Hull>false</nrg3:coincidesWithLod3Hull>
					<!-- the slab, upper zone's face: normal DOWN, away from the upper zone (its floor) -->
					<nrg3:thermalBoundary>
						<nrg3:IntermediateFloorSurface gml:id="B4_tb_up_ifloor">
							<gml:name>Slab, upper zone face (its floor)</gml:name>
							<nrg3:layeredConstruction xlink:href="#R_constr_slab_rev"/>
							<nrg3:relatedTo>
								<nrg3:CityObjectRelation>
									<nrg3:relationType codeSpace="http://www.sig3d.org/citygml/2.0/energy/3.0/RelationTypeValue">adjacentTo</nrg3:relationType>
									<nrg3:relatedTo xlink:href="#B4_tb_low_ifloor"/>
								</nrg3:CityObjectRelation>
							</nrg3:relatedTo>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="B4_poly_up_ifloor">
											<gml:exterior><gml:LinearRing>
												<gml:posList>90 0 3  90 8 3  100 8 3  100 0 3  90 0 3</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
						</nrg3:IntermediateFloorSurface>
					</nrg3:thermalBoundary>
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="B4_tb_up_wall_south">
							<gml:name>Upper zone wall south, opening ratio 0.3</gml:name>
							<nrg3:layeredConstruction xlink:href="#R_constr_envelope"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="B4_poly_up_wall_south">
											<gml:exterior><gml:LinearRing>
												<gml:posList>90 0 3  100 0 3  100 0 6  90 0 6  90 0 3</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
							<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0.3</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="B4_tb_up_wall_east">
							<gml:name>Upper zone wall east, opening ratio 0.15</gml:name>
							<nrg3:layeredConstruction xlink:href="#R_constr_envelope"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="B4_poly_up_wall_east">
											<gml:exterior><gml:LinearRing>
												<gml:posList>100 0 3  100 8 3  100 8 6  100 0 6  100 0 3</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
							<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0.15</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="B4_tb_up_wall_north">
							<gml:name>Upper zone wall north, opening ratio 0.1</gml:name>
							<nrg3:layeredConstruction xlink:href="#R_constr_envelope"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="B4_poly_up_wall_north">
											<gml:exterior><gml:LinearRing>
												<gml:posList>100 8 3  90 8 3  90 8 6  100 8 6  100 8 3</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
							<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0.1</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="B4_tb_up_wall_west">
							<gml:name>Upper zone wall west, opening ratio 0.15</gml:name>
							<nrg3:layeredConstruction xlink:href="#R_constr_envelope"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="B4_poly_up_wall_west">
											<gml:exterior><gml:LinearRing>
												<gml:posList>90 8 3  90 0 3  90 0 6  90 8 6  90 8 3</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
							<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0.15</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>
					<nrg3:thermalBoundary>
						<bldg:RoofSurface gml:id="B4_tb_up_roof">
							<gml:name>Upper zone roof</gml:name>
							<nrg3:layeredConstruction xlink:href="#R_constr_envelope"/>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface srsName="EPSG:28992" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="B4_poly_up_roof">
											<gml:exterior><gml:LinearRing>
												<gml:posList>90 0 6  100 0 6  100 8 6  90 8 6  90 0 6</gml:posList>
											</gml:LinearRing></gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
						</bldg:RoofSurface>
					</nrg3:thermalBoundary>
				</nrg3:ThermalZone>
			</nrg3:thermalZone>
		</bldg:Building>
	</core:cityObjectMember>

</core:CityModel>
