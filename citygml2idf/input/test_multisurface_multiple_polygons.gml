<?xml version="1.0" encoding="UTF-8"?>
<core:CityModel
  xmlns:core="http://www.opengis.net/citygml/2.0"
  xmlns:bldg="http://www.opengis.net/citygml/building/2.0"
  xmlns:gml="http://www.opengis.net/gml"
  xmlns:nrg3="http://www.citygml.org/ade/energy/3.0"
  xmlns:xlink="http://www.w3.org/1999/xlink">
  <gml:name>MultiSurface multiple polygon parser fixture</gml:name>
  <gml:boundedBy>
    <gml:Envelope srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
      <gml:lowerCorner>0 0 0</gml:lowerCorner>
      <gml:upperCorner>10 10 10</gml:upperCorner>
    </gml:Envelope>
  </gml:boundedBy>
  <core:cityObjectMember>
    <bldg:Building gml:id="test_multisurface_building">
      <gml:name>MultiSurface split surface test building</gml:name>

      <bldg:boundedBy>
        <bldg:GroundSurface gml:id="test_multi_ground">
          <bldg:lod3MultiSurface>
            <gml:MultiSurface gml:id="test_multi_ground_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
              <gml:surfaceMember>
                <gml:Polygon gml:id="test_multi_ground_poly">
                  <gml:exterior><gml:LinearRing><gml:posList>0 0 0 10 0 0 10 10 0 0 10 0 0 0 0</gml:posList></gml:LinearRing></gml:exterior>
                </gml:Polygon>
              </gml:surfaceMember>
            </gml:MultiSurface>
          </bldg:lod3MultiSurface>
        </bldg:GroundSurface>
      </bldg:boundedBy>

      <bldg:boundedBy>
        <bldg:RoofSurface gml:id="test_multi_roof">
          <bldg:lod3MultiSurface>
            <gml:MultiSurface gml:id="test_multi_roof_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
              <gml:surfaceMember>
                <gml:Polygon gml:id="test_multi_roof_poly">
                  <gml:exterior><gml:LinearRing><gml:posList>0 0 10 0 10 10 10 10 10 10 0 10 0 0 10</gml:posList></gml:LinearRing></gml:exterior>
                </gml:Polygon>
              </gml:surfaceMember>
            </gml:MultiSurface>
          </bldg:lod3MultiSurface>
        </bldg:RoofSurface>
      </bldg:boundedBy>

      <bldg:boundedBy>
        <bldg:WallSurface gml:id="test_multi_wall_south">
          <gml:name>One BoundarySurface represented by two polygons</gml:name>
          <bldg:lod3MultiSurface>
            <gml:MultiSurface gml:id="test_multi_wall_south_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
              <gml:surfaceMember>
                <gml:Polygon gml:id="test_multi_wall_south_left_poly">
                  <gml:exterior><gml:LinearRing><gml:posList>0 0 0 5 0 0 5 0 10 0 0 10 0 0 0</gml:posList></gml:LinearRing></gml:exterior>
                </gml:Polygon>
              </gml:surfaceMember>
              <gml:surfaceMember>
                <gml:Polygon gml:id="test_multi_wall_south_right_poly">
                  <gml:exterior><gml:LinearRing><gml:posList>5 0 0 10 0 0 10 0 10 5 0 10 5 0 0</gml:posList></gml:LinearRing></gml:exterior>
                </gml:Polygon>
              </gml:surfaceMember>
            </gml:MultiSurface>
          </bldg:lod3MultiSurface>
        </bldg:WallSurface>
      </bldg:boundedBy>

      <bldg:boundedBy>
        <bldg:WallSurface gml:id="test_multi_wall_north">
          <bldg:lod3MultiSurface>
            <gml:MultiSurface gml:id="test_multi_wall_north_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
              <gml:surfaceMember>
                <gml:Polygon gml:id="test_multi_wall_north_poly">
                  <gml:exterior><gml:LinearRing><gml:posList>0 10 0 0 10 10 10 10 10 10 10 0 0 10 0</gml:posList></gml:LinearRing></gml:exterior>
                </gml:Polygon>
              </gml:surfaceMember>
            </gml:MultiSurface>
          </bldg:lod3MultiSurface>
        </bldg:WallSurface>
      </bldg:boundedBy>

      <bldg:boundedBy>
        <bldg:WallSurface gml:id="test_multi_wall_west">
          <bldg:lod3MultiSurface>
            <gml:MultiSurface gml:id="test_multi_wall_west_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
              <gml:surfaceMember>
                <gml:Polygon gml:id="test_multi_wall_west_poly">
                  <gml:exterior><gml:LinearRing><gml:posList>0 0 0 0 0 10 0 10 10 0 10 0 0 0 0</gml:posList></gml:LinearRing></gml:exterior>
                </gml:Polygon>
              </gml:surfaceMember>
            </gml:MultiSurface>
          </bldg:lod3MultiSurface>
        </bldg:WallSurface>
      </bldg:boundedBy>

      <bldg:boundedBy>
        <bldg:WallSurface gml:id="test_multi_wall_east">
          <bldg:lod3MultiSurface>
            <gml:MultiSurface gml:id="test_multi_wall_east_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
              <gml:surfaceMember>
                <gml:Polygon gml:id="test_multi_wall_east_poly">
                  <gml:exterior><gml:LinearRing><gml:posList>10 0 0 10 10 0 10 10 10 10 0 10 10 0 0</gml:posList></gml:LinearRing></gml:exterior>
                </gml:Polygon>
              </gml:surfaceMember>
            </gml:MultiSurface>
          </bldg:lod3MultiSurface>
        </bldg:WallSurface>
      </bldg:boundedBy>

      <nrg3:thermalZone>
        <nrg3:ThermalZone gml:id="test_multisurface_zone">
          <gml:name>MultiSurface coincident hull zone</gml:name>
          <nrg3:isCooled>true</nrg3:isCooled>
          <nrg3:isHeated>true</nrg3:isHeated>
          <nrg3:coincidesWithLod2Hull>false</nrg3:coincidesWithLod2Hull>
          <nrg3:coincidesWithLod3Hull>true</nrg3:coincidesWithLod3Hull>
        </nrg3:ThermalZone>
      </nrg3:thermalZone>
    </bldg:Building>
  </core:cityObjectMember>
</core:CityModel>
