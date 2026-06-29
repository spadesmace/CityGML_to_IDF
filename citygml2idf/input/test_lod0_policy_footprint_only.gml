<?xml version="1.0" encoding="UTF-8"?>
<core:CityModel
  xmlns:core="http://www.opengis.net/citygml/2.0"
  xmlns:bldg="http://www.opengis.net/citygml/building/2.0"
  xmlns:gml="http://www.opengis.net/gml"
  xmlns:nrg3="http://www.citygml.org/ade/energy/3.0">
  <gml:name>LoD0 footprint-only policy fixture</gml:name>
  <gml:boundedBy>
    <gml:Envelope srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
      <gml:lowerCorner>0 0 0</gml:lowerCorner>
      <gml:upperCorner>10 10 0</gml:upperCorner>
    </gml:Envelope>
  </gml:boundedBy>
  <core:cityObjectMember>
    <bldg:Building gml:id="test_lod0_policy_building">
      <gml:name>LoD0 footprint-only building</gml:name>
      <bldg:lod0FootPrint>
        <gml:MultiSurface gml:id="test_lod0_footprint_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
          <gml:surfaceMember>
            <gml:Polygon gml:id="test_lod0_footprint_poly">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList>0 0 0 10 0 0 10 10 0 0 10 0 0 0 0</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
        </gml:MultiSurface>
      </bldg:lod0FootPrint>
      <nrg3:thermalZone>
        <nrg3:ThermalZone gml:id="test_lod0_policy_zone">
          <gml:name>LoD0 thermal zone without geometry</gml:name>
          <nrg3:isCooled>true</nrg3:isCooled>
          <nrg3:isHeated>true</nrg3:isHeated>
          <nrg3:coincidesWithLod2Hull>false</nrg3:coincidesWithLod2Hull>
          <nrg3:coincidesWithLod3Hull>false</nrg3:coincidesWithLod3Hull>
        </nrg3:ThermalZone>
      </nrg3:thermalZone>
    </bldg:Building>
  </core:cityObjectMember>
</core:CityModel>
