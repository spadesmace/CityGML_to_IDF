<?xml version="1.0" encoding="UTF-8"?>
<core:CityModel
  xmlns:core="http://www.opengis.net/citygml/2.0"
  xmlns:bldg="http://www.opengis.net/citygml/building/2.0"
  xmlns:gml="http://www.opengis.net/gml"
  xmlns:nrg3="http://www.citygml.org/ade/energy/3.0"
  xmlns:xlink="http://www.w3.org/1999/xlink">
  <gml:name>LoD3 coincidesWithLod3Hull parser fixture, derived from Alderaan geometry patterns</gml:name>
  <gml:boundedBy>
    <gml:Envelope srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
      <gml:lowerCorner>0 0 0</gml:lowerCorner>
      <gml:upperCorner>10 10 10</gml:upperCorner>
    </gml:Envelope>
  </gml:boundedBy>

  <core:cityObjectMember>
    <bldg:Building gml:id="test_lod3_coincides_building">
      <gml:name>LoD3 coincident hull test building</gml:name>
      <bldg:boundedBy>
        <bldg:GroundSurface gml:id="test_lod3_ground">
          <gml:name>LoD3 ground hull surface</gml:name>
          <bldg:lod3MultiSurface>
            <gml:MultiSurface gml:id="test_lod3_ground_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
              <gml:surfaceMember>
                <gml:Polygon gml:id="test_lod3_ground_poly">
                  <gml:exterior>
                    <gml:LinearRing>
                      <gml:posList>0 0 0 10 0 0 10 10 0 0 10 0 0 0 0</gml:posList>
                    </gml:LinearRing>
                  </gml:exterior>
                </gml:Polygon>
              </gml:surfaceMember>
            </gml:MultiSurface>
          </bldg:lod3MultiSurface>
        </bldg:GroundSurface>
      </bldg:boundedBy>

      <bldg:boundedBy>
        <bldg:RoofSurface gml:id="test_lod3_roof">
          <gml:name>LoD3 roof hull surface</gml:name>
          <bldg:lod3MultiSurface>
            <gml:MultiSurface gml:id="test_lod3_roof_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
              <gml:surfaceMember>
                <gml:Polygon gml:id="test_lod3_roof_poly">
                  <gml:exterior>
                    <gml:LinearRing>
                      <gml:posList>0 0 10 0 10 10 10 10 10 10 0 10 0 0 10</gml:posList>
                    </gml:LinearRing>
                  </gml:exterior>
                </gml:Polygon>
              </gml:surfaceMember>
            </gml:MultiSurface>
          </bldg:lod3MultiSurface>
        </bldg:RoofSurface>
      </bldg:boundedBy>

      <bldg:boundedBy>
        <bldg:WallSurface gml:id="test_lod3_wall_south">
          <gml:name>LoD3 south wall with explicit opening</gml:name>
          <bldg:lod3MultiSurface>
            <gml:MultiSurface gml:id="test_lod3_wall_south_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
              <gml:surfaceMember>
                <gml:Polygon gml:id="test_lod3_wall_south_poly">
                  <gml:exterior>
                    <gml:LinearRing>
                      <gml:posList>0 0 0 10 0 0 10 0 10 0 0 10 0 0 0</gml:posList>
                    </gml:LinearRing>
                  </gml:exterior>
                  <gml:interior>
                    <gml:LinearRing>
                      <gml:posList>3 0 3 7 0 3 7 0 7 3 0 7 3 0 3</gml:posList>
                    </gml:LinearRing>
                  </gml:interior>
                </gml:Polygon>
              </gml:surfaceMember>
            </gml:MultiSurface>
          </bldg:lod3MultiSurface>
          <bldg:opening>
            <bldg:Window gml:id="test_lod3_window_south">
              <gml:name>LoD3 explicit hull window</gml:name>
              <bldg:lod3MultiSurface>
                <gml:MultiSurface gml:id="test_lod3_window_south_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
                  <gml:surfaceMember>
                    <gml:Polygon gml:id="test_lod3_window_south_poly">
                      <gml:exterior>
                        <gml:LinearRing>
                          <gml:posList>3 0 3 7 0 3 7 0 7 3 0 7 3 0 3</gml:posList>
                        </gml:LinearRing>
                      </gml:exterior>
                    </gml:Polygon>
                  </gml:surfaceMember>
                </gml:MultiSurface>
              </bldg:lod3MultiSurface>
            </bldg:Window>
          </bldg:opening>
        </bldg:WallSurface>
      </bldg:boundedBy>

      <bldg:boundedBy>
        <bldg:WallSurface gml:id="test_lod3_wall_north">
          <gml:name>LoD3 north wall hull surface</gml:name>
          <bldg:lod3MultiSurface>
            <gml:MultiSurface gml:id="test_lod3_wall_north_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
              <gml:surfaceMember>
                <gml:Polygon gml:id="test_lod3_wall_north_poly">
                  <gml:exterior>
                    <gml:LinearRing>
                      <gml:posList>0 10 0 0 10 10 10 10 10 10 10 0 0 10 0</gml:posList>
                    </gml:LinearRing>
                  </gml:exterior>
                </gml:Polygon>
              </gml:surfaceMember>
            </gml:MultiSurface>
          </bldg:lod3MultiSurface>
        </bldg:WallSurface>
      </bldg:boundedBy>

      <bldg:boundedBy>
        <bldg:WallSurface gml:id="test_lod3_wall_west">
          <gml:name>LoD3 west wall hull surface</gml:name>
          <bldg:lod3MultiSurface>
            <gml:MultiSurface gml:id="test_lod3_wall_west_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
              <gml:surfaceMember>
                <gml:Polygon gml:id="test_lod3_wall_west_poly">
                  <gml:exterior>
                    <gml:LinearRing>
                      <gml:posList>0 0 0 0 0 10 0 10 10 0 10 0 0 0 0</gml:posList>
                    </gml:LinearRing>
                  </gml:exterior>
                </gml:Polygon>
              </gml:surfaceMember>
            </gml:MultiSurface>
          </bldg:lod3MultiSurface>
        </bldg:WallSurface>
      </bldg:boundedBy>

      <bldg:boundedBy>
        <bldg:WallSurface gml:id="test_lod3_wall_east">
          <gml:name>LoD3 east wall hull surface</gml:name>
          <bldg:lod3MultiSurface>
            <gml:MultiSurface gml:id="test_lod3_wall_east_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
              <gml:surfaceMember>
                <gml:Polygon gml:id="test_lod3_wall_east_poly">
                  <gml:exterior>
                    <gml:LinearRing>
                      <gml:posList>10 0 0 10 10 0 10 10 10 10 0 10 10 0 0</gml:posList>
                    </gml:LinearRing>
                  </gml:exterior>
                </gml:Polygon>
              </gml:surfaceMember>
            </gml:MultiSurface>
          </bldg:lod3MultiSurface>
        </bldg:WallSurface>
      </bldg:boundedBy>

      <nrg3:thermalZone>
        <nrg3:ThermalZone gml:id="test_lod3_coincides_zone">
          <gml:name>LoD3 coincident hull thermal zone</gml:name>
          <nrg3:volume>
            <nrg3:QualifiedVolume>
              <nrg3:value uom="m^3">1000</nrg3:value>
              <nrg3:type>netVolume</nrg3:type>
            </nrg3:QualifiedVolume>
          </nrg3:volume>
          <nrg3:isCooled>true</nrg3:isCooled>
          <nrg3:isHeated>true</nrg3:isHeated>
          <nrg3:coincidesWithLod2Hull>false</nrg3:coincidesWithLod2Hull>
          <nrg3:coincidesWithLod3Hull>true</nrg3:coincidesWithLod3Hull>
        </nrg3:ThermalZone>
      </nrg3:thermalZone>
    </bldg:Building>
  </core:cityObjectMember>
</core:CityModel>
