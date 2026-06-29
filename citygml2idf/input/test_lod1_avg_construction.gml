<?xml version="1.0" encoding="UTF-8"?>
<core:CityModel
    xmlns:core="http://www.opengis.net/citygml/2.0"
    xmlns:bldg="http://www.opengis.net/citygml/building/2.0"
    xmlns:gml="http://www.opengis.net/gml"
    xmlns:nrg3="http://www.citygml.org/ade/energy/3.0"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    gml:id="test_lod1_avg_citymodel">

  <!-- Synthetic parser fixture, not an official Energy ADE sample.
       Purpose: test LoD1 solid geometry whose single ThermalZone carries one
       averaged LayeredConstruction for the whole zone hull. -->

  <core:cityObjectMember>
    <nrg3:LayeredConstructionLibrary gml:id="test_lod1_construction_library">
      <nrg3:libraryMember>
        <nrg3:LayeredConstruction gml:id="test_lod1_avg_construction">
          <gml:name>LoD1 averaged construction from Excel</gml:name>
          <nrg3:libraryCode codeSpace="layered_constr_library_codeSpace">layered_constr_library_code_2</nrg3:libraryCode>
        </nrg3:LayeredConstruction>
      </nrg3:libraryMember>
    </nrg3:LayeredConstructionLibrary>
  </core:cityObjectMember>

  <core:cityObjectMember>
    <bldg:Building gml:id="test_lod1_avg_building">
      <gml:name>LoD1 averaged construction building</gml:name>

      <bldg:lod1Solid>
        <gml:Solid gml:id="test_lod1_solid">
          <gml:exterior>
            <gml:CompositeSurface gml:id="test_lod1_shell">
              <gml:surfaceMember>
                <gml:Polygon gml:id="test_lod1_floor">
                  <gml:exterior>
                    <gml:LinearRing>
                      <gml:posList>0 0 0 0 10 0 10 10 0 10 0 0 0 0 0</gml:posList>
                    </gml:LinearRing>
                  </gml:exterior>
                </gml:Polygon>
              </gml:surfaceMember>
              <gml:surfaceMember>
                <gml:Polygon gml:id="test_lod1_wall_south">
                  <gml:exterior>
                    <gml:LinearRing>
                      <gml:posList>0 0 0 10 0 0 10 0 10 0 0 10 0 0 0</gml:posList>
                    </gml:LinearRing>
                  </gml:exterior>
                </gml:Polygon>
              </gml:surfaceMember>
              <gml:surfaceMember>
                <gml:Polygon gml:id="test_lod1_wall_east">
                  <gml:exterior>
                    <gml:LinearRing>
                      <gml:posList>10 0 0 10 10 0 10 10 10 10 0 10 10 0 0</gml:posList>
                    </gml:LinearRing>
                  </gml:exterior>
                </gml:Polygon>
              </gml:surfaceMember>
              <gml:surfaceMember>
                <gml:Polygon gml:id="test_lod1_wall_north">
                  <gml:exterior>
                    <gml:LinearRing>
                      <gml:posList>10 10 0 0 10 0 0 10 10 10 10 10 10 10 0</gml:posList>
                    </gml:LinearRing>
                  </gml:exterior>
                </gml:Polygon>
              </gml:surfaceMember>
              <gml:surfaceMember>
                <gml:Polygon gml:id="test_lod1_wall_west">
                  <gml:exterior>
                    <gml:LinearRing>
                      <gml:posList>0 10 0 0 0 0 0 0 10 0 10 10 0 10 0</gml:posList>
                    </gml:LinearRing>
                  </gml:exterior>
                </gml:Polygon>
              </gml:surfaceMember>
              <gml:surfaceMember>
                <gml:Polygon gml:id="test_lod1_roof">
                  <gml:exterior>
                    <gml:LinearRing>
                      <gml:posList>0 0 10 10 0 10 10 10 10 0 10 10 0 0 10</gml:posList>
                    </gml:LinearRing>
                  </gml:exterior>
                </gml:Polygon>
              </gml:surfaceMember>
            </gml:CompositeSurface>
          </gml:exterior>
        </gml:Solid>
      </bldg:lod1Solid>

      <nrg3:thermalZone>
        <nrg3:ThermalZone gml:id="test_lod1_zone">
          <gml:name>Single LoD1 thermal zone</gml:name>
          <nrg3:layeredConstruction xlink:href="#test_lod1_avg_construction"/>
        </nrg3:ThermalZone>
      </nrg3:thermalZone>
    </bldg:Building>
  </core:cityObjectMember>
</core:CityModel>
