<?xml version="1.0" encoding="UTF-8"?>
<core:CityModel
    xmlns:core="http://www.opengis.net/citygml/2.0"
    xmlns:bldg="http://www.opengis.net/citygml/building/2.0"
    xmlns:gml="http://www.opengis.net/gml"
    xmlns:nrg3="http://www.citygml.org/ade/energy/3.0"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    gml:id="test_lod1_inline_citymodel">

  <!-- Synthetic parser fixture.
       Purpose: LoD1 single ThermalZone with a LayeredConstruction whose layers
       and materials are provided in CityGML, not Excel. -->

  <core:cityObjectMember>
    <nrg3:MaterialLibrary gml:id="test_lod1_material_library">
      <nrg3:libraryMember>
        <nrg3:SolidMaterial gml:id="test_lod1_solid_material_1">
          <gml:name>CityGML concrete layer</gml:name>
          <nrg3:thermalConductivity uom="W/(K*m)">1.4</nrg3:thermalConductivity>
          <nrg3:density uom="kg/m^3">2200</nrg3:density>
          <nrg3:specificHeatCapacity uom="J/(kg*K)">900</nrg3:specificHeatCapacity>
        </nrg3:SolidMaterial>
      </nrg3:libraryMember>
      <nrg3:libraryMember>
        <nrg3:SolidMaterial gml:id="test_lod1_solid_material_2">
          <gml:name>CityGML insulation layer</gml:name>
          <nrg3:thermalConductivity uom="W/(K*m)">0.04</nrg3:thermalConductivity>
          <nrg3:density uom="kg/m^3">35</nrg3:density>
          <nrg3:specificHeatCapacity uom="J/(kg*K)">1400</nrg3:specificHeatCapacity>
        </nrg3:SolidMaterial>
      </nrg3:libraryMember>
    </nrg3:MaterialLibrary>
  </core:cityObjectMember>

  <core:cityObjectMember>
    <nrg3:LayeredConstructionLibrary gml:id="test_lod1_inline_construction_library">
      <nrg3:libraryMember>
        <nrg3:LayeredConstruction gml:id="test_lod1_inline_construction">
          <gml:name>LoD1 averaged construction from inline layers</gml:name>
          <nrg3:layer>
            <nrg3:Layer gml:id="test_lod1_layer_1">
              <nrg3:thickness uom="m">0.20</nrg3:thickness>
              <nrg3:material xlink:href="#test_lod1_solid_material_1"/>
            </nrg3:Layer>
          </nrg3:layer>
          <nrg3:layer>
            <nrg3:Layer gml:id="test_lod1_layer_2">
              <nrg3:thickness uom="m">0.08</nrg3:thickness>
              <nrg3:material xlink:href="#test_lod1_solid_material_2"/>
            </nrg3:Layer>
          </nrg3:layer>
        </nrg3:LayeredConstruction>
      </nrg3:libraryMember>
    </nrg3:LayeredConstructionLibrary>
  </core:cityObjectMember>

  <core:cityObjectMember>
    <bldg:Building gml:id="test_lod1_inline_building">
      <gml:name>LoD1 inline-layer construction building</gml:name>
      <bldg:lod1Solid>
        <gml:Solid gml:id="test_lod1_inline_solid">
          <gml:exterior>
            <gml:CompositeSurface gml:id="test_lod1_inline_shell">
              <gml:surfaceMember><gml:Polygon gml:id="test_inline_floor"><gml:exterior><gml:LinearRing><gml:posList>0 0 0 0 10 0 10 10 0 10 0 0 0 0 0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon></gml:surfaceMember>
              <gml:surfaceMember><gml:Polygon gml:id="test_inline_wall_south"><gml:exterior><gml:LinearRing><gml:posList>0 0 0 10 0 0 10 0 10 0 0 10 0 0 0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon></gml:surfaceMember>
              <gml:surfaceMember><gml:Polygon gml:id="test_inline_wall_east"><gml:exterior><gml:LinearRing><gml:posList>10 0 0 10 10 0 10 10 10 10 0 10 10 0 0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon></gml:surfaceMember>
              <gml:surfaceMember><gml:Polygon gml:id="test_inline_wall_north"><gml:exterior><gml:LinearRing><gml:posList>10 10 0 0 10 0 0 10 10 10 10 10 10 10 0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon></gml:surfaceMember>
              <gml:surfaceMember><gml:Polygon gml:id="test_inline_wall_west"><gml:exterior><gml:LinearRing><gml:posList>0 10 0 0 0 0 0 0 10 0 10 10 0 10 0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon></gml:surfaceMember>
              <gml:surfaceMember><gml:Polygon gml:id="test_inline_roof"><gml:exterior><gml:LinearRing><gml:posList>0 0 10 10 0 10 10 10 10 0 10 10 0 0 10</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon></gml:surfaceMember>
            </gml:CompositeSurface>
          </gml:exterior>
        </gml:Solid>
      </bldg:lod1Solid>
      <nrg3:thermalZone>
        <nrg3:ThermalZone gml:id="test_lod1_inline_zone">
          <gml:name>Single LoD1 thermal zone with inline construction</gml:name>
          <nrg3:layeredConstruction xlink:href="#test_lod1_inline_construction"/>
        </nrg3:ThermalZone>
      </nrg3:thermalZone>
    </bldg:Building>
  </core:cityObjectMember>
</core:CityModel>
