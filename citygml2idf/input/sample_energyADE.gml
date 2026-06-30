<?xml version="1.0" encoding="UTF-8"?>
<!--
  Sample CityGML 2.0 + Energy ADE 3.0 (beta 7) dataset - EXTENDED coverage.
    Building_B1  - LOD1 block (rectangular)
    Building_B2  - LOD2, L-shaped footprint (6 walls), flat roof
    Building_B3  - LOD3, gabled roof (two tilted RoofSurfaces), openings,
                   TWO thermal zones, maximal Energy ADE
  Plus 3 ADE libraries (Material / LayeredConstruction / Schedule),
  one WeatherStation and one UrbanFunctionArea group.
  Goal: every concrete Energy ADE field is used at least once
        (verify with: python3 ade_coverage.py).
  CRS: EPSG:25832 (ETRS89 / UTM 32N); coords = Easting Northing Height [m].
-->
<core:CityModel
    xmlns:core="http://www.opengis.net/citygml/2.0"
    xmlns:bldg="http://www.opengis.net/citygml/building/2.0"
    xmlns:grp="http://www.opengis.net/citygml/cityobjectgroup/2.0"
    xmlns:gml="http://www.opengis.net/gml"
    xmlns:nrg3="http://www.citygml.org/ade/energy/3.0"
    xmlns:gen="http://www.opengis.net/citygml/generics/2.0"
    xmlns:xAL="urn:oasis:names:tc:ciq:xsdschema:xAL:2.0"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.citygml.org/ade/energy/3.0 ../../citygml_ade_schemas/ade/Energy_ADE_3.0_beta7.xsd
                        http://www.opengis.net/citygml/2.0 http://schemas.opengis.net/citygml/2.0/cityGMLBase.xsd
                        http://www.opengis.net/citygml/building/2.0 http://schemas.opengis.net/citygml/building/2.0/building.xsd
                        http://www.opengis.net/citygml/cityobjectgroup/2.0 http://schemas.opengis.net/citygml/cityobjectgroup/2.0/cityObjectGroup.xsd">

  <gml:name>Energy ADE 3.0 sample - full field coverage</gml:name>
  <gml:boundedBy>
    <gml:Envelope srsName="urn:ogc:def:crs:EPSG::25832" srsDimension="3">
      <gml:lowerCorner>691000 5334500 -2.5</gml:lowerCorner>
      <gml:upperCorner>691052 5334510 8</gml:upperCorner>
    </gml:Envelope>
  </gml:boundedBy>

  <!-- ============================================================= -->
  <!-- BUILDING B1 - LOD1 block                                      -->
  <!-- ============================================================= -->
  <core:cityObjectMember>
    <bldg:Building gml:id="Building_B1">
      <gml:description>Single-family detached house, LOD1 block model.</gml:description>
      <gml:name>Residential House B1</gml:name>
      <core:creationDate>2024-01-15</core:creationDate>
      <core:relativeToTerrain>entirelyAboveTerrain</core:relativeToTerrain>
      <!-- CityObject-level ADE: a relation to B2 and a water-resource record -->
      <nrg3:relatedTo>
        <nrg3:CityObjectRelation>
          <nrg3:relationType codeSpace="../../citygml_ade_schemas/ade/codelists/RelationTypeValue.xml">sharedWall</nrg3:relationType>
          <nrg3:relatedTo xlink:href="#Building_B2"/>
        </nrg3:CityObjectRelation>
      </nrg3:relatedTo>
      <nrg3:resource>
        <nrg3:Water gml:id="B1_Water">
          <nrg3:status>actual</nrg3:status>
          <nrg3:operationType codeSpace="../../citygml_ade_schemas/ade/codelists/ResourceOperationTypeValue.xml">demand</nrg3:operationType>
          <nrg3:amountType codeSpace="../../citygml_ade_schemas/ade/codelists/VolumeTypeValue.xml">netVolume</nrg3:amountType>
          <nrg3:year>2023</nrg3:year>
          <nrg3:amount uom="m3">95.0</nrg3:amount>
          <nrg3:isAmountNormalized>false</nrg3:isAmountNormalized>
          <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/WaterTypeValue.xml">drinkingWater</nrg3:type>
          <nrg3:endUse codeSpace="../../citygml_ade_schemas/ade/codelists/WaterEndUseValue.xml">domestic</nrg3:endUse>
        </nrg3:Water>
      </nrg3:resource>
      <bldg:class codeSpace="http://www.sig3d.org/codelists/standard/building/2.0/_AbstractBuilding_class.xml">1000</bldg:class>
      <bldg:function codeSpace="http://www.sig3d.org/codelists/standard/building/2.0/_AbstractBuilding_function.xml">1000</bldg:function>
      <bldg:usage codeSpace="http://www.sig3d.org/codelists/standard/building/2.0/_AbstractBuilding_usage.xml">1000</bldg:usage>
      <bldg:yearOfConstruction>1985</bldg:yearOfConstruction>
      <bldg:roofType codeSpace="http://www.sig3d.org/codelists/standard/building/2.0/_AbstractBuilding_roofType.xml">1000</bldg:roofType>
      <bldg:measuredHeight uom="m">6.0</bldg:measuredHeight>
      <bldg:storeysAboveGround>2</bldg:storeysAboveGround>
      <bldg:storeysBelowGround>0</bldg:storeysBelowGround>
      <bldg:lod1Solid>
        <gml:Solid srsName="urn:ogc:def:crs:EPSG::25832">
          <gml:exterior>
            <gml:CompositeSurface>
              <gml:surfaceMember><gml:Polygon gml:id="b1_ground"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691000 5334500 0 691000 5334508 0 691010 5334508 0 691010 5334500 0 691000 5334500 0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon></gml:surfaceMember>
              <gml:surfaceMember><gml:Polygon gml:id="b1_roof"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691000 5334500 6 691010 5334500 6 691010 5334508 6 691000 5334508 6 691000 5334500 6</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon></gml:surfaceMember>
              <gml:surfaceMember><gml:Polygon gml:id="b1_south"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691000 5334500 0 691010 5334500 0 691010 5334500 6 691000 5334500 6 691000 5334500 0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon></gml:surfaceMember>
              <gml:surfaceMember><gml:Polygon gml:id="b1_east"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691010 5334500 0 691010 5334508 0 691010 5334508 6 691010 5334500 6 691010 5334500 0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon></gml:surfaceMember>
              <gml:surfaceMember><gml:Polygon gml:id="b1_north"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691010 5334508 0 691000 5334508 0 691000 5334508 6 691010 5334508 6 691010 5334508 0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon></gml:surfaceMember>
              <gml:surfaceMember><gml:Polygon gml:id="b1_west"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691000 5334508 0 691000 5334500 0 691000 5334500 6 691000 5334508 6 691000 5334508 0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon></gml:surfaceMember>
            </gml:CompositeSurface>
          </gml:exterior>
        </gml:Solid>
      </bldg:lod1Solid>
      <nrg3:bdgType codeSpace="../../citygml_ade_schemas/ade/codelists/BuildingTypeValue.xml">single-family house</nrg3:bdgType>
      <nrg3:bdgConstructionWeight codeSpace="../../citygml_ade_schemas/ade/codelists/ConstructionWeightValue.xml">medium</nrg3:bdgConstructionWeight>
      <nrg3:bdgArea>
        <nrg3:QualifiedArea>
          <nrg3:description>Energy reference area from cadastre</nrg3:description>
          <nrg3:source>cadastre</nrg3:source>
          <nrg3:value uom="m2">148.0</nrg3:value>
          <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/AreaTypeValue.xml">energyReferenceArea</nrg3:type>
        </nrg3:QualifiedArea>
      </nrg3:bdgArea>
      <nrg3:bdgHeight>
        <nrg3:QualifiedHeight>
          <nrg3:value uom="m">6.0</nrg3:value>
          <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/HeightTypeValue.xml">generalRoof</nrg3:type>
        </nrg3:QualifiedHeight>
      </nrg3:bdgHeight>
      <nrg3:energyPerformanceCertificate>
        <nrg3:EnergyPerformanceCertificate>
          <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/EnergyPerformanceCertificateTypeValue.xml">nationalScheme</nrg3:type>
          <nrg3:label>C</nrg3:label>
          <nrg3:value uom="kWh/m2/a">95.0</nrg3:value>
          <nrg3:issueDate>2020-06-01</nrg3:issueDate>
        </nrg3:EnergyPerformanceCertificate>
      </nrg3:energyPerformanceCertificate>
    </bldg:Building>
  </core:cityObjectMember>

  <!-- ============================================================= -->
  <!-- BUILDING B2 - LOD2, L-shaped footprint (6 walls), flat roof   -->
  <!-- ============================================================= -->
  <core:cityObjectMember>
    <bldg:Building gml:id="Building_B2">
      <gml:description>Multi-family house, LOD2, L-shaped plan with six walls.</gml:description>
      <gml:name>Apartment Building B2</gml:name>
      <core:creationDate>2024-01-15</core:creationDate>
      <core:relativeToTerrain>entirelyAboveTerrain</core:relativeToTerrain>
      <!-- CityObject-level ADE: heating + auxiliary devices -->
      <nrg3:device>
        <nrg3:Boiler gml:id="B2_Boiler">
          <nrg3:model>CondensingGasBoiler-24kW</nrg3:model>
          <nrg3:yearOfManufacture>2018</nrg3:yearOfManufacture>
          <nrg3:numberOfDevices>1</nrg3:numberOfDevices>
          <nrg3:installedPower uom="kW">24.0</nrg3:installedPower>
          <nrg3:nominalEfficiency uom="ratio">0.94</nrg3:nominalEfficiency>
          <nrg3:hasCondensation>true</nrg3:hasCondensation>
        </nrg3:Boiler>
      </nrg3:device>
      <nrg3:device>
        <nrg3:GenericDevice gml:id="B2_Server">
          <nrg3:model>RackServer</nrg3:model>
          <nrg3:installedPower uom="kW">1.5</nrg3:installedPower>
          <nrg3:efficiencyIndicator>A++</nrg3:efficiencyIndicator>
          <nrg3:heatDissipation uom="W">800.0</nrg3:heatDissipation>
          <nrg3:heatDissipationConvectiveFraction uom="ratio">0.7</nrg3:heatDissipationConvectiveFraction>
          <nrg3:heatDissipationLatentFraction uom="ratio">0.0</nrg3:heatDissipationLatentFraction>
          <nrg3:heatDissipationRadiantFraction uom="ratio">0.3</nrg3:heatDissipationRadiantFraction>
        </nrg3:GenericDevice>
      </nrg3:device>
      <nrg3:device>
        <nrg3:GenericElectricalDevice gml:id="B2_Elevator">
          <nrg3:model>Elevator-4kW</nrg3:model>
          <nrg3:installedPower uom="kW">4.0</nrg3:installedPower>
        </nrg3:GenericElectricalDevice>
      </nrg3:device>
      <nrg3:device>
        <nrg3:LightingDevice gml:id="B2_Lighting">
          <nrg3:model>LED-stairwell</nrg3:model>
          <nrg3:installedPower uom="kW">0.6</nrg3:installedPower>
        </nrg3:LightingDevice>
      </nrg3:device>
      <nrg3:device>
        <nrg3:MovableShadingDevice gml:id="B2_Blinds">
          <nrg3:model>ExternalVenetianBlinds</nrg3:model>
          <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/ShadingDeviceTypeValue.xml">venetianBlind</nrg3:type>
          <nrg3:installationSide>outside</nrg3:installationSide>
          <nrg3:maximumCoverRatio uom="ratio">0.9</nrg3:maximumCoverRatio>
          <nrg3:transmittance>
            <nrg3:Transmittance>
              <nrg3:fraction uom="ratio">0.15</nrg3:fraction>
              <nrg3:wavelengthRange>solar</nrg3:wavelengthRange>
            </nrg3:Transmittance>
          </nrg3:transmittance>
        </nrg3:MovableShadingDevice>
      </nrg3:device>
      <!-- CityObject-level ADE: resources -->
      <nrg3:resource>
        <nrg3:ConstructionMaterial gml:id="B2_ConstrMat">
          <nrg3:status>actual</nrg3:status>
          <nrg3:operationType codeSpace="../../citygml_ade_schemas/ade/codelists/ResourceOperationTypeValue.xml">embodied</nrg3:operationType>
          <nrg3:amountType codeSpace="../../citygml_ade_schemas/ade/codelists/EnergyTypeValue.xml">mass</nrg3:amountType>
          <nrg3:amount uom="kg">85000.0</nrg3:amount>
          <nrg3:isAmountNormalized>false</nrg3:isAmountNormalized>
          <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/ContructionMaterialTypeValue.xml">concrete</nrg3:type>
          <nrg3:endUse codeSpace="../../citygml_ade_schemas/ade/codelists/ConstructionMaterialEndUseValue.xml">structure</nrg3:endUse>
        </nrg3:ConstructionMaterial>
      </nrg3:resource>
      <nrg3:resource>
        <nrg3:Waste gml:id="B2_Waste">
          <nrg3:status>actual</nrg3:status>
          <nrg3:operationType codeSpace="../../citygml_ade_schemas/ade/codelists/ResourceOperationTypeValue.xml">production</nrg3:operationType>
          <nrg3:amountType codeSpace="../../citygml_ade_schemas/ade/codelists/EnergyTypeValue.xml">mass</nrg3:amountType>
          <nrg3:amount uom="kg">3200.0</nrg3:amount>
          <nrg3:isAmountNormalized>false</nrg3:isAmountNormalized>
          <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/WasteTypeValue.xml">municipalSolidWaste</nrg3:type>
          <nrg3:endUse codeSpace="../../citygml_ade_schemas/ade/codelists/WasteEndUseValue.xml">disposal</nrg3:endUse>
          <nrg3:isDangerous>false</nrg3:isDangerous>
          <nrg3:isRecyclable>true</nrg3:isRecyclable>
        </nrg3:Waste>
      </nrg3:resource>
      <nrg3:resource>
        <nrg3:Food gml:id="B2_Food">
          <nrg3:status>actual</nrg3:status>
          <nrg3:operationType codeSpace="../../citygml_ade_schemas/ade/codelists/ResourceOperationTypeValue.xml">consumption</nrg3:operationType>
          <nrg3:amountType codeSpace="../../citygml_ade_schemas/ade/codelists/EnergyTypeValue.xml">mass</nrg3:amountType>
          <nrg3:amount uom="kg">5400.0</nrg3:amount>
          <nrg3:isAmountNormalized>false</nrg3:isAmountNormalized>
          <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/FoodTypeValue.xml">mixed</nrg3:type>
          <nrg3:endUse codeSpace="../../citygml_ade_schemas/ade/codelists/FoodEndUseValue.xml">nutrition</nrg3:endUse>
        </nrg3:Food>
      </nrg3:resource>
      <!-- CityObject-level ADE: weather attached to building (typical values series) -->
      <nrg3:weatherData>
        <nrg3:WeatherData gml:id="B2_Weather">
          <nrg3:libraryCode>TRY-2015-region12</nrg3:libraryCode>
          <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/WeatherDataTypeValue.xml">airTemperature</nrg3:type>
          <nrg3:valueType codeSpace="../../citygml_ade_schemas/ade/codelists/WeatherValueTypeValue.xml">typical</nrg3:valueType>
          <nrg3:yearlyValue uom="Cel">10.0</nrg3:yearlyValue>
          <nrg3:timeDependentValues>
            <nrg3:TypicalValuesTimeSeries gml:id="B2_TempTVS">
              <nrg3:acquisitionMethod codeSpace="../../citygml_ade_schemas/ade/codelists/AcquisitionMethodValue.xml">simulation</nrg3:acquisitionMethod>
              <nrg3:interpolationType>continuous</nrg3:interpolationType>
              <nrg3:startTime>00:00:00</nrg3:startTime>
              <nrg3:startDay>1</nrg3:startDay>
              <nrg3:startMonth>1</nrg3:startMonth>
              <nrg3:temporalExtent unit="day">1</nrg3:temporalExtent>
              <nrg3:timeInterval unit="hour">6</nrg3:timeInterval>
              <nrg3:valuesList uom="Cel">2.0 6.0 9.0 4.0</nrg3:valuesList>
            </nrg3:TypicalValuesTimeSeries>
          </nrg3:timeDependentValues>
        </nrg3:WeatherData>
      </nrg3:weatherData>
      <bldg:class codeSpace="http://www.sig3d.org/codelists/standard/building/2.0/_AbstractBuilding_class.xml">1000</bldg:class>
      <bldg:function codeSpace="http://www.sig3d.org/codelists/standard/building/2.0/_AbstractBuilding_function.xml">1000</bldg:function>
      <bldg:yearOfConstruction>2005</bldg:yearOfConstruction>
      <bldg:roofType codeSpace="http://www.sig3d.org/codelists/standard/building/2.0/_AbstractBuilding_roofType.xml">1000</bldg:roofType>
      <bldg:measuredHeight uom="m">7.0</bldg:measuredHeight>
      <bldg:storeysAboveGround>3</bldg:storeysAboveGround>
      <!-- LOD2 closed solid (ground + 6 walls + roof), referencing the surfaces below -->
      <bldg:lod2Solid>
        <gml:Solid srsName="urn:ogc:def:crs:EPSG::25832">
          <gml:exterior>
            <gml:CompositeSurface>
              <gml:surfaceMember xlink:href="#b2_ground"/>
              <gml:surfaceMember xlink:href="#b2_w1"/>
              <gml:surfaceMember xlink:href="#b2_w2"/>
              <gml:surfaceMember xlink:href="#b2_w3"/>
              <gml:surfaceMember xlink:href="#b2_w4"/>
              <gml:surfaceMember xlink:href="#b2_w5"/>
              <gml:surfaceMember xlink:href="#b2_w6"/>
              <gml:surfaceMember xlink:href="#b2_roof"/>
            </gml:CompositeSurface>
          </gml:exterior>
        </gml:Solid>
      </bldg:lod2Solid>
      <bldg:boundedBy>
        <bldg:GroundSurface gml:id="B2_GroundSurface">
          <bldg:lod2MultiSurface><gml:MultiSurface><gml:surfaceMember>
            <gml:Polygon gml:id="b2_ground"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691020 5334500 0 691020 5334509 0 691027 5334509 0 691027 5334505 0 691032 5334505 0 691032 5334500 0 691020 5334500 0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
          </gml:surfaceMember></gml:MultiSurface></bldg:lod2MultiSurface>
        </bldg:GroundSurface>
      </bldg:boundedBy>
      <bldg:boundedBy>
        <bldg:WallSurface gml:id="B2_Wall1">
          <bldg:lod2MultiSurface><gml:MultiSurface><gml:surfaceMember>
            <gml:Polygon gml:id="b2_w1"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691020 5334500 0 691032 5334500 0 691032 5334500 7 691020 5334500 7 691020 5334500 0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
          </gml:surfaceMember></gml:MultiSurface></bldg:lod2MultiSurface>
          <nrg3:bdgBdrySurfAzimuth uom="deg">180.0</nrg3:bdgBdrySurfAzimuth>
          <nrg3:bdgBdrySurfInclination uom="deg">90.0</nrg3:bdgBdrySurfInclination>
        </bldg:WallSurface>
      </bldg:boundedBy>
      <bldg:boundedBy>
        <bldg:WallSurface gml:id="B2_Wall2">
          <bldg:lod2MultiSurface><gml:MultiSurface><gml:surfaceMember>
            <gml:Polygon gml:id="b2_w2"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691032 5334500 0 691032 5334505 0 691032 5334505 7 691032 5334500 7 691032 5334500 0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
          </gml:surfaceMember></gml:MultiSurface></bldg:lod2MultiSurface>
          <nrg3:bdgBdrySurfAzimuth uom="deg">90.0</nrg3:bdgBdrySurfAzimuth>
        </bldg:WallSurface>
      </bldg:boundedBy>
      <bldg:boundedBy>
        <bldg:WallSurface gml:id="B2_Wall3">
          <bldg:lod2MultiSurface><gml:MultiSurface><gml:surfaceMember>
            <gml:Polygon gml:id="b2_w3"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691032 5334505 0 691027 5334505 0 691027 5334505 7 691032 5334505 7 691032 5334505 0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
          </gml:surfaceMember></gml:MultiSurface></bldg:lod2MultiSurface>
          <nrg3:bdgBdrySurfAzimuth uom="deg">0.0</nrg3:bdgBdrySurfAzimuth>
        </bldg:WallSurface>
      </bldg:boundedBy>
      <bldg:boundedBy>
        <bldg:WallSurface gml:id="B2_Wall4">
          <bldg:lod2MultiSurface><gml:MultiSurface><gml:surfaceMember>
            <gml:Polygon gml:id="b2_w4"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691027 5334505 0 691027 5334509 0 691027 5334509 7 691027 5334505 7 691027 5334505 0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
          </gml:surfaceMember></gml:MultiSurface></bldg:lod2MultiSurface>
          <nrg3:bdgBdrySurfAzimuth uom="deg">90.0</nrg3:bdgBdrySurfAzimuth>
        </bldg:WallSurface>
      </bldg:boundedBy>
      <bldg:boundedBy>
        <bldg:WallSurface gml:id="B2_Wall5">
          <bldg:lod2MultiSurface><gml:MultiSurface><gml:surfaceMember>
            <gml:Polygon gml:id="b2_w5"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691027 5334509 0 691020 5334509 0 691020 5334509 7 691027 5334509 7 691027 5334509 0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
          </gml:surfaceMember></gml:MultiSurface></bldg:lod2MultiSurface>
          <nrg3:bdgBdrySurfAzimuth uom="deg">0.0</nrg3:bdgBdrySurfAzimuth>
        </bldg:WallSurface>
      </bldg:boundedBy>
      <bldg:boundedBy>
        <bldg:WallSurface gml:id="B2_Wall6">
          <bldg:lod2MultiSurface><gml:MultiSurface><gml:surfaceMember>
            <gml:Polygon gml:id="b2_w6"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691020 5334509 0 691020 5334500 0 691020 5334500 7 691020 5334509 7 691020 5334509 0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
          </gml:surfaceMember></gml:MultiSurface></bldg:lod2MultiSurface>
          <nrg3:bdgBdrySurfAzimuth uom="deg">270.0</nrg3:bdgBdrySurfAzimuth>
        </bldg:WallSurface>
      </bldg:boundedBy>
      <bldg:boundedBy>
        <bldg:RoofSurface gml:id="B2_RoofSurface">
          <bldg:lod2MultiSurface><gml:MultiSurface><gml:surfaceMember>
            <gml:Polygon gml:id="b2_roof"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691020 5334500 7 691032 5334500 7 691032 5334505 7 691027 5334505 7 691027 5334509 7 691020 5334509 7 691020 5334500 7</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
          </gml:surfaceMember></gml:MultiSurface></bldg:lod2MultiSurface>
          <nrg3:bdgBdrySurfInclination uom="deg">0.0</nrg3:bdgBdrySurfInclination>
          <nrg3:bdgBdrySurfSkyViewFactor uom="ratio">0.9</nrg3:bdgBdrySurfSkyViewFactor>
        </bldg:RoofSurface>
      </bldg:boundedBy>
      <nrg3:bdgType codeSpace="../../citygml_ade_schemas/ade/codelists/BuildingTypeValue.xml">multi-family house</nrg3:bdgType>
      <nrg3:bdgConstructionWeight codeSpace="../../citygml_ade_schemas/ade/codelists/ConstructionWeightValue.xml">heavy</nrg3:bdgConstructionWeight>
      <nrg3:bdgArea>
        <nrg3:QualifiedArea>
          <nrg3:value uom="m2">324.0</nrg3:value>
          <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/AreaTypeValue.xml">energyReferenceArea</nrg3:type>
        </nrg3:QualifiedArea>
      </nrg3:bdgArea>
      <nrg3:bdgVolume>
        <nrg3:QualifiedVolume>
          <nrg3:value uom="m3">756.0</nrg3:value>
          <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/VolumeTypeValue.xml">grossVolume</nrg3:type>
        </nrg3:QualifiedVolume>
      </nrg3:bdgVolume>
      <nrg3:thermalZone>
        <nrg3:ThermalZone gml:id="B2_ThermalZone">
          <nrg3:volume>
            <nrg3:QualifiedVolume>
              <nrg3:value uom="m3">680.0</nrg3:value>
              <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/VolumeTypeValue.xml">heatedVolume</nrg3:type>
            </nrg3:QualifiedVolume>
          </nrg3:volume>
          <nrg3:heatCapacity uom="J/K">1.2E8</nrg3:heatCapacity>
          <nrg3:infiltrationRate uom="1/h">0.5</nrg3:infiltrationRate>
          <nrg3:isCooled>false</nrg3:isCooled>
          <nrg3:isHeated>true</nrg3:isHeated>
          <nrg3:coincidesWithLod2Hull>true</nrg3:coincidesWithLod2Hull>
          <nrg3:coincidesWithLod3Hull>false</nrg3:coincidesWithLod3Hull>
          <nrg3:thermalBoundary xlink:href="#B2_Wall1"/>
          <nrg3:thermalBoundary xlink:href="#B2_RoofSurface"/>
          <nrg3:thermalBoundary xlink:href="#B2_GroundSurface"/>
        </nrg3:ThermalZone>
      </nrg3:thermalZone>
      <nrg3:usageZone>
        <nrg3:UsageZone gml:id="B2_UsageZone">
          <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/CurrentUseValue.xml">residential</nrg3:type>
          <nrg3:isPrimary>true</nrg3:isPrimary>
          <nrg3:internalHeatGains uom="W">450.0</nrg3:internalHeatGains>
          <nrg3:internalHeatGainsConvectiveFraction uom="ratio">0.5</nrg3:internalHeatGainsConvectiveFraction>
          <nrg3:internalHeatGainsLatentFraction uom="ratio">0.1</nrg3:internalHeatGainsLatentFraction>
          <nrg3:internalHeatGainsRadiantFraction uom="ratio">0.4</nrg3:internalHeatGainsRadiantFraction>
          <nrg3:coolingSchedule xlink:href="#LIB_DualCooling"/>
          <nrg3:heatingSchedule>
            <nrg3:DualValueSchedule gml:id="B2_HeatingSchedule">
              <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/ScheduleTypeValue.xml">typicalDay</nrg3:type>
              <nrg3:idleValue uom="Cel">17.0</nrg3:idleValue>
              <nrg3:usageValue uom="Cel">21.0</nrg3:usageValue>
              <nrg3:startUsageTime>06:00:00</nrg3:startUsageTime>
              <nrg3:endUsageTime>22:00:00</nrg3:endUsageTime>
            </nrg3:DualValueSchedule>
          </nrg3:heatingSchedule>
          <nrg3:ventilationSchedule xlink:href="#LIB_DualCooling"/>
        </nrg3:UsageZone>
      </nrg3:usageZone>
    </bldg:Building>
  </core:cityObjectMember>

  <!-- ============================================================= -->
  <!-- BUILDING B3 - LOD3 gabled roof, TWO thermal zones, full ADE   -->
  <!-- ============================================================= -->
  <core:cityObjectMember>
    <bldg:Building gml:id="Building_B3">
      <gml:description>Office building, LOD3 gabled roof, windows + door, two thermal zones.</gml:description>
      <gml:name>Office Building B3</gml:name>
      <core:creationDate>2024-01-15</core:creationDate>
      <core:externalReference>
        <core:informationSystem>https://example.org/cadastre</core:informationSystem>
        <core:externalObject><core:name>DE-BY-09162-B3</core:name></core:externalObject>
      </core:externalReference>
      <core:relativeToTerrain>entirelyAboveTerrain</core:relativeToTerrain>
      <!-- ===== CityObject-level Energy ADE ===== -->
      <nrg3:relatedTo>
        <nrg3:CityObjectRelation>
          <nrg3:relationType codeSpace="../../citygml_ade_schemas/ade/codelists/RelationTypeValue.xml">neighbour</nrg3:relationType>
          <nrg3:relatedTo xlink:href="#Building_B2"/>
        </nrg3:CityObjectRelation>
      </nrg3:relatedTo>
      <nrg3:weatherData>
        <nrg3:WeatherData gml:id="B3_OutdoorTemp">
          <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/WeatherDataTypeValue.xml">airTemperature</nrg3:type>
          <nrg3:valueType codeSpace="../../citygml_ade_schemas/ade/codelists/WeatherValueTypeValue.xml">measured</nrg3:valueType>
          <nrg3:yearlyValue uom="Cel">10.4</nrg3:yearlyValue>
          <nrg3:position>
            <gml:Point srsName="urn:ogc:def:crs:EPSG::25832" srsDimension="3"><gml:pos>691046 5334505 9</gml:pos></gml:Point>
          </nrg3:position>
        </nrg3:WeatherData>
      </nrg3:weatherData>
      <nrg3:utilityNetworkConnection>
        <nrg3:UtilityNetworkConnection gml:id="B3_DistrictHeat">
          <nrg3:networkType codeSpace="../../citygml_ade_schemas/ade/codelists/NetworkTypeValue.xml">districtHeating</nrg3:networkType>
          <nrg3:connectionStatus>connected</nrg3:connectionStatus>
          <nrg3:functionInNetwork codeSpace="../../citygml_ade_schemas/ade/codelists/FunctionInNetworkValue.xml">consuming</nrg3:functionInNetwork>
          <nrg3:usageInNetwork codeSpace="../../citygml_ade_schemas/ade/codelists/FunctionInNetworkValue.xml">consuming</nrg3:usageInNetwork>
          <nrg3:networkID>DH-MUC-07</nrg3:networkID>
          <nrg3:networkNodeID>node-4521</nrg3:networkNodeID>
        </nrg3:UtilityNetworkConnection>
      </nrg3:utilityNetworkConnection>
      <nrg3:suitability>
        <nrg3:Suitability>
          <nrg3:reason codeSpace="../../citygml_ade_schemas/ade/codelists/SuitabilityReasonValue.xml">solarPotential</nrg3:reason>
          <nrg3:description>South-facing roof, low shading, suitable for PV.</nrg3:description>
          <nrg3:value uom="ratio">0.85</nrg3:value>
          <nrg3:schedule xlink:href="#LIB_DualCooling"/>
        </nrg3:Suitability>
      </nrg3:suitability>
      <nrg3:referencePoint>
        <gml:Point srsName="urn:ogc:def:crs:EPSG::25832" srsDimension="3"><gml:pos>691046 5334505 0</gml:pos></gml:Point>
      </nrg3:referencePoint>
      <!-- Devices: full plant -->
      <nrg3:device>
        <nrg3:HeatPump gml:id="B3_HeatPump">
          <nrg3:model>AirWaterHP-12kW</nrg3:model>
          <nrg3:installedPower uom="kW">12.0</nrg3:installedPower>
          <nrg3:nominalEfficiency uom="ratio">3.8</nrg3:nominalEfficiency>
          <nrg3:deviceOperation>
            <nrg3:DeviceOperation gml:id="B3_HPOp">
              <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/DeviceOperationTypeValue.xml">heating</nrg3:type>
              <nrg3:yearlyGlobalEfficiency>3.6</nrg3:yearlyGlobalEfficiency>
              <nrg3:schedule xlink:href="#LIB_DualCooling"/>
            </nrg3:DeviceOperation>
          </nrg3:deviceOperation>
          <nrg3:heatSource codeSpace="../../citygml_ade_schemas/ade/codelists/HeatSourceTypeValue.xml">ambientAir</nrg3:heatSource>
          <nrg3:copSourceTemperature uom="Cel">7.0</nrg3:copSourceTemperature>
          <nrg3:copOperationTemperature uom="Cel">35.0</nrg3:copOperationTemperature>
        </nrg3:HeatPump>
      </nrg3:device>
      <nrg3:device>
        <nrg3:Boiler gml:id="B3_Boiler">
          <nrg3:model>CondensingGasBoiler-40kW</nrg3:model>
          <nrg3:installedPower uom="kW">40.0</nrg3:installedPower>
          <nrg3:hasCondensation>true</nrg3:hasCondensation>
        </nrg3:Boiler>
      </nrg3:device>
      <nrg3:device>
        <nrg3:PhotovoltaicCollector gml:id="B3_PV">
          <nrg3:model>RoofPV-9kWp</nrg3:model>
          <nrg3:installedPower uom="kW">9.0</nrg3:installedPower>
          <nrg3:moduleArea uom="m2">48.0</nrg3:moduleArea>
          <nrg3:apertureArea uom="m2">45.0</nrg3:apertureArea>
          <nrg3:azimuth uom="deg">180.0</nrg3:azimuth>
          <nrg3:inclination uom="deg">22.0</nrg3:inclination>
          <nrg3:cellType codeSpace="../../citygml_ade_schemas/ade/codelists/CellTypeValue.xml">monocrystalline</nrg3:cellType>
        </nrg3:PhotovoltaicCollector>
      </nrg3:device>
      <nrg3:device>
        <nrg3:GenericSolarCollector gml:id="B3_GenericCollector">
          <nrg3:model>UnspecifiedCollector</nrg3:model>
          <nrg3:moduleArea uom="m2">6.0</nrg3:moduleArea>
          <nrg3:apertureArea uom="m2">5.5</nrg3:apertureArea>
          <nrg3:azimuth uom="deg">180.0</nrg3:azimuth>
          <nrg3:inclination uom="deg">22.0</nrg3:inclination>
          <nrg3:lod2MultiSurface><gml:MultiSurface><gml:surfaceMember>
            <gml:Polygon gml:id="b3_collector2"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691041 5334501 6.1 691043 5334501 6.1 691043 5334504 6.9 691041 5334504 6.9 691041 5334501 6.1</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
          </gml:surfaceMember></gml:MultiSurface></nrg3:lod2MultiSurface>
          <nrg3:lod3MultiSurface><gml:MultiSurface><gml:surfaceMember>
            <gml:Polygon gml:id="b3_collector3"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691041 5334501 6.1 691043 5334501 6.1 691043 5334504 6.9 691041 5334504 6.9 691041 5334501 6.1</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
          </gml:surfaceMember></gml:MultiSurface></nrg3:lod3MultiSurface>
        </nrg3:GenericSolarCollector>
      </nrg3:device>
      <nrg3:device>
        <nrg3:SolarThermalCollector gml:id="B3_SolarThermal">
          <nrg3:model>FlatPlate-8m2</nrg3:model>
          <nrg3:moduleArea uom="m2">8.0</nrg3:moduleArea>
          <nrg3:azimuth uom="deg">180.0</nrg3:azimuth>
          <nrg3:inclination uom="deg">22.0</nrg3:inclination>
          <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/SolarCollectorTypeValue.xml">flatPlate</nrg3:type>
          <nrg3:opticalEfficiency uom="ratio">0.78</nrg3:opticalEfficiency>
          <nrg3:linearHeatLossCoefficient>3.5</nrg3:linearHeatLossCoefficient>
          <nrg3:quadraticHeatLossCoefficient>0.015</nrg3:quadraticHeatLossCoefficient>
        </nrg3:SolarThermalCollector>
      </nrg3:device>
      <nrg3:device>
        <nrg3:PhotovoltaicThermalCollector gml:id="B3_PVT">
          <nrg3:model>PVT-Hybrid-10m2</nrg3:model>
          <nrg3:moduleArea uom="m2">10.0</nrg3:moduleArea>
          <nrg3:azimuth uom="deg">180.0</nrg3:azimuth>
          <nrg3:inclination uom="deg">22.0</nrg3:inclination>
          <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/SolarCollectorTypeValue.xml">hybrid</nrg3:type>
          <nrg3:cellType codeSpace="../../citygml_ade_schemas/ade/codelists/CellTypeValue.xml">polycrystalline</nrg3:cellType>
          <nrg3:opticalEfficiency uom="ratio">0.72</nrg3:opticalEfficiency>
          <nrg3:linearHeatLossCoefficient>4.0</nrg3:linearHeatLossCoefficient>
          <nrg3:quadraticHeatLossCoefficient>0.02</nrg3:quadraticHeatLossCoefficient>
        </nrg3:PhotovoltaicThermalCollector>
      </nrg3:device>
      <nrg3:device>
        <nrg3:ThermalStorageDevice gml:id="B3_HotWaterTank">
          <nrg3:model>BufferTank-800L</nrg3:model>
          <nrg3:preparationTemperature uom="Cel">60.0</nrg3:preparationTemperature>
          <nrg3:medium codeSpace="../../citygml_ade_schemas/ade/codelists/MediumTypeValue.xml">water</nrg3:medium>
          <nrg3:thermalLossesFactor uom="W/K">2.1</nrg3:thermalLossesFactor>
          <nrg3:volume uom="m3">0.8</nrg3:volume>
        </nrg3:ThermalStorageDevice>
      </nrg3:device>
      <nrg3:device>
        <nrg3:ElectricalStorageDevice gml:id="B3_Battery">
          <nrg3:model>HomeBattery-10kWh</nrg3:model>
          <nrg3:batteryTechnology codeSpace="../../citygml_ade_schemas/ade/codelists/BatteryTechnologyTypeValue.xml">lithiumIon</nrg3:batteryTechnology>
          <nrg3:powerCapacity uom="kWh">10.0</nrg3:powerCapacity>
        </nrg3:ElectricalStorageDevice>
      </nrg3:device>
      <!-- Resources: space heating demand (with file series), electricity, plus others -->
      <nrg3:resource>
        <nrg3:Energy gml:id="B3_SpaceHeatingDemand">
          <nrg3:status>actual</nrg3:status>
          <nrg3:operationType codeSpace="../../citygml_ade_schemas/ade/codelists/ResourceOperationTypeValue.xml">demand</nrg3:operationType>
          <nrg3:amountType codeSpace="../../citygml_ade_schemas/ade/codelists/EnergyTypeValue.xml">finalEnergy</nrg3:amountType>
          <nrg3:year>2023</nrg3:year>
          <nrg3:amount uom="kWh">18500.0</nrg3:amount>
          <nrg3:timeDependentAmount>
            <nrg3:RegularTimeSeries gml:id="B3_HeatingTS">
              <nrg3:acquisitionMethod codeSpace="../../citygml_ade_schemas/ade/codelists/AcquisitionMethodValue.xml">measurement</nrg3:acquisitionMethod>
              <nrg3:interpolationType>averageInSucceedingInterval</nrg3:interpolationType>
              <nrg3:source>building energy management system</nrg3:source>
              <nrg3:temporalExtent>
                <gml:TimePeriod>
                  <gml:beginPosition>2023-01-01T00:00:00</gml:beginPosition>
                  <gml:endPosition>2023-01-01T04:00:00</gml:endPosition>
                </gml:TimePeriod>
              </nrg3:temporalExtent>
              <nrg3:timeInterval unit="hour">1</nrg3:timeInterval>
              <nrg3:valuesList uom="kWh">5.1 4.8 4.6 5.3</nrg3:valuesList>
            </nrg3:RegularTimeSeries>
          </nrg3:timeDependentAmount>
          <nrg3:isAmountNormalized>true</nrg3:isAmountNormalized>
          <nrg3:normalizationValue uom="m2">360.0</nrg3:normalizationValue>
          <nrg3:normalizationParameter>energyReferenceArea</nrg3:normalizationParameter>
          <nrg3:co2Equivalent uom="kg">3700.0</nrg3:co2Equivalent>
          <nrg3:costsMoney uom="EUR">2100.0</nrg3:costsMoney>
          <nrg3:yieldsMoney uom="EUR">0.0</nrg3:yieldsMoney>
          <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/EnergyTypeValue.xml">finalEnergy</nrg3:type>
          <nrg3:endUse codeSpace="../../citygml_ade_schemas/ade/codelists/EnergyEndUseValue.xml">spaceHeating</nrg3:endUse>
          <nrg3:energyCarrier codeSpace="../../citygml_ade_schemas/ade/codelists/EnergyCarrierValue.xml">naturalGas</nrg3:energyCarrier>
          <nrg3:maximumLoad uom="kW">38.0</nrg3:maximumLoad>
          <nrg3:source codeSpace="../../citygml_ade_schemas/ade/codelists/EnergySourceValue.xml">districtHeating</nrg3:source>
        </nrg3:Energy>
      </nrg3:resource>
      <nrg3:resource>
        <nrg3:Energy gml:id="B3_ElectricityDemand">
          <nrg3:status>actual</nrg3:status>
          <nrg3:operationType codeSpace="../../citygml_ade_schemas/ade/codelists/ResourceOperationTypeValue.xml">demand</nrg3:operationType>
          <nrg3:amountType codeSpace="../../citygml_ade_schemas/ade/codelists/EnergyTypeValue.xml">finalEnergy</nrg3:amountType>
          <nrg3:amount uom="kWh">9200.0</nrg3:amount>
          <nrg3:timeDependentAmount>
            <nrg3:RegularTimeSeriesFile gml:id="B3_ElecTSF">
              <nrg3:acquisitionMethod codeSpace="../../citygml_ade_schemas/ade/codelists/AcquisitionMethodValue.xml">measurement</nrg3:acquisitionMethod>
              <nrg3:interpolationType>averageInSucceedingInterval</nrg3:interpolationType>
              <nrg3:uom uom="kWh"/>
              <nrg3:fileURI>./timeseries/B3_electricity_2023.csv</nrg3:fileURI>
              <nrg3:temporalExtent>
                <gml:TimePeriod>
                  <gml:beginPosition>2023-01-01T00:00:00</gml:beginPosition>
                  <gml:endPosition>2024-01-01T00:00:00</gml:endPosition>
                </gml:TimePeriod>
              </nrg3:temporalExtent>
              <nrg3:timeInterval unit="hour">1</nrg3:timeInterval>
              <nrg3:numberOfHeaderLines>1</nrg3:numberOfHeaderLines>
              <nrg3:fieldSeparator>,</nrg3:fieldSeparator>
              <nrg3:recordSeparator>\n</nrg3:recordSeparator>
              <nrg3:decimalSymbol>.</nrg3:decimalSymbol>
              <nrg3:valueColumnNumber>2</nrg3:valueColumnNumber>
            </nrg3:RegularTimeSeriesFile>
          </nrg3:timeDependentAmount>
          <nrg3:isAmountNormalized>false</nrg3:isAmountNormalized>
          <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/EnergyTypeValue.xml">finalEnergy</nrg3:type>
          <nrg3:endUse codeSpace="../../citygml_ade_schemas/ade/codelists/EnergyEndUseValue.xml">electricalAppliances</nrg3:endUse>
          <nrg3:energyCarrier codeSpace="../../citygml_ade_schemas/ade/codelists/EnergyCarrierValue.xml">electricity</nrg3:energyCarrier>
        </nrg3:Energy>
      </nrg3:resource>
      <nrg3:resource>
        <nrg3:UrbanSpace gml:id="B3_UrbanSpace">
          <nrg3:status>actual</nrg3:status>
          <nrg3:operationType codeSpace="../../citygml_ade_schemas/ade/codelists/ResourceOperationTypeValue.xml">occupation</nrg3:operationType>
          <nrg3:amountType codeSpace="../../citygml_ade_schemas/ade/codelists/AreaTypeValue.xml">footprintArea</nrg3:amountType>
          <nrg3:amount uom="m2">120.0</nrg3:amount>
          <nrg3:isAmountNormalized>false</nrg3:isAmountNormalized>
          <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/UrbanSpaceTypeValue.xml">builtArea</nrg3:type>
          <nrg3:endUse codeSpace="../../citygml_ade_schemas/ade/codelists/UrbanSpaceEndUseValue.xml">office</nrg3:endUse>
        </nrg3:UrbanSpace>
      </nrg3:resource>
      <nrg3:resource>
        <nrg3:OtherResource gml:id="B3_OtherResource">
          <nrg3:status>potential</nrg3:status>
          <nrg3:operationType codeSpace="../../citygml_ade_schemas/ade/codelists/ResourceOperationTypeValue.xml">demand</nrg3:operationType>
          <nrg3:amountType codeSpace="../../citygml_ade_schemas/ade/codelists/EnergyTypeValue.xml">mass</nrg3:amountType>
          <nrg3:amount uom="kg">50.0</nrg3:amount>
          <nrg3:isAmountNormalized>false</nrg3:isAmountNormalized>
          <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/OtherResourceTypeValue.xml">refrigerant</nrg3:type>
          <nrg3:endUse codeSpace="../../citygml_ade_schemas/ade/codelists/OtherResourceEndUseValue.xml">cooling</nrg3:endUse>
        </nrg3:OtherResource>
      </nrg3:resource>
      <!-- ===== CityGML base building attributes ===== -->
      <bldg:class codeSpace="http://www.sig3d.org/codelists/standard/building/2.0/_AbstractBuilding_class.xml">1000</bldg:class>
      <bldg:function codeSpace="http://www.sig3d.org/codelists/standard/building/2.0/_AbstractBuilding_function.xml">1120</bldg:function>
      <bldg:usage codeSpace="http://www.sig3d.org/codelists/standard/building/2.0/_AbstractBuilding_usage.xml">1120</bldg:usage>
      <bldg:yearOfConstruction>2015</bldg:yearOfConstruction>
      <bldg:roofType codeSpace="http://www.sig3d.org/codelists/standard/building/2.0/_AbstractBuilding_roofType.xml">1030</bldg:roofType>
      <bldg:measuredHeight uom="m">8.0</bldg:measuredHeight>
      <bldg:storeysAboveGround>3</bldg:storeysAboveGround>
      <bldg:storeysBelowGround>1</bldg:storeysBelowGround>
      <!-- ===================================================================
           B3 envelope as a 4-level vertical stack of thematic surfaces.
           Horizontal interfaces between two thermal zones carry the role-correct
           Energy ADE type, are defined ONCE and shared (xlink) by both zones:
             z=-2.5 GroundSurface (basement slab -> terrain)
             z= 0   BasementCeilingSurface  (basement | ground floor)   [hull bottom]
             z= 3   IntermediateFloorSurface (ground | upper, both heated)
             z= 6   AtticFloorSurface        (upper, heated | attic, unheated)
           RoofSurface is used ONLY for the roof skin -> exterior.
           Exterior walls are split per storey so each is one zone boundary.
      ==================================================================== -->
      <!-- Basement slab (terrain contact), not part of the above-ground hull -->
      <bldg:boundedBy>
        <bldg:GroundSurface gml:id="B3_GroundSurface">
          <bldg:lod3MultiSurface><gml:MultiSurface><gml:surfaceMember>
            <gml:Polygon gml:id="b3_ground"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691040 5334500 -2.5 691040 5334510 -2.5 691052 5334510 -2.5 691052 5334500 -2.5 691040 5334500 -2.5</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
          </gml:surfaceMember></gml:MultiSurface></bldg:lod3MultiSurface>
          <nrg3:bdgBdrySurfIsAdiabatic>false</nrg3:bdgBdrySurfIsAdiabatic>
        </bldg:GroundSurface>
      </bldg:boundedBy>
      <!-- Basement perimeter walls (z -2.5..0), against the surrounding ground -->
      <bldg:boundedBy>
        <bldg:WallSurface gml:id="B3_BasementWallSouth">
          <bldg:lod3MultiSurface><gml:MultiSurface><gml:surfaceMember>
            <gml:Polygon gml:id="b3_bw_south"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691040 5334500 -2.5 691052 5334500 -2.5 691052 5334500 0 691040 5334500 0 691040 5334500 -2.5</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
          </gml:surfaceMember></gml:MultiSurface></bldg:lod3MultiSurface>
          <nrg3:bdgBdrySurfIsAdiabatic>true</nrg3:bdgBdrySurfIsAdiabatic>
        </bldg:WallSurface>
      </bldg:boundedBy>
      <bldg:boundedBy>
        <bldg:WallSurface gml:id="B3_BasementWallEast">
          <bldg:lod3MultiSurface><gml:MultiSurface><gml:surfaceMember>
            <gml:Polygon gml:id="b3_bw_east"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691052 5334500 -2.5 691052 5334510 -2.5 691052 5334510 0 691052 5334500 0 691052 5334500 -2.5</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
          </gml:surfaceMember></gml:MultiSurface></bldg:lod3MultiSurface>
        </bldg:WallSurface>
      </bldg:boundedBy>
      <bldg:boundedBy>
        <bldg:WallSurface gml:id="B3_BasementWallNorth">
          <bldg:lod3MultiSurface><gml:MultiSurface><gml:surfaceMember>
            <gml:Polygon gml:id="b3_bw_north"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691052 5334510 -2.5 691040 5334510 -2.5 691040 5334510 0 691052 5334510 0 691052 5334510 -2.5</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
          </gml:surfaceMember></gml:MultiSurface></bldg:lod3MultiSurface>
        </bldg:WallSurface>
      </bldg:boundedBy>
      <bldg:boundedBy>
        <bldg:WallSurface gml:id="B3_BasementWallWest">
          <bldg:lod3MultiSurface><gml:MultiSurface><gml:surfaceMember>
            <gml:Polygon gml:id="b3_bw_west"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691040 5334510 -2.5 691040 5334500 -2.5 691040 5334500 0 691040 5334510 0 691040 5334510 -2.5</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
          </gml:surfaceMember></gml:MultiSurface></bldg:lod3MultiSurface>
        </bldg:WallSurface>
      </bldg:boundedBy>
      <!-- z=0 basement | ground-floor interface (also the above-ground hull bottom) -->
      <bldg:boundedBy>
        <nrg3:BasementCeilingSurface gml:id="B3_BasementCeiling">
          <bldg:lod3MultiSurface><gml:MultiSurface><gml:surfaceMember>
            <gml:Polygon gml:id="b3_basement"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691040 5334500 0 691040 5334510 0 691052 5334510 0 691052 5334500 0 691040 5334500 0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
          </gml:surfaceMember></gml:MultiSurface></bldg:lod3MultiSurface>
          <nrg3:bdgBdrySurfIsAdiabatic>false</nrg3:bdgBdrySurfIsAdiabatic>
        </nrg3:BasementCeilingSurface>
      </bldg:boundedBy>
      <!-- Ground-floor exterior walls (z 0..3); south wall carries construction + openings -->
      <bldg:boundedBy>
        <bldg:WallSurface gml:id="B3_WallGroundSouth">
          <!-- Layered construction with optical properties on this wall -->
          <nrg3:layeredConstruction>
            <nrg3:LayeredConstruction gml:id="B3_WallConstruction">
              <nrg3:libraryCode>WALL-EXT-2015</nrg3:libraryCode>
              <nrg3:uValue uom="W/K/m2">0.18</nrg3:uValue>
              <nrg3:gValue uom="ratio">0.0</nrg3:gValue>
              <nrg3:glazingRatio uom="ratio">0.0</nrg3:glazingRatio>
              <nrg3:emissivity>
                <nrg3:Emissivity>
                  <nrg3:fraction uom="ratio">0.9</nrg3:fraction>
                  <nrg3:surface>outside</nrg3:surface>
                </nrg3:Emissivity>
              </nrg3:emissivity>
              <nrg3:reflectance>
                <nrg3:Reflectance>
                  <nrg3:fraction uom="ratio">0.4</nrg3:fraction>
                  <nrg3:surface>outside</nrg3:surface>
                  <nrg3:wavelengthRange>solar</nrg3:wavelengthRange>
                </nrg3:Reflectance>
              </nrg3:reflectance>
              <nrg3:transmittance>
                <nrg3:Transmittance>
                  <nrg3:fraction uom="ratio">0.0</nrg3:fraction>
                  <nrg3:wavelengthRange>solar</nrg3:wavelengthRange>
                </nrg3:Transmittance>
              </nrg3:transmittance>
              <nrg3:layer>
                <nrg3:Layer gml:id="B3_LayerBrick">
                  <nrg3:thickness uom="m">0.24</nrg3:thickness>
                  <nrg3:material>
                    <nrg3:SolidMaterial gml:id="B3_MatBrick">
                      <nrg3:thermalConductivity uom="W/K/m">0.79</nrg3:thermalConductivity>
                      <nrg3:density uom="kg/m3">1800.0</nrg3:density>
                      <nrg3:specificHeatCapacity uom="J/kg/K">1000.0</nrg3:specificHeatCapacity>
                    </nrg3:SolidMaterial>
                  </nrg3:material>
                </nrg3:Layer>
              </nrg3:layer>
              <nrg3:layer>
                <nrg3:Layer gml:id="B3_LayerInsulation">
                  <nrg3:thickness uom="m">0.16</nrg3:thickness>
                  <nrg3:material xlink:href="#LIB_Insulation"/>
                </nrg3:Layer>
              </nrg3:layer>
            </nrg3:LayeredConstruction>
          </nrg3:layeredConstruction>
          <bldg:lod3MultiSurface><gml:MultiSurface><gml:surfaceMember>
            <gml:Polygon gml:id="b3_gw_south"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691040 5334500 0 691052 5334500 0 691052 5334500 3 691040 5334500 3 691040 5334500 0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
          </gml:surfaceMember></gml:MultiSurface></bldg:lod3MultiSurface>
          <bldg:opening>
            <bldg:Window gml:id="B3_Window1">
              <bldg:lod3MultiSurface><gml:MultiSurface><gml:surfaceMember>
                <gml:Polygon gml:id="b3_win1"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691042 5334500 1 691045 5334500 1 691045 5334500 2.5 691042 5334500 2.5 691042 5334500 1</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
              </gml:surfaceMember></gml:MultiSurface></bldg:lod3MultiSurface>
              <nrg3:bdgOpnArea uom="m2">4.5</nrg3:bdgOpnArea>
              <nrg3:bdgOpnAzimuth uom="deg">180.0</nrg3:bdgOpnAzimuth>
              <nrg3:bdgOpnInclination uom="deg">90.0</nrg3:bdgOpnInclination>
              <nrg3:bdgOpnGroundViewFactor uom="ratio">0.3</nrg3:bdgOpnGroundViewFactor>
              <nrg3:bdgOpnSkyViewFactor uom="ratio">0.5</nrg3:bdgOpnSkyViewFactor>
            </bldg:Window>
          </bldg:opening>
          <bldg:opening>
            <bldg:Window gml:id="B3_Window2">
              <bldg:lod3MultiSurface><gml:MultiSurface><gml:surfaceMember>
                <gml:Polygon gml:id="b3_win2"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691047 5334500 1 691050 5334500 1 691050 5334500 2.5 691047 5334500 2.5 691047 5334500 1</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
              </gml:surfaceMember></gml:MultiSurface></bldg:lod3MultiSurface>
              <nrg3:bdgOpnArea uom="m2">4.5</nrg3:bdgOpnArea>
              <nrg3:bdgOpnAzimuth uom="deg">180.0</nrg3:bdgOpnAzimuth>
            </bldg:Window>
          </bldg:opening>
          <bldg:opening>
            <bldg:Door gml:id="B3_Door1">
              <bldg:lod3MultiSurface><gml:MultiSurface><gml:surfaceMember>
                <gml:Polygon gml:id="b3_door"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691045 5334500 0 691047 5334500 0 691047 5334500 2.1 691045 5334500 2.1 691045 5334500 0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
              </gml:surfaceMember></gml:MultiSurface></bldg:lod3MultiSurface>
            </bldg:Door>
          </bldg:opening>
          <nrg3:bdgBdrySurfAzimuth uom="deg">180.0</nrg3:bdgBdrySurfAzimuth>
          <nrg3:bdgBdrySurfGroundViewFactor uom="ratio">0.5</nrg3:bdgBdrySurfGroundViewFactor>
          <nrg3:bdgBdrySurfHeatCapacity uom="J/K">5.0E6</nrg3:bdgBdrySurfHeatCapacity>
          <nrg3:bdgBdrySurfInclination uom="deg">90.0</nrg3:bdgBdrySurfInclination>
          <nrg3:bdgBdrySurfOpaqueSurfaceArea uom="m2">27.0</nrg3:bdgBdrySurfOpaqueSurfaceArea>
          <nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="ratio">0.30</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
          <nrg3:bdgBdrySurfSkyViewFactor uom="ratio">0.5</nrg3:bdgBdrySurfSkyViewFactor>
          <nrg3:bdgBdrySurfThickness uom="m">0.40</nrg3:bdgBdrySurfThickness>
          <nrg3:bdgBdrySurfTotalSurfaceArea uom="m2">36.0</nrg3:bdgBdrySurfTotalSurfaceArea>
        </bldg:WallSurface>
      </bldg:boundedBy>
      <bldg:boundedBy>
        <bldg:WallSurface gml:id="B3_WallGroundEast">
          <bldg:lod3MultiSurface><gml:MultiSurface><gml:surfaceMember>
            <gml:Polygon gml:id="b3_gw_east"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691052 5334500 0 691052 5334510 0 691052 5334510 3 691052 5334500 3 691052 5334500 0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
          </gml:surfaceMember></gml:MultiSurface></bldg:lod3MultiSurface>
          <nrg3:bdgBdrySurfAzimuth uom="deg">90.0</nrg3:bdgBdrySurfAzimuth>
        </bldg:WallSurface>
      </bldg:boundedBy>
      <bldg:boundedBy>
        <bldg:WallSurface gml:id="B3_WallGroundNorth">
          <bldg:lod3MultiSurface><gml:MultiSurface><gml:surfaceMember>
            <gml:Polygon gml:id="b3_gw_north"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691052 5334510 0 691040 5334510 0 691040 5334510 3 691052 5334510 3 691052 5334510 0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
          </gml:surfaceMember></gml:MultiSurface></bldg:lod3MultiSurface>
          <nrg3:bdgBdrySurfAzimuth uom="deg">0.0</nrg3:bdgBdrySurfAzimuth>
        </bldg:WallSurface>
      </bldg:boundedBy>
      <bldg:boundedBy>
        <bldg:WallSurface gml:id="B3_WallGroundWest">
          <bldg:lod3MultiSurface><gml:MultiSurface><gml:surfaceMember>
            <gml:Polygon gml:id="b3_gw_west"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691040 5334510 0 691040 5334500 0 691040 5334500 3 691040 5334510 3 691040 5334510 0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
          </gml:surfaceMember></gml:MultiSurface></bldg:lod3MultiSurface>
          <nrg3:bdgBdrySurfAzimuth uom="deg">270.0</nrg3:bdgBdrySurfAzimuth>
        </bldg:WallSurface>
      </bldg:boundedBy>
      <!-- Upper-floor exterior walls (z 3..6) -->
      <bldg:boundedBy>
        <bldg:WallSurface gml:id="B3_WallUpperSouth">
          <bldg:lod3MultiSurface><gml:MultiSurface><gml:surfaceMember>
            <gml:Polygon gml:id="b3_uw_south"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691040 5334500 3 691052 5334500 3 691052 5334500 6 691040 5334500 6 691040 5334500 3</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
          </gml:surfaceMember></gml:MultiSurface></bldg:lod3MultiSurface>
          <nrg3:bdgBdrySurfAzimuth uom="deg">180.0</nrg3:bdgBdrySurfAzimuth>
        </bldg:WallSurface>
      </bldg:boundedBy>
      <bldg:boundedBy>
        <bldg:WallSurface gml:id="B3_WallUpperEast">
          <bldg:lod3MultiSurface><gml:MultiSurface><gml:surfaceMember>
            <gml:Polygon gml:id="b3_uw_east"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691052 5334500 3 691052 5334510 3 691052 5334510 6 691052 5334500 6 691052 5334500 3</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
          </gml:surfaceMember></gml:MultiSurface></bldg:lod3MultiSurface>
          <nrg3:bdgBdrySurfAzimuth uom="deg">90.0</nrg3:bdgBdrySurfAzimuth>
        </bldg:WallSurface>
      </bldg:boundedBy>
      <bldg:boundedBy>
        <bldg:WallSurface gml:id="B3_WallUpperNorth">
          <bldg:lod3MultiSurface><gml:MultiSurface><gml:surfaceMember>
            <gml:Polygon gml:id="b3_uw_north"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691052 5334510 3 691040 5334510 3 691040 5334510 6 691052 5334510 6 691052 5334510 3</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
          </gml:surfaceMember></gml:MultiSurface></bldg:lod3MultiSurface>
          <nrg3:bdgBdrySurfAzimuth uom="deg">0.0</nrg3:bdgBdrySurfAzimuth>
        </bldg:WallSurface>
      </bldg:boundedBy>
      <bldg:boundedBy>
        <bldg:WallSurface gml:id="B3_WallUpperWest">
          <bldg:lod3MultiSurface><gml:MultiSurface><gml:surfaceMember>
            <gml:Polygon gml:id="b3_uw_west"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691040 5334510 3 691040 5334500 3 691040 5334500 6 691040 5334510 6 691040 5334510 3</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
          </gml:surfaceMember></gml:MultiSurface></bldg:lod3MultiSurface>
          <nrg3:bdgBdrySurfAzimuth uom="deg">270.0</nrg3:bdgBdrySurfAzimuth>
        </bldg:WallSurface>
      </bldg:boundedBy>
      <!-- Attic gable walls (z 6..8, triangular) -> exterior -->
      <bldg:boundedBy>
        <bldg:WallSurface gml:id="B3_GableEast">
          <bldg:lod3MultiSurface><gml:MultiSurface><gml:surfaceMember>
            <gml:Polygon gml:id="b3_aw_east"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691052 5334500 6 691052 5334510 6 691052 5334505 8 691052 5334500 6</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
          </gml:surfaceMember></gml:MultiSurface></bldg:lod3MultiSurface>
          <nrg3:bdgBdrySurfAzimuth uom="deg">90.0</nrg3:bdgBdrySurfAzimuth>
        </bldg:WallSurface>
      </bldg:boundedBy>
      <bldg:boundedBy>
        <bldg:WallSurface gml:id="B3_GableWest">
          <bldg:lod3MultiSurface><gml:MultiSurface><gml:surfaceMember>
            <gml:Polygon gml:id="b3_aw_west"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691040 5334500 6 691040 5334505 8 691040 5334510 6 691040 5334500 6</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
          </gml:surfaceMember></gml:MultiSurface></bldg:lod3MultiSurface>
          <nrg3:bdgBdrySurfAzimuth uom="deg">270.0</nrg3:bdgBdrySurfAzimuth>
        </bldg:WallSurface>
      </bldg:boundedBy>
      <bldg:boundedBy>
        <bldg:RoofSurface gml:id="B3_RoofSouth">
          <bldg:lod3MultiSurface><gml:MultiSurface><gml:surfaceMember>
            <gml:Polygon gml:id="b3_rsouth"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691040 5334500 6 691052 5334500 6 691052 5334505 8 691040 5334505 8 691040 5334500 6</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
          </gml:surfaceMember></gml:MultiSurface></bldg:lod3MultiSurface>
          <nrg3:bdgBdrySurfAzimuth uom="deg">180.0</nrg3:bdgBdrySurfAzimuth>
          <nrg3:bdgBdrySurfInclination uom="deg">22.0</nrg3:bdgBdrySurfInclination>
          <nrg3:bdgBdrySurfSkyViewFactor uom="ratio">0.85</nrg3:bdgBdrySurfSkyViewFactor>
        </bldg:RoofSurface>
      </bldg:boundedBy>
      <bldg:boundedBy>
        <bldg:RoofSurface gml:id="B3_RoofNorth">
          <bldg:lod3MultiSurface><gml:MultiSurface><gml:surfaceMember>
            <gml:Polygon gml:id="b3_rnorth"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691040 5334505 8 691052 5334505 8 691052 5334510 6 691040 5334510 6 691040 5334505 8</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
          </gml:surfaceMember></gml:MultiSurface></bldg:lod3MultiSurface>
          <nrg3:bdgBdrySurfAzimuth uom="deg">0.0</nrg3:bdgBdrySurfAzimuth>
          <nrg3:bdgBdrySurfInclination uom="deg">22.0</nrg3:bdgBdrySurfInclination>
        </bldg:RoofSurface>
      </bldg:boundedBy>
      <!-- z=3 ground | upper interface (both heated) -->
      <bldg:boundedBy>
        <nrg3:IntermediateFloorSurface gml:id="B3_IntermediateFloor">
          <bldg:lod3MultiSurface><gml:MultiSurface><gml:surfaceMember>
            <gml:Polygon gml:id="b3_inter"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691040 5334500 3 691052 5334500 3 691052 5334510 3 691040 5334510 3 691040 5334500 3</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
          </gml:surfaceMember></gml:MultiSurface></bldg:lod3MultiSurface>
          <nrg3:bdgBdrySurfIsAdiabatic>true</nrg3:bdgBdrySurfIsAdiabatic>
        </nrg3:IntermediateFloorSurface>
      </bldg:boundedBy>
      <!-- z=6 upper (heated) | attic (unheated) interface -->
      <bldg:boundedBy>
        <nrg3:AtticFloorSurface gml:id="B3_AtticFloor">
          <bldg:lod3MultiSurface><gml:MultiSurface><gml:surfaceMember>
            <gml:Polygon gml:id="b3_attic"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691040 5334500 6 691052 5334500 6 691052 5334510 6 691040 5334510 6 691040 5334500 6</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
          </gml:surfaceMember></gml:MultiSurface></bldg:lod3MultiSurface>
          <nrg3:bdgBdrySurfHeatCapacity uom="J/K">8.0E6</nrg3:bdgBdrySurfHeatCapacity>
        </nrg3:AtticFloorSurface>
      </bldg:boundedBy>
      <!-- vertical party wall shared with the neighbouring building -->
      <bldg:boundedBy>
        <nrg3:PartyWallSurface gml:id="B3_PartyWall">
          <bldg:lod3MultiSurface><gml:MultiSurface><gml:surfaceMember>
            <gml:Polygon gml:id="b3_party"><gml:exterior><gml:LinearRing><gml:posList srsDimension="3">691046 5334500 0 691046 5334510 0 691046 5334510 6 691046 5334500 6 691046 5334500 0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>
          </gml:surfaceMember></gml:MultiSurface></bldg:lod3MultiSurface>
        </nrg3:PartyWallSurface>
      </bldg:boundedBy>
      <!-- LOD3 closed above-ground gabled hull (z 0..8): basement-ceiling bottom,
           per-storey walls, gable triangles, two roof slopes. (after all
           boundedBy, per CityGML sequence) -->
      <bldg:lod3Solid>
        <gml:Solid srsName="urn:ogc:def:crs:EPSG::25832">
          <gml:exterior>
            <gml:CompositeSurface>
              <gml:surfaceMember xlink:href="#b3_basement"/>
              <gml:surfaceMember xlink:href="#b3_gw_south"/>
              <gml:surfaceMember xlink:href="#b3_gw_east"/>
              <gml:surfaceMember xlink:href="#b3_gw_north"/>
              <gml:surfaceMember xlink:href="#b3_gw_west"/>
              <gml:surfaceMember xlink:href="#b3_uw_south"/>
              <gml:surfaceMember xlink:href="#b3_uw_east"/>
              <gml:surfaceMember xlink:href="#b3_uw_north"/>
              <gml:surfaceMember xlink:href="#b3_uw_west"/>
              <gml:surfaceMember xlink:href="#b3_aw_east"/>
              <gml:surfaceMember xlink:href="#b3_aw_west"/>
              <gml:surfaceMember xlink:href="#b3_rsouth"/>
              <gml:surfaceMember xlink:href="#b3_rnorth"/>
            </gml:CompositeSurface>
          </gml:exterior>
        </gml:Solid>
      </bldg:lod3Solid>
      <bldg:address>
        <core:Address>
          <core:xalAddress>
            <xAL:AddressDetails>
              <xAL:Country>
                <xAL:CountryName>Germany</xAL:CountryName>
                <xAL:Locality Type="Town">
                  <xAL:LocalityName>Munich</xAL:LocalityName>
                  <xAL:Thoroughfare Type="Street">
                    <xAL:ThoroughfareNumber>12</xAL:ThoroughfareNumber>
                    <xAL:ThoroughfareName>Energieweg</xAL:ThoroughfareName>
                  </xAL:Thoroughfare>
                  <xAL:PostalCode><xAL:PostalCodeNumber>80331</xAL:PostalCodeNumber></xAL:PostalCode>
                </xAL:Locality>
              </xAL:Country>
            </xAL:AddressDetails>
          </core:xalAddress>
        </core:Address>
      </bldg:address>
      <!-- ===== Energy ADE building-level attributes ===== -->
      <nrg3:bdgType codeSpace="../../citygml_ade_schemas/ade/codelists/BuildingTypeValue.xml">office building</nrg3:bdgType>
      <nrg3:bdgConstructionWeight codeSpace="../../citygml_ade_schemas/ade/codelists/ConstructionWeightValue.xml">heavy</nrg3:bdgConstructionWeight>
      <nrg3:bdgIsProtected>false</nrg3:bdgIsProtected>
      <nrg3:bdgAtticThermalStatus>isNeitherHeatedNorCooled</nrg3:bdgAtticThermalStatus>
      <nrg3:bdgBasementThermalStatus>isOnlyHeated</nrg3:bdgBasementThermalStatus>
      <nrg3:bdgArea>
        <nrg3:QualifiedArea>
          <nrg3:value uom="m2">360.0</nrg3:value>
          <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/AreaTypeValue.xml">energyReferenceArea</nrg3:type>
        </nrg3:QualifiedArea>
      </nrg3:bdgArea>
      <nrg3:bdgHeight>
        <nrg3:QualifiedHeight>
          <nrg3:value uom="m">8.0</nrg3:value>
          <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/HeightTypeValue.xml">highestPoint</nrg3:type>
        </nrg3:QualifiedHeight>
      </nrg3:bdgHeight>
      <nrg3:bdgVolume>
        <nrg3:QualifiedVolume>
          <nrg3:value uom="m3">960.0</nrg3:value>
          <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/VolumeTypeValue.xml">grossVolume</nrg3:type>
        </nrg3:QualifiedVolume>
      </nrg3:bdgVolume>
      <nrg3:energyPerformanceCertificate>
        <nrg3:EnergyPerformanceCertificate gml:id="B3_EPC">
          <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/EnergyPerformanceCertificateTypeValue.xml">nationalScheme</nrg3:type>
          <nrg3:label>A</nrg3:label>
          <nrg3:value uom="kWh/m2/a">42.0</nrg3:value>
          <nrg3:issueDate>2022-09-15</nrg3:issueDate>
          <nrg3:expirationDate>2032-09-15</nrg3:expirationDate>
          <nrg3:certificationMethod>DIN V 18599</nrg3:certificationMethod>
          <nrg3:certificationURI>https://example.org/epc/B3.pdf</nrg3:certificationURI>
        </nrg3:EnergyPerformanceCertificate>
      </nrg3:energyPerformanceCertificate>
      <nrg3:refurbishmentMeasure>
        <nrg3:RefurbishmentMeasure gml:id="B3_Refurb">
          <nrg3:libraryCode>REFURB-PV-2021</nrg3:libraryCode>
          <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/RefurbishmentMeasureTypeValue.xml">installedPVPanels</nrg3:type>
          <nrg3:startDate>2021-04-01</nrg3:startDate>
          <nrg3:endDate>2021-05-20</nrg3:endDate>
        </nrg3:RefurbishmentMeasure>
      </nrg3:refurbishmentMeasure>
      <!-- Thermal zone 1: heated ground+upper floors -->
      <!-- Vertical stack of 4 thermal zones. Each separating surface is declared
           once (in boundedBy above) and referenced by BOTH adjacent zones, with
           the role-correct type:
             basement|ground = BasementCeilingSurface
             ground|upper    = IntermediateFloorSurface
             upper|attic     = AtticFloorSurface  -->
      <!-- Zone 1: basement (unheated) -->
      <nrg3:thermalZone>
        <nrg3:ThermalZone gml:id="B3_ThermalZone_Basement">
          <nrg3:area>
            <nrg3:QualifiedArea>
              <nrg3:value uom="m2">120.0</nrg3:value>
              <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/AreaTypeValue.xml">netFloorArea</nrg3:type>
            </nrg3:QualifiedArea>
          </nrg3:area>
          <nrg3:heatCapacity uom="J/K">9.0E7</nrg3:heatCapacity>
          <nrg3:infiltrationRate uom="1/h">0.6</nrg3:infiltrationRate>
          <nrg3:isCooled>false</nrg3:isCooled>
          <nrg3:isHeated>false</nrg3:isHeated>
          <nrg3:coincidesWithLod2Hull>false</nrg3:coincidesWithLod2Hull>
          <nrg3:coincidesWithLod3Hull>false</nrg3:coincidesWithLod3Hull>
          <nrg3:thermalBoundary xlink:href="#B3_GroundSurface"/>
          <nrg3:thermalBoundary xlink:href="#B3_BasementWallSouth"/>
          <nrg3:thermalBoundary xlink:href="#B3_BasementWallEast"/>
          <nrg3:thermalBoundary xlink:href="#B3_BasementWallNorth"/>
          <nrg3:thermalBoundary xlink:href="#B3_BasementWallWest"/>
          <nrg3:thermalBoundary xlink:href="#B3_BasementCeiling"/>
        </nrg3:ThermalZone>
      </nrg3:thermalZone>
      <!-- Zone 2: ground floor (heated); floor = basement ceiling, ceiling = intermediate floor -->
      <nrg3:thermalZone>
        <nrg3:ThermalZone gml:id="B3_ThermalZone_Ground">
          <nrg3:area>
            <nrg3:QualifiedArea>
              <nrg3:value uom="m2">120.0</nrg3:value>
              <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/AreaTypeValue.xml">heatedArea</nrg3:type>
            </nrg3:QualifiedArea>
          </nrg3:area>
          <nrg3:volume>
            <nrg3:QualifiedVolume>
              <nrg3:value uom="m3">360.0</nrg3:value>
              <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/VolumeTypeValue.xml">heatedVolume</nrg3:type>
            </nrg3:QualifiedVolume>
          </nrg3:volume>
          <nrg3:usageZone xlink:href="#B3_UsageZone"/>
          <nrg3:heatCapacity uom="J/K">8.0E7</nrg3:heatCapacity>
          <nrg3:infiltrationRate uom="1/h">0.3</nrg3:infiltrationRate>
          <nrg3:isCooled>true</nrg3:isCooled>
          <nrg3:isHeated>true</nrg3:isHeated>
          <nrg3:coincidesWithLod2Hull>false</nrg3:coincidesWithLod2Hull>
          <nrg3:coincidesWithLod3Hull>false</nrg3:coincidesWithLod3Hull>
          <nrg3:thermalBoundary xlink:href="#B3_BasementCeiling"/>
          <nrg3:thermalBoundary xlink:href="#B3_WallGroundSouth"/>
          <nrg3:thermalBoundary xlink:href="#B3_WallGroundEast"/>
          <nrg3:thermalBoundary xlink:href="#B3_WallGroundNorth"/>
          <nrg3:thermalBoundary xlink:href="#B3_WallGroundWest"/>
          <nrg3:thermalBoundary xlink:href="#B3_PartyWall"/>
          <nrg3:thermalBoundary xlink:href="#B3_IntermediateFloor"/>
        </nrg3:ThermalZone>
      </nrg3:thermalZone>
      <!-- Zone 3: upper floor (heated); floor = intermediate floor, ceiling = attic floor -->
      <nrg3:thermalZone>
        <nrg3:ThermalZone gml:id="B3_ThermalZone_Upper">
          <nrg3:area>
            <nrg3:QualifiedArea>
              <nrg3:value uom="m2">120.0</nrg3:value>
              <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/AreaTypeValue.xml">heatedArea</nrg3:type>
            </nrg3:QualifiedArea>
          </nrg3:area>
          <nrg3:volume>
            <nrg3:QualifiedVolume>
              <nrg3:value uom="m3">360.0</nrg3:value>
              <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/VolumeTypeValue.xml">heatedVolume</nrg3:type>
            </nrg3:QualifiedVolume>
          </nrg3:volume>
          <nrg3:heatCapacity uom="J/K">8.0E7</nrg3:heatCapacity>
          <nrg3:infiltrationRate uom="1/h">0.3</nrg3:infiltrationRate>
          <nrg3:isCooled>true</nrg3:isCooled>
          <nrg3:isHeated>true</nrg3:isHeated>
          <nrg3:coincidesWithLod2Hull>false</nrg3:coincidesWithLod2Hull>
          <nrg3:coincidesWithLod3Hull>false</nrg3:coincidesWithLod3Hull>
          <nrg3:thermalBoundary xlink:href="#B3_IntermediateFloor"/>
          <nrg3:thermalBoundary xlink:href="#B3_WallUpperSouth"/>
          <nrg3:thermalBoundary xlink:href="#B3_WallUpperEast"/>
          <nrg3:thermalBoundary xlink:href="#B3_WallUpperNorth"/>
          <nrg3:thermalBoundary xlink:href="#B3_WallUpperWest"/>
          <nrg3:thermalBoundary xlink:href="#B3_PartyWall"/>
          <nrg3:thermalBoundary xlink:href="#B3_AtticFloor"/>
        </nrg3:ThermalZone>
      </nrg3:thermalZone>
      <!-- Zone 4: attic (unheated); floor = attic floor, bounded by the tilted roof slopes + gables -->
      <nrg3:thermalZone>
        <nrg3:ThermalZone gml:id="B3_ThermalZone_Attic">
          <nrg3:area>
            <nrg3:QualifiedArea>
              <nrg3:value uom="m2">120.0</nrg3:value>
              <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/AreaTypeValue.xml">netFloorArea</nrg3:type>
            </nrg3:QualifiedArea>
          </nrg3:area>
          <nrg3:heatCapacity uom="J/K">3.0E7</nrg3:heatCapacity>
          <nrg3:infiltrationRate uom="1/h">1.2</nrg3:infiltrationRate>
          <nrg3:isCooled>false</nrg3:isCooled>
          <nrg3:isHeated>false</nrg3:isHeated>
          <nrg3:coincidesWithLod2Hull>false</nrg3:coincidesWithLod2Hull>
          <nrg3:coincidesWithLod3Hull>false</nrg3:coincidesWithLod3Hull>
          <nrg3:thermalBoundary xlink:href="#B3_AtticFloor"/>
          <nrg3:thermalBoundary xlink:href="#B3_GableEast"/>
          <nrg3:thermalBoundary xlink:href="#B3_GableWest"/>
          <nrg3:thermalBoundary xlink:href="#B3_RoofSouth"/>
          <nrg3:thermalBoundary xlink:href="#B3_RoofNorth"/>
        </nrg3:ThermalZone>
      </nrg3:thermalZone>
      <!-- Usage zone -->
      <nrg3:usageZone>
        <nrg3:UsageZone gml:id="B3_UsageZone">
          <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/CurrentUseValue.xml">office</nrg3:type>
          <nrg3:isPrimary>true</nrg3:isPrimary>
          <nrg3:numberOfBuildingUnits>1</nrg3:numberOfBuildingUnits>
          <nrg3:internalHeatGains uom="W">2400.0</nrg3:internalHeatGains>
          <nrg3:internalHeatGainsConvectiveFraction uom="ratio">0.4</nrg3:internalHeatGainsConvectiveFraction>
          <nrg3:internalHeatGainsLatentFraction uom="ratio">0.1</nrg3:internalHeatGainsLatentFraction>
          <nrg3:internalHeatGainsRadiantFraction uom="ratio">0.5</nrg3:internalHeatGainsRadiantFraction>
          <nrg3:coolingSchedule>
            <nrg3:DualValueSchedule gml:id="B3_CoolingSchedule">
              <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/ScheduleTypeValue.xml">weekDay</nrg3:type>
              <nrg3:idleValue uom="Cel">28.0</nrg3:idleValue>
              <nrg3:usageValue uom="Cel">24.0</nrg3:usageValue>
              <nrg3:startUsageTime>08:00:00</nrg3:startUsageTime>
              <nrg3:endUsageTime>18:00:00</nrg3:endUsageTime>
            </nrg3:DualValueSchedule>
          </nrg3:coolingSchedule>
          <nrg3:heatingSchedule>
            <nrg3:DualValueSchedule gml:id="B3_HeatingSchedule">
              <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/ScheduleTypeValue.xml">weekDay</nrg3:type>
              <nrg3:idleValue uom="Cel">18.0</nrg3:idleValue>
              <nrg3:usageValue uom="Cel">21.0</nrg3:usageValue>
              <nrg3:startUsageTime>07:00:00</nrg3:startUsageTime>
              <nrg3:endUsageTime>18:00:00</nrg3:endUsageTime>
            </nrg3:DualValueSchedule>
          </nrg3:heatingSchedule>
          <nrg3:ventilationSchedule>
            <nrg3:CompositeSchedule gml:id="B3_VentSchedule">
              <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/ScheduleTypeValue.xml">typicalWeek</nrg3:type>
              <nrg3:scheduleComponent>
                <nrg3:ScheduleComponent gml:id="B3_VentComp">
                  <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/ScheduleTypeValue.xml">weekDay</nrg3:type>
                  <nrg3:repetitions>5</nrg3:repetitions>
                  <nrg3:additionalGap unit="day">2</nrg3:additionalGap>
                  <nrg3:scheduleComponentMember xlink:href="#B3_HeatingSchedule"/>
                </nrg3:ScheduleComponent>
              </nrg3:scheduleComponent>
            </nrg3:CompositeSchedule>
          </nrg3:ventilationSchedule>
          <nrg3:occupiedBy>
            <nrg3:Occupants gml:id="B3_Occupants">
              <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/OccupantsTypeValue.xml">workers</nrg3:type>
              <nrg3:numberOfOccupants>18</nrg3:numberOfOccupants>
              <nrg3:heatDissipation uom="W">120.0</nrg3:heatDissipation>
              <nrg3:heatDissipationConvectiveFraction uom="ratio">0.5</nrg3:heatDissipationConvectiveFraction>
              <nrg3:heatDissipationLatentFraction uom="ratio">0.3</nrg3:heatDissipationLatentFraction>
              <nrg3:heatDissipationRadiantFraction uom="ratio">0.2</nrg3:heatDissipationRadiantFraction>
              <nrg3:occupancyRate xlink:href="#LIB_DualCooling"/>
              <nrg3:averageDietType codeSpace="../../citygml_ade_schemas/ade/codelists/DietTypeValue.xml">mixed</nrg3:averageDietType>
              <nrg3:averageIncomeLevel codeSpace="../../citygml_ade_schemas/ade/codelists/IncomeLevelValue.xml">medium</nrg3:averageIncomeLevel>
              <nrg3:averageInstructionLevel codeSpace="../../citygml_ade_schemas/ade/codelists/InstructionLevelValue.xml">tertiary</nrg3:averageInstructionLevel>
            </nrg3:Occupants>
          </nrg3:occupiedBy>
        </nrg3:UsageZone>
      </nrg3:usageZone>
      <!-- Building unit -->
      <nrg3:buildingUnit>
        <nrg3:BuildingUnit gml:id="B3_BuildingUnit">
          <nrg3:area>
            <nrg3:QualifiedArea>
              <nrg3:value uom="m2">360.0</nrg3:value>
              <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/AreaTypeValue.xml">netFloorArea</nrg3:type>
            </nrg3:QualifiedArea>
          </nrg3:area>
          <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/CurrentUseValue.xml">office</nrg3:type>
          <nrg3:numberOfRooms>12</nrg3:numberOfRooms>
          <nrg3:ownerName>Energieweg Immobilien GmbH</nrg3:ownerName>
          <nrg3:ownershipType codeSpace="../../citygml_ade_schemas/ade/codelists/OwnershipTypeValue.xml">corporation</nrg3:ownershipType>
          <nrg3:address>
            <core:Address>
              <core:xalAddress>
                <xAL:AddressDetails>
                  <xAL:Country>
                    <xAL:CountryName>Germany</xAL:CountryName>
                    <xAL:Locality Type="Town">
                      <xAL:LocalityName>Munich</xAL:LocalityName>
                      <xAL:Thoroughfare Type="Street">
                        <xAL:ThoroughfareNumber>12</xAL:ThoroughfareNumber>
                        <xAL:ThoroughfareName>Energieweg</xAL:ThoroughfareName>
                      </xAL:Thoroughfare>
                      <xAL:PostalCode><xAL:PostalCodeNumber>80331</xAL:PostalCodeNumber></xAL:PostalCode>
                    </xAL:Locality>
                  </xAL:Country>
                </xAL:AddressDetails>
              </core:xalAddress>
            </core:Address>
          </nrg3:address>
          <nrg3:energyPerformanceCertificate>
            <nrg3:EnergyPerformanceCertificate gml:id="B3_UnitEPC">
              <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/EnergyPerformanceCertificateTypeValue.xml">nationalScheme</nrg3:type>
              <nrg3:label>A</nrg3:label>
              <nrg3:value uom="kWh/m2/a">42.0</nrg3:value>
            </nrg3:EnergyPerformanceCertificate>
          </nrg3:energyPerformanceCertificate>
          <nrg3:refurbishmentMeasure>
            <nrg3:RefurbishmentMeasure gml:id="B3_UnitRefurb">
              <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/RefurbishmentMeasureTypeValue.xml">changedWindows</nrg3:type>
              <nrg3:endDate>2019-08-01</nrg3:endDate>
            </nrg3:RefurbishmentMeasure>
          </nrg3:refurbishmentMeasure>
          <nrg3:occupiedBy>
            <nrg3:Occupants gml:id="B3_UnitOccupants">
              <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/OccupantsTypeValue.xml">workers</nrg3:type>
              <nrg3:numberOfOccupants>18</nrg3:numberOfOccupants>
            </nrg3:Occupants>
          </nrg3:occupiedBy>
        </nrg3:BuildingUnit>
      </nrg3:buildingUnit>
    </bldg:Building>
  </core:cityObjectMember>

  <!-- ============================================================= -->
  <!-- Energy ADE libraries (top-level CityObjects)                  -->
  <!-- ============================================================= -->
  <core:cityObjectMember>
    <nrg3:MaterialLibrary gml:id="MaterialLibrary_1">
      <gml:name>Default material library</gml:name>
      <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/MediumTypeValue.xml">unknown</nrg3:type>
      <nrg3:source>manufacturer datasheets</nrg3:source>
      <nrg3:author>TU Delft 3D Geoinformation</nrg3:author>
      <nrg3:libraryMember>
        <nrg3:SolidMaterial gml:id="LIB_Insulation">
          <nrg3:libraryCode>EPS-035</nrg3:libraryCode>
          <nrg3:thermalConductivity uom="W/K/m">0.035</nrg3:thermalConductivity>
          <nrg3:density uom="kg/m3">30.0</nrg3:density>
          <nrg3:specificHeatCapacity uom="J/kg/K">1450.0</nrg3:specificHeatCapacity>
          <nrg3:permeance uom="kg/(s*m2*Pa)">2.0E-9</nrg3:permeance>
          <nrg3:porosity uom="ratio">0.95</nrg3:porosity>
          <nrg3:embodiedEnergy uom="MJ/kg">88.0</nrg3:embodiedEnergy>
          <nrg3:embodiedCarbon uom="kg">3.3</nrg3:embodiedCarbon>
        </nrg3:SolidMaterial>
      </nrg3:libraryMember>
      <nrg3:libraryMember>
        <nrg3:Gas gml:id="LIB_AirGap">
          <nrg3:libraryCode>AIR-GAP-20mm</nrg3:libraryCode>
          <nrg3:isVentilated>false</nrg3:isVentilated>
          <nrg3:rValue uom="m2*K/W">0.18</nrg3:rValue>
        </nrg3:Gas>
      </nrg3:libraryMember>
    </nrg3:MaterialLibrary>
  </core:cityObjectMember>

  <core:cityObjectMember>
    <nrg3:LayeredConstructionLibrary gml:id="LayeredConstructionLibrary_1">
      <gml:name>Default construction library</gml:name>
      <nrg3:author>TU Delft 3D Geoinformation</nrg3:author>
      <nrg3:libraryMember>
        <nrg3:LayeredConstruction gml:id="LIB_WindowConstruction">
          <nrg3:libraryCode>WIN-2PANE</nrg3:libraryCode>
          <nrg3:uValue uom="W/K/m2">1.1</nrg3:uValue>
          <nrg3:gValue uom="ratio">0.6</nrg3:gValue>
          <nrg3:glazingRatio uom="ratio">0.8</nrg3:glazingRatio>
          <nrg3:transmittance>
            <nrg3:Transmittance>
              <nrg3:fraction uom="ratio">0.7</nrg3:fraction>
              <nrg3:wavelengthRange>visible</nrg3:wavelengthRange>
            </nrg3:Transmittance>
          </nrg3:transmittance>
          <nrg3:layer>
            <nrg3:Layer gml:id="LIB_GlassLayer">
              <nrg3:thickness uom="m">0.004</nrg3:thickness>
              <nrg3:material xlink:href="#LIB_AirGap"/>
            </nrg3:Layer>
          </nrg3:layer>
        </nrg3:LayeredConstruction>
      </nrg3:libraryMember>
      <nrg3:libraryMember>
        <nrg3:ReverseLayeredConstruction gml:id="LIB_ReverseConstruction">
          <nrg3:baseLayeredConstruction xlink:href="#LIB_WindowConstruction"/>
        </nrg3:ReverseLayeredConstruction>
      </nrg3:libraryMember>
    </nrg3:LayeredConstructionLibrary>
  </core:cityObjectMember>

  <core:cityObjectMember>
    <nrg3:ScheduleLibrary gml:id="ScheduleLibrary_1">
      <gml:name>Default schedule library</gml:name>
      <nrg3:author>TU Delft 3D Geoinformation</nrg3:author>
      <nrg3:libraryMember>
        <nrg3:DualValueSchedule gml:id="LIB_DualCooling">
          <nrg3:libraryCode>COOL-OFFICE</nrg3:libraryCode>
          <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/ScheduleTypeValue.xml">weekDay</nrg3:type>
          <nrg3:idleValue uom="ratio">0.0</nrg3:idleValue>
          <nrg3:usageValue uom="ratio">1.0</nrg3:usageValue>
          <nrg3:startUsageTime>08:00:00</nrg3:startUsageTime>
          <nrg3:endUsageTime>18:00:00</nrg3:endUsageTime>
        </nrg3:DualValueSchedule>
      </nrg3:libraryMember>
      <nrg3:libraryMember>
        <nrg3:AtomicSchedule gml:id="LIB_AtomicConst">
          <nrg3:libraryCode>CONST-1</nrg3:libraryCode>
          <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/ScheduleTypeValue.xml">year</nrg3:type>
          <nrg3:startTime>00:00:00</nrg3:startTime>
          <nrg3:startDay>1</nrg3:startDay>
          <nrg3:startMonth>1</nrg3:startMonth>
          <nrg3:startYear>2023</nrg3:startYear>
          <nrg3:temporalExtent unit="year">1</nrg3:temporalExtent>
          <nrg3:constantValue uom="ratio">1.0</nrg3:constantValue>
        </nrg3:AtomicSchedule>
      </nrg3:libraryMember>
      <nrg3:libraryMember>
        <nrg3:AtomicSchedule gml:id="LIB_AtomicSensor">
          <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/ScheduleTypeValue.xml">year</nrg3:type>
          <nrg3:timeSeries>
            <nrg3:SensorConnection gml:id="LIB_Sensor">
              <nrg3:acquisitionMethod codeSpace="../../citygml_ade_schemas/ade/codelists/AcquisitionMethodValue.xml">measurement</nrg3:acquisitionMethod>
              <nrg3:interpolationType>instantaneousTotal</nrg3:interpolationType>
              <nrg3:temporalExtent unit="year">1</nrg3:temporalExtent>
              <nrg3:connectionType codeSpace="../../citygml_ade_schemas/ade/codelists/SensorConnectionTypeValue.xml">SensorThings</nrg3:connectionType>
              <nrg3:observationProperty>indoorTemperature</nrg3:observationProperty>
              <nrg3:uom uom="Cel"/>
              <nrg3:sensorID>sensor-77</nrg3:sensorID>
              <nrg3:sensorName>OfficeTempSensor</nrg3:sensorName>
              <nrg3:observationID>obs-1001</nrg3:observationID>
              <nrg3:datastreamID>ds-2002</nrg3:datastreamID>
              <nrg3:baseURL>https://example.org/sta/v1.1</nrg3:baseURL>
              <nrg3:authType codeSpace="../../citygml_ade_schemas/ade/codelists/AuthenticationTypeValue.xml">basic</nrg3:authType>
              <nrg3:mqttServer>tcp://example.org:1883</nrg3:mqttServer>
              <nrg3:mqttTopic>v1.1/Datastreams(2002)/Observations</nrg3:mqttTopic>
              <nrg3:linkToObservation>https://example.org/sta/v1.1/Observations(1001)</nrg3:linkToObservation>
              <nrg3:linkToSensorDescription>https://example.org/sta/v1.1/Sensors(77)</nrg3:linkToSensorDescription>
            </nrg3:SensorConnection>
          </nrg3:timeSeries>
        </nrg3:AtomicSchedule>
      </nrg3:libraryMember>
      <nrg3:libraryMember>
        <nrg3:CompositeSchedule gml:id="LIB_Composite">
          <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/ScheduleTypeValue.xml">typicalWeek</nrg3:type>
          <nrg3:scheduleComponent>
            <nrg3:ScheduleComponent gml:id="LIB_Comp1">
              <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/ScheduleTypeValue.xml">weekDay</nrg3:type>
              <nrg3:repetitions>5</nrg3:repetitions>
              <nrg3:additionalGap unit="day">2</nrg3:additionalGap>
              <nrg3:scheduleComponentMember xlink:href="#LIB_DualCooling"/>
            </nrg3:ScheduleComponent>
          </nrg3:scheduleComponent>
        </nrg3:CompositeSchedule>
      </nrg3:libraryMember>
    </nrg3:ScheduleLibrary>
  </core:cityObjectMember>

  <!-- ============================================================= -->
  <!-- Energy ADE WeatherStation + TypicalValuesTimeSeriesFile       -->
  <!-- ============================================================= -->
  <core:cityObjectMember>
    <nrg3:WeatherStation gml:id="WeatherStation_1">
      <gml:name>Munich City Weather Station</gml:name>
      <nrg3:weatherData>
        <nrg3:WeatherData gml:id="WS_GlobalRadiation">
          <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/WeatherDataTypeValue.xml">globalSolarIrradiance</nrg3:type>
          <nrg3:valueType codeSpace="../../citygml_ade_schemas/ade/codelists/WeatherValueTypeValue.xml">measured</nrg3:valueType>
          <nrg3:yearlyValue uom="kWh/m2">1180.0</nrg3:yearlyValue>
          <nrg3:timeDependentValues>
            <nrg3:TypicalValuesTimeSeriesFile gml:id="WS_RadiationTVSF">
              <nrg3:acquisitionMethod codeSpace="../../citygml_ade_schemas/ade/codelists/AcquisitionMethodValue.xml">measurement</nrg3:acquisitionMethod>
              <nrg3:interpolationType>averageInSucceedingInterval</nrg3:interpolationType>
              <nrg3:startTime>00:00:00</nrg3:startTime>
              <nrg3:startDay>1</nrg3:startDay>
              <nrg3:startMonth>1</nrg3:startMonth>
              <nrg3:uom uom="W/m2"/>
              <nrg3:fileURI>./timeseries/munich_global_radiation_TRY.csv</nrg3:fileURI>
              <nrg3:temporalExtent unit="year">1</nrg3:temporalExtent>
              <nrg3:timeInterval unit="hour">1</nrg3:timeInterval>
              <nrg3:numberOfHeaderLines>2</nrg3:numberOfHeaderLines>
              <nrg3:fieldSeparator>;</nrg3:fieldSeparator>
              <nrg3:recordSeparator>\n</nrg3:recordSeparator>
              <nrg3:decimalSymbol>,</nrg3:decimalSymbol>
              <nrg3:valueColumnNumber>3</nrg3:valueColumnNumber>
            </nrg3:TypicalValuesTimeSeriesFile>
          </nrg3:timeDependentValues>
          <nrg3:position>
            <gml:Point srsName="urn:ogc:def:crs:EPSG::25832" srsDimension="3"><gml:pos>691030 5334520 0</gml:pos></gml:Point>
          </nrg3:position>
        </nrg3:WeatherData>
      </nrg3:weatherData>
    </nrg3:WeatherStation>
  </core:cityObjectMember>

  <!-- ============================================================= -->
  <!-- Energy ADE UrbanFunctionArea (groups the three buildings)     -->
  <!-- ============================================================= -->
  <core:cityObjectMember>
    <nrg3:UrbanFunctionArea gml:id="UrbanFunctionArea_1">
      <gml:name>Energieweg residential-office block</gml:name>
      <grp:groupMember xlink:href="#Building_B1"/>
      <grp:groupMember xlink:href="#Building_B2"/>
      <grp:groupMember xlink:href="#Building_B3"/>
      <nrg3:type codeSpace="../../citygml_ade_schemas/ade/codelists/FunctionAreaTypeValue.xml">mixedUse</nrg3:type>
      <nrg3:code codeSpace="../../citygml_ade_schemas/ade/codelists/FunctionAreaCodeValue.xml">MU-01</nrg3:code>
    </nrg3:UrbanFunctionArea>
  </core:cityObjectMember>

</core:CityModel>
