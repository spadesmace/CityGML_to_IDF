<?xml version="1.0" encoding="UTF-8"?>
<core:CityModel
    xmlns:core="http://www.opengis.net/citygml/2.0"
    xmlns:bldg="http://www.opengis.net/citygml/building/2.0"
    xmlns:gml="http://www.opengis.net/gml"
    xmlns:nrg3="http://www.citygml.org/ade/energy/3.0"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    gml:id="test_lod1_uvalue_citymodel">

  <!-- Synthetic parser fixture.
       Purpose: LoD1 single ThermalZone with an averaged construction expressed
       only as a whole-construction uValue. Parser should create Material:NoMass
       with thermal resistance R = 1 / U. -->

  <core:cityObjectMember>
    <nrg3:LayeredConstructionLibrary gml:id="test_lod1_uvalue_construction_library">
      <nrg3:libraryMember>
        <nrg3:LayeredConstruction gml:id="test_lod1_uvalue_construction">
          <gml:name>LoD1 averaged construction from U-value</gml:name>
          <nrg3:uValue uom="W/(m^2*K)">0.50</nrg3:uValue>
        </nrg3:LayeredConstruction>
      </nrg3:libraryMember>
    </nrg3:LayeredConstructionLibrary>
  </core:cityObjectMember>

  <core:cityObjectMember>
    <bldg:Building gml:id="test_lod1_uvalue_building">
      <gml:name>LoD1 U-value construction building</gml:name>
      <bldg:lod1Solid>
        <gml:Solid gml:id="test_lod1_uvalue_solid">
          <gml:exterior>
            <gml:CompositeSurface gml:id="test_lod1_uvalue_shell">
              <gml:surfaceMember><gml:Polygon gml:id="test_uvalue_floor"><gml:exterior><gml:LinearRing><gml:posList>0 0 0 0 10 0 10 10 0 10 0 0 0 0 0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon></gml:surfaceMember>
              <gml:surfaceMember><gml:Polygon gml:id="test_uvalue_wall_south"><gml:exterior><gml:LinearRing><gml:posList>0 0 0 10 0 0 10 0 10 0 0 10 0 0 0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon></gml:surfaceMember>
              <gml:surfaceMember><gml:Polygon gml:id="test_uvalue_wall_east"><gml:exterior><gml:LinearRing><gml:posList>10 0 0 10 10 0 10 10 10 10 0 10 10 0 0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon></gml:surfaceMember>
              <gml:surfaceMember><gml:Polygon gml:id="test_uvalue_wall_north"><gml:exterior><gml:LinearRing><gml:posList>10 10 0 0 10 0 0 10 10 10 10 10 10 10 0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon></gml:surfaceMember>
              <gml:surfaceMember><gml:Polygon gml:id="test_uvalue_wall_west"><gml:exterior><gml:LinearRing><gml:posList>0 10 0 0 0 0 0 0 10 0 10 10 0 10 0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon></gml:surfaceMember>
              <gml:surfaceMember><gml:Polygon gml:id="test_uvalue_roof"><gml:exterior><gml:LinearRing><gml:posList>0 0 10 10 0 10 10 10 10 0 10 10 0 0 10</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon></gml:surfaceMember>
            </gml:CompositeSurface>
          </gml:exterior>
        </gml:Solid>
      </bldg:lod1Solid>
      <nrg3:thermalZone>
        <nrg3:ThermalZone gml:id="test_lod1_uvalue_zone">
          <gml:name>Single LoD1 thermal zone with U-value construction</gml:name>
          <nrg3:layeredConstruction xlink:href="#test_lod1_uvalue_construction"/>
        </nrg3:ThermalZone>
      </nrg3:thermalZone>
    </bldg:Building>
  </core:cityObjectMember>
</core:CityModel>
