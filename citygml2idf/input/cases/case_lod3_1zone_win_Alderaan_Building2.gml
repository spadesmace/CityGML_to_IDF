<?xml version='1.0' encoding='UTF-8'?>
<core:CityModel xmlns:app="http://www.opengis.net/citygml/appearance/2.0" xmlns:bldg="http://www.opengis.net/citygml/building/2.0" xmlns:brid="http://www.opengis.net/citygml/bridge/2.0" xmlns:core="http://www.opengis.net/citygml/2.0" xmlns:dem="http://www.opengis.net/citygml/relief/2.0" xmlns:frn="http://www.opengis.net/citygml/cityfurniture/2.0" xmlns:gen="http://www.opengis.net/citygml/generics/2.0" xmlns:gml="http://www.opengis.net/gml" xmlns:grp="http://www.opengis.net/citygml/cityobjectgroup/2.0" xmlns:luse="http://www.opengis.net/citygml/landuse/2.0" xmlns:nrg3="http://www.citygml.org/ade/energy/3.0" xmlns:pbase="http://www.opengis.net/citygml/profiles/base/2.0" xmlns:sch="http://www.ascc.net/xml/schematron" xmlns:smil20="http://www.w3.org/2001/SMIL20/" xmlns:smil20lang="http://www.w3.org/2001/SMIL20/Language" xmlns:tex="http://www.opengis.net/citygml/texturedsurface/2.0" xmlns:tran="http://www.opengis.net/citygml/transportation/2.0" xmlns:tun="http://www.opengis.net/citygml/tunnel/2.0" xmlns:veg="http://www.opengis.net/citygml/vegetation/2.0" xmlns:wtr="http://www.opengis.net/citygml/waterbody/2.0" xmlns:xAL="urn:oasis:names:tc:ciq:xsdschema:xAL:2.0" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><gml:description>This city model contains a set of "fantasy" buildings created by Giorgio Agugiaro (g.agugiaro@tudelft.nl)</gml:description>
	<gml:name>CityGML city of Alderaan</gml:name>
	<gml:boundedBy>
		<gml:Envelope srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
			<gml:lowerCorner>-80 -100 -5</gml:lowerCorner>
			<gml:upperCorner>160 100 50</gml:upperCorner>
		</gml:Envelope>
	</gml:boundedBy>
	<core:cityObjectMember>
		<nrg3:LayeredConstructionLibrary gml:id="id_layered_construction_library_1">
			<gml:description>This is Layered Construction Library 1</gml:description>
			<gml:name>Layered Construction Library 1</gml:name>
			<nrg3:type codeSpace="layered_construction_library_type_codeSpace">layered_construction_library_type</nrg3:type>
			<nrg3:source>TABULA</nrg3:source>
			<nrg3:author>Giorgio Agugiaro</nrg3:author>
			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="id_layered_construction_glazing_5">
					<gml:description>This is LayeredConstruction Glazing 5 (without layers as children objects)</gml:description>
					<gml:name>LayeredConstruction Glazing 5 (no layers)</gml:name>
					<nrg3:libraryCode codeSpace="layered_constr_library_codeSpace">layered_constr_library_code_5</nrg3:libraryCode>
					<nrg3:uValue uom="W/(K*m^2)">1.9</nrg3:uValue>
					<nrg3:glazingRatio uom="unit interval">0.95</nrg3:glazingRatio>
					<nrg3:emissivity>
						<nrg3:Emissivity>
							<nrg3:fraction uom="unit interval">0.1</nrg3:fraction>
							<nrg3:surface>outside</nrg3:surface>
						</nrg3:Emissivity>
					</nrg3:emissivity>
					<nrg3:emissivity>
						<nrg3:Emissivity>
							<nrg3:fraction uom="unit interval">0.2</nrg3:fraction>
							<nrg3:surface>inside</nrg3:surface>
						</nrg3:Emissivity>
					</nrg3:emissivity>
					<nrg3:reflectance>
						<nrg3:Reflectance>
							<nrg3:fraction uom="unit interval">0.2</nrg3:fraction>
							<nrg3:surface>outside</nrg3:surface>
							<nrg3:wavelengthRange>solar</nrg3:wavelengthRange>
						</nrg3:Reflectance>
					</nrg3:reflectance>
					<nrg3:reflectance>
						<nrg3:Reflectance>
							<nrg3:fraction uom="unit interval">0.3</nrg3:fraction>
							<nrg3:surface>inside</nrg3:surface>
							<nrg3:wavelengthRange>solar</nrg3:wavelengthRange>
						</nrg3:Reflectance>
					</nrg3:reflectance>
					<nrg3:transmittance>
						<nrg3:Transmittance>
							<nrg3:fraction uom="unit interval">0.7</nrg3:fraction>
							<nrg3:wavelengthRange>solar</nrg3:wavelengthRange>
						</nrg3:Transmittance>
					</nrg3:transmittance>
					<nrg3:transmittance>
						<nrg3:Transmittance>
							<nrg3:fraction uom="unit interval">0.5</nrg3:fraction>
							<nrg3:wavelengthRange>solar</nrg3:wavelengthRange>
						</nrg3:Transmittance>
					</nrg3:transmittance>
				</nrg3:LayeredConstruction>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="id_layered_construction_ground_1">
					<gml:description>This is LayeredConstruction Ground 1 (from inside to outside)</gml:description>
					<gml:name>LayeredConstruction Ground 1</gml:name>
					<nrg3:libraryCode codeSpace="layered_constr_library_codeSpace">layered_constr_library_code_1</nrg3:libraryCode>
					<nrg3:uValue uom="W/(K*m^2)">0.42</nrg3:uValue>
					<nrg3:glazingRatio uom="unit interval">0.95</nrg3:glazingRatio>
					<nrg3:emissivity>
						<nrg3:Emissivity>
							<nrg3:fraction uom="unit interval">0.1</nrg3:fraction>
							<nrg3:surface>outside</nrg3:surface>
						</nrg3:Emissivity>
					</nrg3:emissivity>
					<nrg3:emissivity>
						<nrg3:Emissivity>
							<nrg3:fraction uom="unit interval">0.2</nrg3:fraction>
							<nrg3:surface>inside</nrg3:surface>
						</nrg3:Emissivity>
					</nrg3:emissivity>
					<nrg3:reflectance>
						<nrg3:Reflectance>
							<nrg3:fraction uom="unit interval">0.2</nrg3:fraction>
							<nrg3:surface>outside</nrg3:surface>
							<nrg3:wavelengthRange>solar</nrg3:wavelengthRange>
						</nrg3:Reflectance>
					</nrg3:reflectance>
					<nrg3:reflectance>
						<nrg3:Reflectance>
							<nrg3:fraction uom="unit interval">0.3</nrg3:fraction>
							<nrg3:surface>inside</nrg3:surface>
							<nrg3:wavelengthRange>solar</nrg3:wavelengthRange>
						</nrg3:Reflectance>
					</nrg3:reflectance>
					<nrg3:transmittance>
						<nrg3:Transmittance>
							<nrg3:fraction uom="unit interval">0.7</nrg3:fraction>
							<nrg3:wavelengthRange>solar</nrg3:wavelengthRange>
						</nrg3:Transmittance>
					</nrg3:transmittance>
					<nrg3:transmittance>
						<nrg3:Transmittance>
							<nrg3:fraction uom="unit interval">0.5</nrg3:fraction>
							<nrg3:wavelengthRange>solar</nrg3:wavelengthRange>
						</nrg3:Transmittance>
					</nrg3:transmittance>
					<nrg3:layer>
						<nrg3:Layer gml:id="id_layer_1">
							<gml:description>This is Layer 1</gml:description>
							<gml:name>Layer 1</gml:name>
							<nrg3:thickness uom="mm">40</nrg3:thickness>
							<nrg3:material xlink:href="id_solid_material_1"/>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="id_layer_2">
							<gml:description>This is Layer 2</gml:description>
							<gml:name>Layer 2</gml:name>
							<nrg3:thickness uom="mm">45</nrg3:thickness>
							<nrg3:material xlink:href="id_solid_material_2"/>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="id_layer_3">
							<gml:description>This is Layer 3</gml:description>
							<gml:name>Layer 3</gml:name>
							<nrg3:thickness uom="mm">80</nrg3:thickness>
							<nrg3:material xlink:href="id_solid_material_3"/>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="id_layer_4">
							<gml:description>This is Layer 4</gml:description>
							<gml:name>Layer 4</gml:name>
							<nrg3:thickness uom="mm">5</nrg3:thickness>
							<nrg3:material xlink:href="id_solid_material_4"/>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="id_layer_5">
							<gml:description>This is Layer 5</gml:description>
							<gml:name>Layer 5</gml:name>
							<nrg3:thickness uom="mm">300</nrg3:thickness>
							<nrg3:material xlink:href="id_solid_material_5"/>
						</nrg3:Layer>
					</nrg3:layer>
				</nrg3:LayeredConstruction>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="id_layered_construction_iwall_4">
					<gml:description>This is LayeredConstruction Internal Wall 4 (from inside to outside)</gml:description>
					<gml:name>LayeredConstruction Internal Wall 4</gml:name>
					<nrg3:libraryCode codeSpace="layered_constr_library_codeSpace">layered_constr_library_code_4</nrg3:libraryCode>
					<nrg3:uValue uom="W/(K*m^2)">0.42</nrg3:uValue>
					<nrg3:glazingRatio uom="unit interval">0.95</nrg3:glazingRatio>
					<nrg3:emissivity>
						<nrg3:Emissivity>
							<nrg3:fraction uom="unit interval">0.1</nrg3:fraction>
							<nrg3:surface>outside</nrg3:surface>
						</nrg3:Emissivity>
					</nrg3:emissivity>
					<nrg3:emissivity>
						<nrg3:Emissivity>
							<nrg3:fraction uom="unit interval">0.2</nrg3:fraction>
							<nrg3:surface>inside</nrg3:surface>
						</nrg3:Emissivity>
					</nrg3:emissivity>
					<nrg3:reflectance>
						<nrg3:Reflectance>
							<nrg3:fraction uom="unit interval">0.2</nrg3:fraction>
							<nrg3:surface>outside</nrg3:surface>
							<nrg3:wavelengthRange>solar</nrg3:wavelengthRange>
						</nrg3:Reflectance>
					</nrg3:reflectance>
					<nrg3:reflectance>
						<nrg3:Reflectance>
							<nrg3:fraction uom="unit interval">0.3</nrg3:fraction>
							<nrg3:surface>inside</nrg3:surface>
							<nrg3:wavelengthRange>solar</nrg3:wavelengthRange>
						</nrg3:Reflectance>
					</nrg3:reflectance>
					<nrg3:transmittance>
						<nrg3:Transmittance>
							<nrg3:fraction uom="unit interval">0.7</nrg3:fraction>
							<nrg3:wavelengthRange>solar</nrg3:wavelengthRange>
						</nrg3:Transmittance>
					</nrg3:transmittance>
					<nrg3:transmittance>
						<nrg3:Transmittance>
							<nrg3:fraction uom="unit interval">0.5</nrg3:fraction>
							<nrg3:wavelengthRange>solar</nrg3:wavelengthRange>
						</nrg3:Transmittance>
					</nrg3:transmittance>
					<nrg3:layer>
						<nrg3:Layer gml:id="id_layer_16">
							<gml:description>This is Layer 16</gml:description>
							<gml:name>Layer 16</gml:name>
							<nrg3:thickness uom="mm">10</nrg3:thickness>
							<nrg3:material xlink:href="id_solid_material_16"/>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="id_layer_17">
							<gml:description>This is Layer 17</gml:description>
							<gml:name>Layer 17</gml:name>
							<nrg3:thickness uom="mm">200</nrg3:thickness>
							<nrg3:material xlink:href="id_solid_material_17"/>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="id_layer_18">
							<gml:description>This is Layer 18</gml:description>
							<gml:name>Layer 18</gml:name>
							<nrg3:thickness uom="mm">120</nrg3:thickness>
							<nrg3:material xlink:href="id_solid_material_18"/>
						</nrg3:Layer>
					</nrg3:layer>
				</nrg3:LayeredConstruction>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="id_layered_construction_roof_3">
					<gml:description>This is LayeredConstruction Roof 3 (from inside to outside)</gml:description>
					<gml:name>LayeredConstruction Roof 3</gml:name>
					<nrg3:libraryCode codeSpace="layered_constr_library_codeSpace">layered_constr_library_code_3</nrg3:libraryCode>
					<nrg3:uValue uom="W/(K*m^2)">0.39</nrg3:uValue>
					<nrg3:glazingRatio uom="unit interval">0.95</nrg3:glazingRatio>
					<nrg3:emissivity>
						<nrg3:Emissivity>
							<nrg3:fraction uom="unit interval">0.1</nrg3:fraction>
							<nrg3:surface>outside</nrg3:surface>
						</nrg3:Emissivity>
					</nrg3:emissivity>
					<nrg3:emissivity>
						<nrg3:Emissivity>
							<nrg3:fraction uom="unit interval">0.2</nrg3:fraction>
							<nrg3:surface>inside</nrg3:surface>
						</nrg3:Emissivity>
					</nrg3:emissivity>
					<nrg3:reflectance>
						<nrg3:Reflectance>
							<nrg3:fraction uom="unit interval">0.2</nrg3:fraction>
							<nrg3:surface>outside</nrg3:surface>
							<nrg3:wavelengthRange>solar</nrg3:wavelengthRange>
						</nrg3:Reflectance>
					</nrg3:reflectance>
					<nrg3:reflectance>
						<nrg3:Reflectance>
							<nrg3:fraction uom="unit interval">0.3</nrg3:fraction>
							<nrg3:surface>inside</nrg3:surface>
							<nrg3:wavelengthRange>solar</nrg3:wavelengthRange>
						</nrg3:Reflectance>
					</nrg3:reflectance>
					<nrg3:transmittance>
						<nrg3:Transmittance>
							<nrg3:fraction uom="unit interval">0.7</nrg3:fraction>
							<nrg3:wavelengthRange>solar</nrg3:wavelengthRange>
						</nrg3:Transmittance>
					</nrg3:transmittance>
					<nrg3:transmittance>
						<nrg3:Transmittance>
							<nrg3:fraction uom="unit interval">0.5</nrg3:fraction>
							<nrg3:wavelengthRange>solar</nrg3:wavelengthRange>
						</nrg3:Transmittance>
					</nrg3:transmittance>
					<nrg3:layer>
						<nrg3:Layer gml:id="id_layer_11">
							<gml:description>This is Layer 11</gml:description>
							<gml:name>Layer 11</gml:name>
							<nrg3:thickness uom="mm">10</nrg3:thickness>
							<nrg3:material xlink:href="id_solid_material_11"/>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="id_layer_12">
							<gml:description>This is Layer 12</gml:description>
							<gml:name>Layer 12</gml:name>
							<nrg3:thickness uom="mm">200</nrg3:thickness>
							<nrg3:material xlink:href="id_solid_material_12"/>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="id_layer_13">
							<gml:description>This is Layer 13</gml:description>
							<gml:name>Layer 13</gml:name>
							<nrg3:thickness uom="mm">30</nrg3:thickness>
							<nrg3:material xlink:href="id_gas_2"/>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="id_layer_14">
							<gml:description>This is Layer 14</gml:description>
							<gml:name>Layer 14</gml:name>
							<nrg3:thickness uom="mm">120</nrg3:thickness>
							<nrg3:material xlink:href="id_solid_material_14"/>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="id_layer_15">
							<gml:description>This is Layer 15</gml:description>
							<gml:name>Layer 15</gml:name>
							<nrg3:thickness uom="mm">5</nrg3:thickness>
							<nrg3:material xlink:href="id_solid_material_15"/>
						</nrg3:Layer>
					</nrg3:layer>
				</nrg3:LayeredConstruction>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:LayeredConstruction gml:id="id_layered_construction_wall_2">
					<gml:description>This is LayeredConstruction Wall 2 (from inside to outside)</gml:description>
					<gml:name>LayeredConstruction Wall 2</gml:name>
					<nrg3:libraryCode codeSpace="layered_constr_library_codeSpace">layered_constr_library_code_2</nrg3:libraryCode>
					<nrg3:uValue uom="W/(K*m^2)">0.31</nrg3:uValue>
					<nrg3:glazingRatio uom="unit interval">0.95</nrg3:glazingRatio>
					<nrg3:emissivity>
						<nrg3:Emissivity>
							<nrg3:fraction uom="unit interval">0.1</nrg3:fraction>
							<nrg3:surface>outside</nrg3:surface>
						</nrg3:Emissivity>
					</nrg3:emissivity>
					<nrg3:emissivity>
						<nrg3:Emissivity>
							<nrg3:fraction uom="unit interval">0.2</nrg3:fraction>
							<nrg3:surface>inside</nrg3:surface>
						</nrg3:Emissivity>
					</nrg3:emissivity>
					<nrg3:reflectance>
						<nrg3:Reflectance>
							<nrg3:fraction uom="unit interval">0.2</nrg3:fraction>
							<nrg3:surface>outside</nrg3:surface>
							<nrg3:wavelengthRange>solar</nrg3:wavelengthRange>
						</nrg3:Reflectance>
					</nrg3:reflectance>
					<nrg3:reflectance>
						<nrg3:Reflectance>
							<nrg3:fraction uom="unit interval">0.3</nrg3:fraction>
							<nrg3:surface>inside</nrg3:surface>
							<nrg3:wavelengthRange>solar</nrg3:wavelengthRange>
						</nrg3:Reflectance>
					</nrg3:reflectance>
					<nrg3:transmittance>
						<nrg3:Transmittance>
							<nrg3:fraction uom="unit interval">0.7</nrg3:fraction>
							<nrg3:wavelengthRange>solar</nrg3:wavelengthRange>
						</nrg3:Transmittance>
					</nrg3:transmittance>
					<nrg3:transmittance>
						<nrg3:Transmittance>
							<nrg3:fraction uom="unit interval">0.5</nrg3:fraction>
							<nrg3:wavelengthRange>solar</nrg3:wavelengthRange>
						</nrg3:Transmittance>
					</nrg3:transmittance>
					<nrg3:layer>
						<nrg3:Layer gml:id="id_layer_6">
							<gml:description>This is Layer 6</gml:description>
							<gml:name>Layer 6</gml:name>
							<nrg3:thickness uom="mm">10</nrg3:thickness>
							<nrg3:material xlink:href="id_solid_material_6"/>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="id_layer_7">
							<gml:description>This is Layer 7</gml:description>
							<gml:name>Layer 7</gml:name>
							<nrg3:thickness uom="mm">300</nrg3:thickness>
							<nrg3:material xlink:href="id_solid_material_7"/>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="id_layer_8">
							<gml:description>This is Layer 8</gml:description>
							<gml:name>Layer 8</gml:name>
							<nrg3:thickness uom="mm">30</nrg3:thickness>
							<nrg3:material xlink:href="id_gas_1"/>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="id_layer_9">
							<gml:description>This is Layer 9</gml:description>
							<gml:name>Layer 9</gml:name>
							<nrg3:thickness uom="mm">80</nrg3:thickness>
							<nrg3:material xlink:href="id_solid_material_9"/>
						</nrg3:Layer>
					</nrg3:layer>
					<nrg3:layer>
						<nrg3:Layer gml:id="id_layer_10">
							<gml:description>This is Layer 10</gml:description>
							<gml:name>Layer 10</gml:name>
							<nrg3:thickness uom="mm">20</nrg3:thickness>
							<nrg3:material xlink:href="id_solid_material_10"/>
						</nrg3:Layer>
					</nrg3:layer>
				</nrg3:LayeredConstruction>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:ReverseLayeredConstruction gml:id="id_reverse_layered_construction_ground_1">
					<gml:description>ReverseLayeredConstruction Ground 1 (from inside to outside) (reverse the order of the layers of the linked LayeredConstruction)</gml:description>
					<gml:name>ReverseLayeredConstruction Ground 1</gml:name>
					<nrg3:baseLayeredConstruction xlink:href="#id_layered_construction_ground_1"/>
				</nrg3:ReverseLayeredConstruction>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:ReverseLayeredConstruction gml:id="id_reverse_layered_construction_iwall_4">
					<gml:description>ReverseLayeredConstruction Internal Wall 4 (from inside to outside) (reverse the order of the layers of the linked LayeredConstruction)</gml:description>
					<gml:name>ReverseLayeredConstruction Internal Wall 4</gml:name>
					<nrg3:baseLayeredConstruction xlink:href="#id_layered_construction_iwall_4"/>
				</nrg3:ReverseLayeredConstruction>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:ReverseLayeredConstruction gml:id="id_reverse_layered_construction_iwall_4bis">
					<gml:description>ReverseLayeredConstruction Internal Wall 4bis</gml:description>
					<gml:name>ReverseLayeredConstruction Internal Wall 4bis</gml:name>
					<nrg3:baseLayeredConstruction xlink:href="#id_layered_construction_iwall_4"/>
				</nrg3:ReverseLayeredConstruction>
			</nrg3:libraryMember>
		</nrg3:LayeredConstructionLibrary>
	</core:cityObjectMember>
	<core:cityObjectMember>
		<nrg3:MaterialLibrary gml:id="id_material_library_1">
			<gml:description>This is Material Library 1</gml:description>
			<gml:name>Material Library 1</gml:name>
			<nrg3:type codeSpace="material_library_type_codeSpace">material_library_type</nrg3:type>
			<nrg3:source>TABULA</nrg3:source>
			<nrg3:author>Giorgio Agugiaro</nrg3:author>
			<nrg3:libraryMember>
				<nrg3:Gas gml:id="id_gas_1">
					<gml:description>This is Gas 1</gml:description>
					<gml:name>Gas 1</gml:name>
					<nrg3:libraryCode codeSpace="gascode_codeSpace">gas_code_1</nrg3:libraryCode>
					<nrg3:isVentilated>false</nrg3:isVentilated>
					<nrg3:rValue uom="J/K/mol">8.314</nrg3:rValue>
				</nrg3:Gas>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:Gas gml:id="id_gas_2">
					<gml:description>This is Gas 2</gml:description>
					<gml:name>Gas 2</gml:name>
					<nrg3:libraryCode codeSpace="gascode_codeSpace">gas_code_2</nrg3:libraryCode>
					<nrg3:isVentilated>false</nrg3:isVentilated>
					<nrg3:rValue uom="J/K/mol">8.314</nrg3:rValue>
				</nrg3:Gas>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:SolidMaterial gml:id="id_solid_material_1">
					<gml:description>This is SolidMaterial 1</gml:description>
					<gml:name>SolidMaterial 1</gml:name>
					<nrg3:libraryCode codeSpace="gascode_codeSpace">solid_material_code_1</nrg3:libraryCode>
					<nrg3:thermalConductivity uom="W/(K*m)">3.5</nrg3:thermalConductivity>
					<nrg3:density uom="kg/m^3">2500</nrg3:density>
					<nrg3:specificHeatCapacity uom="J/(kg*K)">0.9</nrg3:specificHeatCapacity>
					<nrg3:permeance uom="xxx">0.9</nrg3:permeance>
					<nrg3:porosity uom="ratio">0.05</nrg3:porosity>
					<nrg3:embodiedEnergy uom="kWh/kg">15.4</nrg3:embodiedEnergy>
					<nrg3:embodiedCarbon uom="kgCO2/kg">1.9</nrg3:embodiedCarbon>
				</nrg3:SolidMaterial>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:SolidMaterial gml:id="id_solid_material_2">
					<gml:description>This is SolidMaterial 2</gml:description>
					<gml:name>SolidMaterial 2</gml:name>
					<nrg3:libraryCode codeSpace="gascode_codeSpace">solid_material_code_2</nrg3:libraryCode>
					<nrg3:thermalConductivity uom="W/(K*m)">1.4</nrg3:thermalConductivity>
					<nrg3:density uom="kg/m^3">2000</nrg3:density>
					<nrg3:specificHeatCapacity uom="J/(kg*K)">0.9</nrg3:specificHeatCapacity>
					<nrg3:permeance uom="xxx">0.9</nrg3:permeance>
					<nrg3:porosity uom="ratio">0.1</nrg3:porosity>
					<nrg3:embodiedEnergy uom="kWh/kg">15.1</nrg3:embodiedEnergy>
					<nrg3:embodiedCarbon uom="kgCO2/kg">1.2</nrg3:embodiedCarbon>
				</nrg3:SolidMaterial>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:SolidMaterial gml:id="id_solid_material_3">
					<gml:description>This is SolidMaterial 3</gml:description>
					<gml:name>SolidMaterial 3</gml:name>
					<nrg3:libraryCode codeSpace="gascode_codeSpace">solid_material_code_3</nrg3:libraryCode>
					<nrg3:thermalConductivity uom="W/(K*m)">0.04</nrg3:thermalConductivity>
					<nrg3:density uom="kg/m^3">20</nrg3:density>
					<nrg3:specificHeatCapacity uom="J/(kg*K)">0.9</nrg3:specificHeatCapacity>
					<nrg3:permeance uom="xxx">0.9</nrg3:permeance>
					<nrg3:porosity uom="ratio">0.01</nrg3:porosity>
					<nrg3:embodiedEnergy uom="kWh/kg">2.1</nrg3:embodiedEnergy>
					<nrg3:embodiedCarbon uom="kgCO2/kg">2.1</nrg3:embodiedCarbon>
				</nrg3:SolidMaterial>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:SolidMaterial gml:id="id_solid_material_4">
					<gml:description>This is SolidMaterial 4</gml:description>
					<gml:name>SolidMaterial 4</gml:name>
					<nrg3:libraryCode codeSpace="gascode_codeSpace">solid_material_code_4</nrg3:libraryCode>
					<nrg3:thermalConductivity uom="W/(K*m)">0.23</nrg3:thermalConductivity>
					<nrg3:density uom="kg/m^3">1100</nrg3:density>
					<nrg3:specificHeatCapacity uom="J/(kg*K)">0.9</nrg3:specificHeatCapacity>
					<nrg3:permeance uom="xxx">0.9</nrg3:permeance>
					<nrg3:porosity uom="ratio">0.01</nrg3:porosity>
					<nrg3:embodiedEnergy uom="kWh/kg">9.8</nrg3:embodiedEnergy>
					<nrg3:embodiedCarbon uom="kgCO2/kg">7.3</nrg3:embodiedCarbon>
				</nrg3:SolidMaterial>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:SolidMaterial gml:id="id_solid_material_5">
					<gml:description>This is SolidMaterial 5</gml:description>
					<gml:name>SolidMaterial 5</gml:name>
					<nrg3:libraryCode codeSpace="gascode_codeSpace">solid_material_code_5</nrg3:libraryCode>
					<nrg3:thermalConductivity uom="W/(K*m)">2.3</nrg3:thermalConductivity>
					<nrg3:density uom="kg/m^3">2300</nrg3:density>
					<nrg3:specificHeatCapacity uom="J/(kg*K)">0.9</nrg3:specificHeatCapacity>
					<nrg3:permeance uom="xxx">0.9</nrg3:permeance>
					<nrg3:porosity uom="ratio">0.1</nrg3:porosity>
					<nrg3:embodiedEnergy uom="kWh/kg">0</nrg3:embodiedEnergy>
					<nrg3:embodiedCarbon uom="kgCO2/kg">2.8</nrg3:embodiedCarbon>
				</nrg3:SolidMaterial>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:SolidMaterial gml:id="id_solid_material_6">
					<gml:description>This is SolidMaterial 6</gml:description>
					<gml:name>SolidMaterial 6</gml:name>
					<nrg3:libraryCode codeSpace="gascode_codeSpace">solid_material_code_6</nrg3:libraryCode>
					<nrg3:thermalConductivity uom="W/(K*m)">0.7</nrg3:thermalConductivity>
					<nrg3:density uom="kg/m^3">1400</nrg3:density>
					<nrg3:specificHeatCapacity uom="J/(kg*K)">0.9</nrg3:specificHeatCapacity>
					<nrg3:permeance uom="xxx">0.9</nrg3:permeance>
					<nrg3:porosity uom="ratio">0.05</nrg3:porosity>
					<nrg3:embodiedEnergy uom="kWh/kg">8</nrg3:embodiedEnergy>
					<nrg3:embodiedCarbon uom="kgCO2/kg">3.3</nrg3:embodiedCarbon>
				</nrg3:SolidMaterial>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:SolidMaterial gml:id="id_solid_material_7">
					<gml:description>This is SolidMaterial 7</gml:description>
					<gml:name>SolidMaterial 7</gml:name>
					<nrg3:libraryCode codeSpace="gascode_codeSpace">solid_material_code_7</nrg3:libraryCode>
					<nrg3:thermalConductivity uom="W/(K*m)">0.8</nrg3:thermalConductivity>
					<nrg3:density uom="kg/m^3">1800</nrg3:density>
					<nrg3:specificHeatCapacity uom="J/(kg*K)">0.9</nrg3:specificHeatCapacity>
					<nrg3:permeance uom="xxx">0.9</nrg3:permeance>
					<nrg3:porosity uom="ratio">0.05</nrg3:porosity>
					<nrg3:embodiedEnergy uom="kWh/kg">2.2</nrg3:embodiedEnergy>
					<nrg3:embodiedCarbon uom="kgCO2/kg">1.4</nrg3:embodiedCarbon>
				</nrg3:SolidMaterial>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:SolidMaterial gml:id="id_solid_material_9">
					<gml:description>This is SolidMaterial 9</gml:description>
					<gml:name>SolidMaterial 9</gml:name>
					<nrg3:libraryCode codeSpace="gascode_codeSpace">solid_material_code_9</nrg3:libraryCode>
					<nrg3:thermalConductivity uom="W/(K*m)">0.035</nrg3:thermalConductivity>
					<nrg3:density uom="kg/m^3">20</nrg3:density>
					<nrg3:specificHeatCapacity uom="J/(kg*K)">0.9</nrg3:specificHeatCapacity>
					<nrg3:permeance uom="xxx">0.9</nrg3:permeance>
					<nrg3:porosity uom="ratio">0.01</nrg3:porosity>
					<nrg3:embodiedEnergy uom="kWh/kg">6.9</nrg3:embodiedEnergy>
					<nrg3:embodiedCarbon uom="kgCO2/kg">6.7</nrg3:embodiedCarbon>
				</nrg3:SolidMaterial>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:SolidMaterial gml:id="id_solid_material_10">
					<gml:description>This is SolidMaterial 10</gml:description>
					<gml:name>SolidMaterial 10</gml:name>
					<nrg3:libraryCode codeSpace="gascode_codeSpace">solid_material_code_10</nrg3:libraryCode>
					<nrg3:thermalConductivity uom="W/(K*m)">0.87</nrg3:thermalConductivity>
					<nrg3:density uom="kg/m^3">1800</nrg3:density>
					<nrg3:specificHeatCapacity uom="J/(kg*K)">0.9</nrg3:specificHeatCapacity>
					<nrg3:permeance uom="xxx">0.9</nrg3:permeance>
					<nrg3:porosity uom="ratio">0.05</nrg3:porosity>
					<nrg3:embodiedEnergy uom="kWh/kg">6.7</nrg3:embodiedEnergy>
					<nrg3:embodiedCarbon uom="kgCO2/kg">6.9</nrg3:embodiedCarbon>
				</nrg3:SolidMaterial>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:SolidMaterial gml:id="id_solid_material_11">
					<gml:description>This is SolidMaterial 11</gml:description>
					<gml:name>SolidMaterial 11</gml:name>
					<nrg3:libraryCode codeSpace="gascode_codeSpace">solid_material_code_11</nrg3:libraryCode>
					<nrg3:thermalConductivity uom="W/(K*m)">0.7</nrg3:thermalConductivity>
					<nrg3:density uom="kg/m^3">1400</nrg3:density>
					<nrg3:specificHeatCapacity uom="J/(kg*K)">0.9</nrg3:specificHeatCapacity>
					<nrg3:permeance uom="xxx">0.9</nrg3:permeance>
					<nrg3:porosity uom="ratio">0.05</nrg3:porosity>
					<nrg3:embodiedEnergy uom="kWh/kg">14.9</nrg3:embodiedEnergy>
					<nrg3:embodiedCarbon uom="kgCO2/kg">3.4</nrg3:embodiedCarbon>
				</nrg3:SolidMaterial>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:SolidMaterial gml:id="id_solid_material_12">
					<gml:description>This is SolidMaterial 12</gml:description>
					<gml:name>SolidMaterial 12</gml:name>
					<nrg3:libraryCode codeSpace="gascode_codeSpace">solid_material_code_12</nrg3:libraryCode>
					<nrg3:thermalConductivity uom="W/(K*m)">2.3</nrg3:thermalConductivity>
					<nrg3:density uom="kg/m^3">2400</nrg3:density>
					<nrg3:specificHeatCapacity uom="J/(kg*K)">0.9</nrg3:specificHeatCapacity>
					<nrg3:permeance uom="xxx">0.9</nrg3:permeance>
					<nrg3:porosity uom="ratio">0.1</nrg3:porosity>
					<nrg3:embodiedEnergy uom="kWh/kg">11.9</nrg3:embodiedEnergy>
					<nrg3:embodiedCarbon uom="kgCO2/kg">1.7</nrg3:embodiedCarbon>
				</nrg3:SolidMaterial>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:SolidMaterial gml:id="id_solid_material_14">
					<gml:description>This is SolidMaterial 14</gml:description>
					<gml:name>SolidMaterial 14</gml:name>
					<nrg3:libraryCode codeSpace="gascode_codeSpace">solid_material_code_14</nrg3:libraryCode>
					<nrg3:thermalConductivity uom="W/(K*m)">0.04</nrg3:thermalConductivity>
					<nrg3:density uom="kg/m^3">110</nrg3:density>
					<nrg3:specificHeatCapacity uom="J/(kg*K)">0.9</nrg3:specificHeatCapacity>
					<nrg3:permeance uom="xxx">0.9</nrg3:permeance>
					<nrg3:porosity uom="ratio">0.01</nrg3:porosity>
					<nrg3:embodiedEnergy uom="kWh/kg">19.9</nrg3:embodiedEnergy>
					<nrg3:embodiedCarbon uom="kgCO2/kg">1.4</nrg3:embodiedCarbon>
				</nrg3:SolidMaterial>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:SolidMaterial gml:id="id_solid_material_15">
					<gml:description>This is SolidMaterial 15</gml:description>
					<gml:name>SolidMaterial 15</gml:name>
					<nrg3:libraryCode codeSpace="gascode_codeSpace">solid_material_code_15</nrg3:libraryCode>
					<nrg3:thermalConductivity uom="W/(K*m)">0.23</nrg3:thermalConductivity>
					<nrg3:density uom="kg/m^3">1100</nrg3:density>
					<nrg3:specificHeatCapacity uom="J/(kg*K)">0.9</nrg3:specificHeatCapacity>
					<nrg3:permeance uom="xxx">0.9</nrg3:permeance>
					<nrg3:porosity uom="ratio">0.05</nrg3:porosity>
					<nrg3:embodiedEnergy uom="kWh/kg">19.2</nrg3:embodiedEnergy>
					<nrg3:embodiedCarbon uom="kgCO2/kg">9.8</nrg3:embodiedCarbon>
				</nrg3:SolidMaterial>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:SolidMaterial gml:id="id_solid_material_16">
					<gml:description>This is SolidMaterial 16</gml:description>
					<gml:name>SolidMaterial 16</gml:name>
					<nrg3:libraryCode codeSpace="gascode_codeSpace">solid_material_code_16</nrg3:libraryCode>
					<nrg3:thermalConductivity uom="W/(K*m)">0.7</nrg3:thermalConductivity>
					<nrg3:density uom="kg/m^3">1400</nrg3:density>
					<nrg3:specificHeatCapacity uom="J/(kg*K)">0.9</nrg3:specificHeatCapacity>
					<nrg3:permeance uom="xxx">0.9</nrg3:permeance>
					<nrg3:porosity uom="ratio">0.05</nrg3:porosity>
					<nrg3:embodiedEnergy uom="kWh/kg">14.1</nrg3:embodiedEnergy>
					<nrg3:embodiedCarbon uom="kgCO2/kg">3.9</nrg3:embodiedCarbon>
				</nrg3:SolidMaterial>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:SolidMaterial gml:id="id_solid_material_17">
					<gml:description>This is SolidMaterial 17</gml:description>
					<gml:name>SolidMaterial 17</gml:name>
					<nrg3:libraryCode codeSpace="gascode_codeSpace">solid_material_code_17</nrg3:libraryCode>
					<nrg3:thermalConductivity uom="W/(K*m)">0.8</nrg3:thermalConductivity>
					<nrg3:density uom="kg/m^3">1800</nrg3:density>
					<nrg3:specificHeatCapacity uom="J/(kg*K)">0.9</nrg3:specificHeatCapacity>
					<nrg3:permeance uom="xxx">0.9</nrg3:permeance>
					<nrg3:porosity uom="ratio">0.05</nrg3:porosity>
					<nrg3:embodiedEnergy uom="kWh/kg">1.1</nrg3:embodiedEnergy>
					<nrg3:embodiedCarbon uom="kgCO2/kg">5.2</nrg3:embodiedCarbon>
				</nrg3:SolidMaterial>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:SolidMaterial gml:id="id_solid_material_18">
					<gml:description>This is SolidMaterial 18</gml:description>
					<gml:name>SolidMaterial 18</gml:name>
					<nrg3:libraryCode codeSpace="gascode_codeSpace">solid_material_code_18</nrg3:libraryCode>
					<nrg3:thermalConductivity uom="W/(K*m)">0.7</nrg3:thermalConductivity>
					<nrg3:density uom="kg/m^3">1400</nrg3:density>
					<nrg3:specificHeatCapacity uom="J/(kg*K)">0.9</nrg3:specificHeatCapacity>
					<nrg3:permeance uom="xxx">0.9</nrg3:permeance>
					<nrg3:porosity uom="ratio">0.05</nrg3:porosity>
					<nrg3:embodiedEnergy uom="kWh/kg">9.4</nrg3:embodiedEnergy>
					<nrg3:embodiedCarbon uom="kgCO2/kg">0.5</nrg3:embodiedCarbon>
				</nrg3:SolidMaterial>
			</nrg3:libraryMember>
		</nrg3:MaterialLibrary>
	</core:cityObjectMember>
	<core:cityObjectMember>
		<nrg3:ScheduleLibrary gml:id="id_schedule_library_1">
			<gml:description>This is Schedule Library 1</gml:description>
			<gml:name>Schedule Library 1</gml:name>
			<nrg3:type codeSpace="schedule_library_type_codeSpace">schedule_library_type</nrg3:type>
			<nrg3:source>Coruscant Schedule Library</nrg3:source>
			<nrg3:author>Giorgio Agugiaro</nrg3:author>
			<nrg3:libraryMember>
				<nrg3:AtomicSchedule gml:id="id_atomic_schedule_1">
					<gml:description>This is AtomicSchedule 1 for a year, connected to a timeseries of 1 yearly value</gml:description>
					<gml:name>AtomicSchedule 1</gml:name>
					<nrg3:libraryCode codeSpace="schedule_library_codeSpace">atom_sched_code_1</nrg3:libraryCode>
					<nrg3:type codeSpace="schedule_type_codeSpace">year</nrg3:type>
					<nrg3:startTime>00:00:00</nrg3:startTime>
					<nrg3:startDay>1</nrg3:startDay>
					<nrg3:startMonth>1</nrg3:startMonth>
					<nrg3:temporalExtent unit="year">1</nrg3:temporalExtent>
					<nrg3:timeSeries>
						<nrg3:TypicalValuesTimeSeries gml:id="id_default_values_time_series_2">
							<gml:description>This is DefaultValuesTimeSeries 2</gml:description>
							<gml:name>DefaultValuesTimeSeries 2</gml:name>
							<nrg3:acquisitionMethod codeSpace="codespace_18">calibratedSimulation</nrg3:acquisitionMethod>
							<nrg3:interpolationType>discontinuous</nrg3:interpolationType>
							<nrg3:source>source_18</nrg3:source>
							<nrg3:temporalExtent unit="year">1</nrg3:temporalExtent>
							<nrg3:timeInterval unit="year">1</nrg3:timeInterval>
							<nrg3:valuesList uom="unit">100</nrg3:valuesList>
						</nrg3:TypicalValuesTimeSeries>
					</nrg3:timeSeries>
				</nrg3:AtomicSchedule>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:AtomicSchedule gml:id="id_atomic_schedule_2">
					<gml:description>This is AtomicSchedule 2 for a year, connected to a timeseries of 12 monthly values</gml:description>
					<gml:name>AtomicSchedule 2</gml:name>
					<nrg3:libraryCode codeSpace="schedule_library_codeSpace">atom_sched_code_2</nrg3:libraryCode>
					<nrg3:type codeSpace="schedule_type_codeSpace">year</nrg3:type>
					<nrg3:startTime>00:00:00</nrg3:startTime>
					<nrg3:startDay>1</nrg3:startDay>
					<nrg3:startMonth>1</nrg3:startMonth>
					<nrg3:temporalExtent unit="year">1</nrg3:temporalExtent>
					<nrg3:timeSeries>
						<nrg3:TypicalValuesTimeSeries gml:id="id_default_values_time_series_3">
							<gml:description>This is DefaultValuesTimeSeries 3</gml:description>
							<gml:name>DefaultValuesTimeSeries 3</gml:name>
							<nrg3:acquisitionMethod codeSpace="codespace_19">estimation</nrg3:acquisitionMethod>
							<nrg3:interpolationType>instantaneousTotal</nrg3:interpolationType>
							<nrg3:source>source_19</nrg3:source>
							<nrg3:temporalExtent unit="year">1</nrg3:temporalExtent>
							<nrg3:timeInterval unit="year">0.083</nrg3:timeInterval>
							<nrg3:valuesList uom="unit">101 102 103 104 105 106 107 108 109 110 111 112</nrg3:valuesList>
						</nrg3:TypicalValuesTimeSeries>
					</nrg3:timeSeries>
				</nrg3:AtomicSchedule>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:AtomicSchedule gml:id="id_atomic_schedule_3">
					<gml:description>This is AtomicSchedule 3 for a year, connected to a timeseries of 52 weekly values</gml:description>
					<gml:name>AtomicSchedule 3</gml:name>
					<nrg3:libraryCode codeSpace="schedule_library_codeSpace">atom_sched_code_3</nrg3:libraryCode>
					<nrg3:type codeSpace="schedule_type_codeSpace">year</nrg3:type>
					<nrg3:startTime>00:00:00</nrg3:startTime>
					<nrg3:startDay>1</nrg3:startDay>
					<nrg3:startMonth>1</nrg3:startMonth>
					<nrg3:temporalExtent unit="year">1</nrg3:temporalExtent>
					<nrg3:timeSeries>
						<nrg3:TypicalValuesTimeSeries gml:id="id_default_values_time_series_4">
							<gml:description>This is DefaultValuesTimeSeries 4</gml:description>
							<gml:name>DefaultValuesTimeSeries 4</gml:name>
							<nrg3:acquisitionMethod codeSpace="codespace_20">unknown</nrg3:acquisitionMethod>
							<nrg3:interpolationType>maximumInPrecedingInterval</nrg3:interpolationType>
							<nrg3:source>source_20</nrg3:source>
							<nrg3:temporalExtent unit="year">1</nrg3:temporalExtent>
							<nrg3:timeInterval unit="day">7</nrg3:timeInterval>
							<nrg3:valuesList uom="unit">1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52</nrg3:valuesList>
						</nrg3:TypicalValuesTimeSeries>
					</nrg3:timeSeries>
				</nrg3:AtomicSchedule>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:AtomicSchedule gml:id="id_atomic_schedule_4">
					<gml:description>This is AtomicSchedule 4 for a year, connected to a timeseries of 365 daily values</gml:description>
					<gml:name>AtomicSchedule 4</gml:name>
					<nrg3:libraryCode codeSpace="schedule_library_codeSpace">atom_sched_code_4</nrg3:libraryCode>
					<nrg3:type codeSpace="schedule_type_codeSpace">year</nrg3:type>
					<nrg3:startTime>00:00:00</nrg3:startTime>
					<nrg3:startDay>1</nrg3:startDay>
					<nrg3:startMonth>1</nrg3:startMonth>
					<nrg3:temporalExtent unit="year">1</nrg3:temporalExtent>
					<nrg3:timeSeries>
						<nrg3:TypicalValuesTimeSeries gml:id="id_default_values_time_series_5">
							<gml:description>This is DefaultValuesTimeSeries 5</gml:description>
							<gml:name>DefaultValuesTimeSeries 5</gml:name>
							<nrg3:acquisitionMethod codeSpace="codespace_21">simulation</nrg3:acquisitionMethod>
							<nrg3:interpolationType>continuous</nrg3:interpolationType>
							<nrg3:source>source_21</nrg3:source>
							<nrg3:temporalExtent unit="year">1</nrg3:temporalExtent>
							<nrg3:timeInterval unit="day">1</nrg3:timeInterval>
							<nrg3:valuesList uom="unit">1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255 256 257 258 259 260 261 262 263 264 265 266 267 268 269 270 271 272 273 274 275 276 277 278 279 280 281 282 283 284 285 286 287 288 289 290 291 292 293 294 295 296 297 298 299 300 301 302 303 304 305 306 307 308 309 310 311 312 313 314 315 316 317 318 319 320 321 322 323 324 325 326 327 328 329 330 331 332 333 334 335 336 337 338 339 340 341 342 343 344 345 346 347 348 349 350 351 352 353 354 355 356 357 358 359 360 361 362 363 364 365</nrg3:valuesList>
						</nrg3:TypicalValuesTimeSeries>
					</nrg3:timeSeries>
				</nrg3:AtomicSchedule>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:AtomicSchedule gml:id="id_atomic_schedule_5">
					<gml:description>This is AtomicSchedule 5 for a day, connected to a timeseries of 24 hourly values</gml:description>
					<gml:name>AtomicSchedule 5</gml:name>
					<nrg3:libraryCode codeSpace="schedule_library_codeSpace">atom_sched_code_5</nrg3:libraryCode>
					<nrg3:type codeSpace="schedule_type_codeSpace">year</nrg3:type>
					<nrg3:startTime>00:00:00</nrg3:startTime>
					<nrg3:temporalExtent unit="day">1</nrg3:temporalExtent>
					<nrg3:timeSeries>
						<nrg3:TypicalValuesTimeSeries gml:id="id_default_values_time_series_6">
							<gml:description>This is DefaultValuesTimeSeries 6</gml:description>
							<gml:name>DefaultValuesTimeSeries 6</gml:name>
							<nrg3:acquisitionMethod codeSpace="codespace_22">calibratedSimulation</nrg3:acquisitionMethod>
							<nrg3:interpolationType>discontinuous</nrg3:interpolationType>
							<nrg3:source>source_22</nrg3:source>
							<nrg3:temporalExtent unit="day">1</nrg3:temporalExtent>
							<nrg3:timeInterval unit="hour">1</nrg3:timeInterval>
							<nrg3:valuesList uom="unit">1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24</nrg3:valuesList>
						</nrg3:TypicalValuesTimeSeries>
					</nrg3:timeSeries>
				</nrg3:AtomicSchedule>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:AtomicSchedule gml:id="id_atomic_schedule_6">
					<gml:description>This is AtomicSchedule 6</gml:description>
					<gml:name>AtomicSchedule 6</gml:name>
					<nrg3:libraryCode codeSpace="schedule_library_codeSpace">atom_sched_code_6</nrg3:libraryCode>
					<nrg3:type codeSpace="schedule_type_codeSpace">weekDay</nrg3:type>
					<nrg3:startTime>00:00:00</nrg3:startTime>
					<nrg3:temporalExtent unit="day">1</nrg3:temporalExtent>
					<nrg3:timeSeries>
						<nrg3:TypicalValuesTimeSeries gml:id="id_default_values_time_series_7">
							<gml:description>This is DefaultValuesTimeSeries 7</gml:description>
							<gml:name>DefaultValuesTimeSeries 7</gml:name>
							<nrg3:acquisitionMethod codeSpace="codespace_23">estimation</nrg3:acquisitionMethod>
							<nrg3:interpolationType>instantaneousTotal</nrg3:interpolationType>
							<nrg3:source>source_23</nrg3:source>
							<nrg3:temporalExtent unit="day">1</nrg3:temporalExtent>
							<nrg3:timeInterval unit="hour">1</nrg3:timeInterval>
							<nrg3:valuesList uom="unit">1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24</nrg3:valuesList>
						</nrg3:TypicalValuesTimeSeries>
					</nrg3:timeSeries>
				</nrg3:AtomicSchedule>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:AtomicSchedule gml:id="id_atomic_schedule_7">
					<gml:description>This is AtomicSchedule 7</gml:description>
					<gml:name>AtomicSchedule 7</gml:name>
					<nrg3:libraryCode codeSpace="schedule_library_codeSpace">atom_sched_code_7</nrg3:libraryCode>
					<nrg3:type codeSpace="schedule_type_codeSpace">weekendDay</nrg3:type>
					<nrg3:startTime>00:00:00</nrg3:startTime>
					<nrg3:temporalExtent unit="day">1</nrg3:temporalExtent>
					<nrg3:timeSeries>
						<nrg3:TypicalValuesTimeSeries gml:id="id_default_values_time_series_8">
							<gml:description>This is DefaultValuesTimeSeries 8</gml:description>
							<gml:name>DefaultValuesTimeSeries 8</gml:name>
							<nrg3:acquisitionMethod codeSpace="codespace_24">unknown</nrg3:acquisitionMethod>
							<nrg3:interpolationType>maximumInPrecedingInterval</nrg3:interpolationType>
							<nrg3:source>source_24</nrg3:source>
							<nrg3:temporalExtent unit="day">1</nrg3:temporalExtent>
							<nrg3:timeInterval unit="hour">1</nrg3:timeInterval>
							<nrg3:valuesList uom="unit">11 12 13 14 15 16 17 18 19 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124</nrg3:valuesList>
						</nrg3:TypicalValuesTimeSeries>
					</nrg3:timeSeries>
				</nrg3:AtomicSchedule>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:AtomicSchedule gml:id="id_atomic_schedule_8">
					<gml:description>This is AtomicSchedule 8</gml:description>
					<gml:name>AtomicSchedule 8</gml:name>
					<nrg3:libraryCode codeSpace="schedule_library_codeSpace">atom_sched_code_8</nrg3:libraryCode>
					<nrg3:type codeSpace="schedule_type_codeSpace">typicalDay</nrg3:type>
					<nrg3:startTime>00:00:00</nrg3:startTime>
					<nrg3:temporalExtent unit="day">1</nrg3:temporalExtent>
					<nrg3:timeSeries>
						<nrg3:TypicalValuesTimeSeries gml:id="id_default_values_time_series_9">
							<gml:description>This is DefaultValuesTimeSeries 9</gml:description>
							<gml:name>DefaultValuesTimeSeries 9</gml:name>
							<nrg3:acquisitionMethod codeSpace="codespace_25">simulation</nrg3:acquisitionMethod>
							<nrg3:interpolationType>continuous</nrg3:interpolationType>
							<nrg3:source>source_25</nrg3:source>
							<nrg3:temporalExtent unit="day">1</nrg3:temporalExtent>
							<nrg3:timeInterval unit="hour">1</nrg3:timeInterval>
							<nrg3:valuesList uom="unit">11 12 13 14 15 16 17 18 19 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124</nrg3:valuesList>
						</nrg3:TypicalValuesTimeSeries>
					</nrg3:timeSeries>
				</nrg3:AtomicSchedule>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:AtomicSchedule gml:id="id_atomic_schedule_9">
					<gml:description>This is AtomicSchedule 9</gml:description>
					<gml:name>AtomicSchedule 9</gml:name>
					<nrg3:libraryCode codeSpace="schedule_library_codeSpace">atom_sched_code_9</nrg3:libraryCode>
					<nrg3:type codeSpace="schedule_type_codeSpace">typicalDay</nrg3:type>
					<nrg3:startTime>00:00:00</nrg3:startTime>
					<nrg3:temporalExtent unit="day">1</nrg3:temporalExtent>
					<nrg3:timeSeries>
						<nrg3:TypicalValuesTimeSeries gml:id="id_default_values_time_series_10">
							<gml:description>This is DefaultValuesTimeSeries 10</gml:description>
							<gml:name>DefaultValuesTimeSeries 10</gml:name>
							<nrg3:acquisitionMethod codeSpace="codespace_26">calibratedSimulation</nrg3:acquisitionMethod>
							<nrg3:interpolationType>discontinuous</nrg3:interpolationType>
							<nrg3:source>source_26</nrg3:source>
							<nrg3:temporalExtent unit="day">1</nrg3:temporalExtent>
							<nrg3:timeInterval unit="hour">1</nrg3:timeInterval>
							<nrg3:valuesList uom="unit">21 22 23 24 25 26 27 28 29 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224</nrg3:valuesList>
						</nrg3:TypicalValuesTimeSeries>
					</nrg3:timeSeries>
				</nrg3:AtomicSchedule>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:AtomicSchedule gml:id="id_atomic_schedule_10">
					<gml:description>This is AtomicSchedule 10</gml:description>
					<gml:name>AtomicSchedule 10</gml:name>
					<nrg3:libraryCode codeSpace="schedule_library_codeSpace">atom_sched_code_10</nrg3:libraryCode>
					<nrg3:type codeSpace="schedule_type_codeSpace">typicalDay</nrg3:type>
					<nrg3:startTime>00:00:00</nrg3:startTime>
					<nrg3:temporalExtent unit="day">1</nrg3:temporalExtent>
					<nrg3:timeSeries>
						<nrg3:TypicalValuesTimeSeries gml:id="id_default_values_time_series_11">
							<gml:description>This is DefaultValuesTimeSeries 11</gml:description>
							<gml:name>DefaultValuesTimeSeries 11</gml:name>
							<nrg3:acquisitionMethod codeSpace="codespace_27">estimation</nrg3:acquisitionMethod>
							<nrg3:interpolationType>instantaneousTotal</nrg3:interpolationType>
							<nrg3:source>source_27</nrg3:source>
							<nrg3:temporalExtent unit="day">1</nrg3:temporalExtent>
							<nrg3:timeInterval unit="hour">1</nrg3:timeInterval>
							<nrg3:valuesList uom="unit">31 32 33 34 35 36 37 38 39 310 311 312 313 314 315 316 317 318 319 320 321 322 323 324</nrg3:valuesList>
						</nrg3:TypicalValuesTimeSeries>
					</nrg3:timeSeries>
				</nrg3:AtomicSchedule>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:AtomicSchedule gml:id="id_atomic_schedule_11">
					<gml:description>This is AtomicSchedule 11</gml:description>
					<gml:name>AtomicSchedule 11</gml:name>
					<nrg3:libraryCode codeSpace="schedule_library_codeSpace">atom_sched_code_11</nrg3:libraryCode>
					<nrg3:type codeSpace="schedule_type_codeSpace">typicalDay</nrg3:type>
					<nrg3:startTime>00:00:00</nrg3:startTime>
					<nrg3:temporalExtent unit="day">1</nrg3:temporalExtent>
					<nrg3:timeSeries>
						<nrg3:TypicalValuesTimeSeries gml:id="id_default_values_time_series_12">
							<gml:description>This is DefaultValuesTimeSeries 12</gml:description>
							<gml:name>DefaultValuesTimeSeries 12</gml:name>
							<nrg3:acquisitionMethod codeSpace="codespace_28">unknown</nrg3:acquisitionMethod>
							<nrg3:interpolationType>maximumInPrecedingInterval</nrg3:interpolationType>
							<nrg3:source>source_28</nrg3:source>
							<nrg3:temporalExtent unit="day">1</nrg3:temporalExtent>
							<nrg3:timeInterval unit="hour">1</nrg3:timeInterval>
							<nrg3:valuesList uom="unit">41 42 43 44 45 46 47 48 49 410 411 412 413 414 415 416 417 418 419 420 421 422 423 424</nrg3:valuesList>
						</nrg3:TypicalValuesTimeSeries>
					</nrg3:timeSeries>
				</nrg3:AtomicSchedule>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:CompositeSchedule gml:id="id_composite_schedule_1">
					<gml:description>This is CompositeSchedule 1, for 1 typical week, composed of 5 typical days and 2 weekend days</gml:description>
					<gml:name>CompositeSchedule 1</gml:name>
					<nrg3:libraryCode codeSpace="schedule_library_codeSpace">comp_sched_code_1</nrg3:libraryCode>
					<nrg3:type codeSpace="schedule_type_codeSpace">week</nrg3:type>
					<nrg3:startTime>00:00:00</nrg3:startTime>
					<nrg3:temporalExtent unit="day">7</nrg3:temporalExtent>
					<nrg3:scheduleComponent>
						<nrg3:ScheduleComponent gml:id="id_schedule_component_1">
							<gml:description>This is ScheduleComponent 1</gml:description>
							<gml:name>ScheduleComponent 1 containing a repetition of 5 times a daily schedule of timeseries of 24 hourly values for a week day</gml:name>
							<nrg3:type codeSpace="schedule_type_codeSpace">weekDay</nrg3:type>
							<nrg3:repetitions>5</nrg3:repetitions>
							<nrg3:additionalGap unit="day">0</nrg3:additionalGap>
							<nrg3:scheduleComponentMember xlink:href="#id_atomic_schedule_6"/>
						</nrg3:ScheduleComponent>
					</nrg3:scheduleComponent>
					<nrg3:scheduleComponent>
						<nrg3:ScheduleComponent gml:id="id_schedule_component_2">
							<gml:description>This is ScheduleComponent 2</gml:description>
							<gml:name>ScheduleComponent 2 containing a repetition of 2 times a daily schedule of timeseries of 24 hourly values for a weekend day</gml:name>
							<nrg3:type codeSpace="schedule_type_codeSpace">weekendDay</nrg3:type>
							<nrg3:repetitions>2</nrg3:repetitions>
							<nrg3:additionalGap unit="day">0</nrg3:additionalGap>
							<nrg3:scheduleComponentMember xlink:href="#id_atomic_schedule_7"/>
						</nrg3:ScheduleComponent>
					</nrg3:scheduleComponent>
				</nrg3:CompositeSchedule>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:CompositeSchedule gml:id="id_composite_schedule_2">
					<gml:description>This is CompositeSchedule 2, for 1 year, composed of 4 seasons</gml:description>
					<gml:name>CompositeSchedule 2</gml:name>
					<nrg3:libraryCode codeSpace="schedule_library_codeSpace">comp_sched_code_2</nrg3:libraryCode>
					<nrg3:type codeSpace="schedule_type_codeSpace">week</nrg3:type>
					<nrg3:startTime>00:00:00</nrg3:startTime>
					<nrg3:temporalExtent unit="day">7</nrg3:temporalExtent>
					<nrg3:scheduleComponent>
						<nrg3:ScheduleComponent gml:id="id_schedule_component_3">
							<gml:description>This is ScheduleComponent 3</gml:description>
							<gml:name>ScheduleComponent 3, for the winter season, containing a repetition of 91 times of a typical day schedule of timeseries of 24 hourly values </gml:name>
							<nrg3:type codeSpace="schedule_type_codeSpace">winter</nrg3:type>
							<nrg3:repetitions>91</nrg3:repetitions>
							<nrg3:additionalGap unit="day">0</nrg3:additionalGap>
							<nrg3:scheduleComponentMember xlink:href="#id_atomic_schedule_8"/>
						</nrg3:ScheduleComponent>
					</nrg3:scheduleComponent>
					<nrg3:scheduleComponent>
						<nrg3:ScheduleComponent gml:id="id_schedule_component_4">
							<gml:description>This is ScheduleComponent 4</gml:description>
							<gml:name>ScheduleComponent 4, for the spring season, containing a repetition of 91 times of a typical day schedule of timeseries of 24 hourly values </gml:name>
							<nrg3:type codeSpace="schedule_type_codeSpace">spring</nrg3:type>
							<nrg3:repetitions>91</nrg3:repetitions>
							<nrg3:additionalGap unit="day">0</nrg3:additionalGap>
							<nrg3:scheduleComponentMember xlink:href="#id_atomic_schedule_9"/>
						</nrg3:ScheduleComponent>
					</nrg3:scheduleComponent>
					<nrg3:scheduleComponent>
						<nrg3:ScheduleComponent gml:id="id_schedule_component_5">
							<gml:description>This is ScheduleComponent 5</gml:description>
							<gml:name>ScheduleComponent 5, for the summer season, containing a repetition of 92 times of a typical day schedule of timeseries of 24 hourly values </gml:name>
							<nrg3:type codeSpace="schedule_type_codeSpace">summer</nrg3:type>
							<nrg3:repetitions>92</nrg3:repetitions>
							<nrg3:additionalGap unit="day">0</nrg3:additionalGap>
							<nrg3:scheduleComponentMember xlink:href="#id_atomic_schedule_10"/>
						</nrg3:ScheduleComponent>
					</nrg3:scheduleComponent>
					<nrg3:scheduleComponent>
						<nrg3:ScheduleComponent gml:id="id_schedule_component_6">
							<gml:description>This is ScheduleComponent 6</gml:description>
							<gml:name>ScheduleComponent 6, for the autumn season, containing a repetition of 91 times of a typical day schedule of timeseries of 24 hourly values </gml:name>
							<nrg3:type codeSpace="schedule_type_codeSpace">autumn</nrg3:type>
							<nrg3:repetitions>91</nrg3:repetitions>
							<nrg3:additionalGap unit="day">0</nrg3:additionalGap>
							<nrg3:scheduleComponentMember xlink:href="#id_atomic_schedule_11"/>
						</nrg3:ScheduleComponent>
					</nrg3:scheduleComponent>
				</nrg3:CompositeSchedule>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:CompositeSchedule gml:id="id_composite_schedule_3">
					<gml:description>This is CompositeSchedule 3, for 1 year, composed of 52 typical weeks, and using Xlinks</gml:description>
					<gml:name>CompositeSchedule 3</gml:name>
					<nrg3:libraryCode codeSpace="schedule_library_codeSpace">comp_sched_code_3</nrg3:libraryCode>
					<nrg3:type codeSpace="schedule_type_codeSpace">year</nrg3:type>
					<nrg3:startTime>00:00:00</nrg3:startTime>
					<nrg3:temporalExtent unit="year">1</nrg3:temporalExtent>
					<nrg3:scheduleComponent>
						<nrg3:ScheduleComponent gml:id="id_schedule_component_7">
							<gml:description>This is ScheduleComponent 7</gml:description>
							<gml:name>ScheduleComponent 7, for 1 year, composed of 52 typical weeks</gml:name>
							<nrg3:type codeSpace="schedule_type_codeSpace">typicalWeek</nrg3:type>
							<nrg3:repetitions>52</nrg3:repetitions>
							<nrg3:additionalGap unit="day">0</nrg3:additionalGap>
							<nrg3:scheduleComponentMember xlink:href="#id_composite_schedule_1"/>
						</nrg3:ScheduleComponent>
					</nrg3:scheduleComponent>
				</nrg3:CompositeSchedule>
			 </nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:CompositeSchedule gml:id="id_composite_schedule_4">
					<gml:description>This is CompositeSchedule 3, for 1 year, composed of 52 typical weeks, and using Xlinks</gml:description>
					<gml:name>CompositeSchedule 3</gml:name>
					<nrg3:libraryCode codeSpace="schedule_library_codeSpace">comp_sched_code_4</nrg3:libraryCode>
					<nrg3:type codeSpace="schedule_type_codeSpace">year</nrg3:type>
					<nrg3:startTime>00:00:00</nrg3:startTime>
					<nrg3:temporalExtent unit="year">1</nrg3:temporalExtent>
					<nrg3:scheduleComponent>
						<nrg3:ScheduleComponent gml:id="id_schedule_component_8">
							<gml:description>This is ScheduleComponent 7</gml:description>
							<gml:name>ScheduleComponent 7, for 1 year, composed of 52 typical weeks</gml:name>
							<nrg3:type codeSpace="schedule_type_codeSpace">typicalWeek</nrg3:type>
							<nrg3:repetitions>52</nrg3:repetitions>
							<nrg3:additionalGap unit="day">0</nrg3:additionalGap>
							<nrg3:scheduleComponentMember xlink:href="#id_composite_schedule_1"/>
						</nrg3:ScheduleComponent>
					</nrg3:scheduleComponent>
				</nrg3:CompositeSchedule>
			 </nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:DualValueSchedule gml:id="id_dual_value_schedule_1">
					<gml:description>This is DualValueSchedule 1 for a Monday</gml:description>
					<gml:name>DualValueSchedule 1</gml:name>
					<nrg3:libraryCode codeSpace="schedule_library_codeSpace">dual_value_sched_code_1</nrg3:libraryCode>
					<nrg3:type codeSpace="schedule_type_codeSpace">monday</nrg3:type>
					<nrg3:startTime>00:00:00</nrg3:startTime>
					<nrg3:temporalExtent unit="day">1</nrg3:temporalExtent>
					<nrg3:idleValue uom="degrees Celsius">12</nrg3:idleValue>
					<nrg3:usageValue uom="degrees Celsius">19</nrg3:usageValue>
					<nrg3:startUsageTime>07:00:00</nrg3:startUsageTime>
					<nrg3:endUsageTime>21:00:00</nrg3:endUsageTime>
				</nrg3:DualValueSchedule>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:DualValueSchedule gml:id="id_dual_value_schedule_2">
					<gml:description>This is DualValueSchedule 2 for a typical day</gml:description>
					<gml:name>DualValueSchedule 2</gml:name>
					<nrg3:libraryCode codeSpace="schedule_library_codeSpace">dual_value_sched_code_2</nrg3:libraryCode>
					<nrg3:type codeSpace="schedule_type_codeSpace">typicalDay</nrg3:type>
					<nrg3:startTime>00:00:00</nrg3:startTime>
					<nrg3:temporalExtent unit="day">1</nrg3:temporalExtent>
					<nrg3:idleValue uom="degrees Celsius">12</nrg3:idleValue>
					<nrg3:usageValue uom="degrees Celsius">19</nrg3:usageValue>
					<nrg3:startUsageTime>07:00:00</nrg3:startUsageTime>
					<nrg3:endUsageTime>14:00:00</nrg3:endUsageTime>
				</nrg3:DualValueSchedule>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:DualValueSchedule gml:id="id_dual_value_schedule_3">
					<gml:description>This is DualValueSchedule 3 for a week day</gml:description>
					<gml:name>DualValueSchedule 3</gml:name>
					<nrg3:libraryCode codeSpace="schedule_library_codeSpace">dual_value_sched_code_3</nrg3:libraryCode>
					<nrg3:type codeSpace="schedule_type_codeSpace">weekDay</nrg3:type>
					<nrg3:startTime>00:00:00</nrg3:startTime>
					<nrg3:temporalExtent unit="day">1</nrg3:temporalExtent>
					<nrg3:idleValue uom="degrees Celsius">35</nrg3:idleValue>
					<nrg3:usageValue uom="degrees Celsius">25</nrg3:usageValue>
					<nrg3:startUsageTime>07:00:00</nrg3:startUsageTime>
					<nrg3:endUsageTime>21:00:00</nrg3:endUsageTime>
				</nrg3:DualValueSchedule>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:DualValueSchedule gml:id="id_dual_value_schedule_4">
					<gml:description>This is DualValueSchedule 4 for a weekend day</gml:description>
					<gml:name>DualValueSchedule 4</gml:name>
					<nrg3:libraryCode codeSpace="schedule_library_codeSpace">dual_value_sched_code_4</nrg3:libraryCode>
					<nrg3:type codeSpace="schedule_type_codeSpace">weekendDay</nrg3:type>
					<nrg3:startTime>00:00:00</nrg3:startTime>
					<nrg3:temporalExtent unit="day">1</nrg3:temporalExtent>
					<nrg3:idleValue uom="degrees Celsius">35</nrg3:idleValue>
					<nrg3:usageValue uom="degrees Celsius">25</nrg3:usageValue>
					<nrg3:startUsageTime>07:00:00</nrg3:startUsageTime>
					<nrg3:endUsageTime>14:00:00</nrg3:endUsageTime>
				</nrg3:DualValueSchedule>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:DualValueSchedule gml:id="id_dual_value_schedule_5">
					<gml:description>This is DualValueSchedule 5 for a week</gml:description>
					<gml:name>DualValueSchedule 5</gml:name>
					<nrg3:libraryCode codeSpace="schedule_library_codeSpace">dual_value_sched_code_5</nrg3:libraryCode>
					<nrg3:type codeSpace="schedule_type_codeSpace">week</nrg3:type>
					<nrg3:startTime>00:00:00</nrg3:startTime>
					<nrg3:startDay>1</nrg3:startDay>
					<nrg3:temporalExtent unit="day">7</nrg3:temporalExtent>
					<nrg3:idleValue uom="unit interval">0</nrg3:idleValue>
					<nrg3:usageValue uom="unit interval">1</nrg3:usageValue>
					<nrg3:startUsageTime>09:00:00</nrg3:startUsageTime>
					<nrg3:endUsageTime>18:00:00</nrg3:endUsageTime>
				</nrg3:DualValueSchedule>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:DualValueSchedule gml:id="id_dual_value_schedule_6">
					<gml:description>This is DualValueSchedule 6 for August</gml:description>
					<gml:name>DualValueSchedule 6</gml:name>
					<nrg3:libraryCode codeSpace="schedule_library_codeSpace">dual_value_sched_code_6</nrg3:libraryCode>
					<nrg3:type codeSpace="schedule_type_codeSpace">august</nrg3:type>
					<nrg3:startTime>00:00:00</nrg3:startTime>
					<nrg3:startDay>1</nrg3:startDay>
					<nrg3:startMonth>8</nrg3:startMonth>
					<nrg3:temporalExtent unit="day">31</nrg3:temporalExtent>
					<nrg3:idleValue uom="unit interval">0.5</nrg3:idleValue>
					<nrg3:usageValue uom="unit interval">1</nrg3:usageValue>
					<nrg3:startUsageTime>09:00:00</nrg3:startUsageTime>
					<nrg3:endUsageTime>18:00:00</nrg3:endUsageTime>
				</nrg3:DualValueSchedule>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:DualValueSchedule gml:id="id_dual_value_schedule_7">
					<gml:description>This is DualValueSchedule 7 for spring</gml:description>
					<gml:name>DualValueSchedule 7</gml:name>
					<nrg3:libraryCode codeSpace="schedule_library_codeSpace">dual_value_sched_code_7</nrg3:libraryCode>
					<nrg3:type codeSpace="schedule_type_codeSpace">spring</nrg3:type>
					<nrg3:startTime>00:00:00</nrg3:startTime>
					<nrg3:startDay>22</nrg3:startDay>
					<nrg3:startMonth>3</nrg3:startMonth>
					<nrg3:temporalExtent unit="day">122</nrg3:temporalExtent>
					<nrg3:idleValue uom="unit interval">0</nrg3:idleValue>
					<nrg3:usageValue uom="unit interval">1</nrg3:usageValue>
					<nrg3:startUsageTime>09:00:00</nrg3:startUsageTime>
					<nrg3:endUsageTime>18:00:00</nrg3:endUsageTime>
				</nrg3:DualValueSchedule>
			</nrg3:libraryMember>
			<nrg3:libraryMember>
				<nrg3:DualValueSchedule gml:id="id_dual_value_schedule_8">
					<gml:description>This is DualValueSchedule 8 for a year</gml:description>
					<gml:name>DualValueSchedule 8</gml:name>
					<nrg3:libraryCode codeSpace="schedule_library_codeSpace">dual_value_sched_code_8</nrg3:libraryCode>
					<nrg3:type codeSpace="schedule_type_codeSpace">year</nrg3:type>
					<nrg3:startTime>00:00:00</nrg3:startTime>
					<nrg3:startDay>1</nrg3:startDay>
					<nrg3:startMonth>1</nrg3:startMonth>
					<nrg3:temporalExtent unit="year">1</nrg3:temporalExtent>
					<nrg3:idleValue uom="unit interval">0.5</nrg3:idleValue>
					<nrg3:usageValue uom="unit interval">1</nrg3:usageValue>
					<nrg3:startUsageTime>09:00:00</nrg3:startUsageTime>
					<nrg3:endUsageTime>18:00:00</nrg3:endUsageTime>
				</nrg3:DualValueSchedule>
			</nrg3:libraryMember>
		</nrg3:ScheduleLibrary>
	</core:cityObjectMember>
	<core:cityObjectMember>
		<bldg:Building gml:id="id_building_2">
			<gml:description>This is Building 2</gml:description>
			<gml:name>Rey's Hut</gml:name>
			<core:creationDate>2024-09-25</core:creationDate>
			<nrg3:device>
				<nrg3:Boiler gml:id="id_boiler_4">
					<gml:description>This is Boiler 4</gml:description>
					<gml:name>Boiler 4</gml:name>
					<nrg3:referencePoint>
						<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:pos>15 5 7.5</gml:pos>
						</gml:Point>
					</nrg3:referencePoint>
					<nrg3:model>Boiler Boiler 4</nrg3:model>
					<nrg3:yearOfManufacture>1992</nrg3:yearOfManufacture>
					<nrg3:numberOfDevices>1</nrg3:numberOfDevices>
					<nrg3:installedPower uom="kW">9.8</nrg3:installedPower>
					<nrg3:nominalEfficiency uom="unit interval">0.2</nrg3:nominalEfficiency>
					<nrg3:efficiencyIndicator>eff_indic_string_4</nrg3:efficiencyIndicator>
					<nrg3:heatDissipation uom="W/m^2">10</nrg3:heatDissipation>
					<nrg3:heatDissipationConvectiveFraction uom="unit interval">0.2</nrg3:heatDissipationConvectiveFraction>
					<nrg3:heatDissipationLatentFraction uom="unit interval">0.3</nrg3:heatDissipationLatentFraction>
					<nrg3:heatDissipationRadiantFraction uom="unit interval">0.5</nrg3:heatDissipationRadiantFraction>
					<nrg3:deviceOperation>
						<nrg3:DeviceOperation gml:id="id_operation_schedule_1">
							<gml:description>This is OperationSchedule 1</gml:description>
							<gml:name>OperationSchedule 1</gml:name>
							<nrg3:type codeSpace="deviceOperation_codeSpace">spaceHeating</nrg3:type>
							<nrg3:yearlyGlobalEfficiency>0.7</nrg3:yearlyGlobalEfficiency>
							<nrg3:schedule xlink:href="#id_dual_value_schedule_1"/>
						</nrg3:DeviceOperation>
					</nrg3:deviceOperation>
					<nrg3:hasCondensation>true</nrg3:hasCondensation>
				</nrg3:Boiler>
			</nrg3:device>
			<nrg3:device>
				<nrg3:LightingDevice gml:id="id_lighting_device_3">
					<gml:description>This is LightingDevice 3</gml:description>
					<gml:name>LightingDevice 3</gml:name>
					<nrg3:referencePoint>
						<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:pos>15 5 7.5</gml:pos>
						</gml:Point>
					</nrg3:referencePoint>
					<nrg3:model>LightingDevice LightingDevice 3</nrg3:model>
					<nrg3:yearOfManufacture>1999</nrg3:yearOfManufacture>
					<nrg3:numberOfDevices>1</nrg3:numberOfDevices>
					<nrg3:installedPower uom="kW">3.3</nrg3:installedPower>
					<nrg3:nominalEfficiency uom="unit interval">0.7</nrg3:nominalEfficiency>
					<nrg3:efficiencyIndicator>eff_indic_string_3</nrg3:efficiencyIndicator>
					<nrg3:heatDissipation uom="W/m^2">1</nrg3:heatDissipation>
					<nrg3:heatDissipationConvectiveFraction uom="unit interval">0.2</nrg3:heatDissipationConvectiveFraction>
					<nrg3:heatDissipationLatentFraction uom="unit interval">0.3</nrg3:heatDissipationLatentFraction>
					<nrg3:heatDissipationRadiantFraction uom="unit interval">0.5</nrg3:heatDissipationRadiantFraction>
					<nrg3:deviceOperation>
						<nrg3:DeviceOperation gml:id="id_operation_schedule_14">
							<gml:description>This is OperationSchedule 14</gml:description>
							<gml:name>OperationSchedule 14</gml:name>
							<nrg3:type codeSpace="deviceOperation_codeSpace">lighting</nrg3:type>
							<nrg3:yearlyGlobalEfficiency>0.6</nrg3:yearlyGlobalEfficiency>
							<nrg3:schedule xlink:href="#id_composite_schedule_1"/>
						</nrg3:DeviceOperation>
					</nrg3:deviceOperation>
				</nrg3:LightingDevice>
			</nrg3:device>
			<nrg3:device>
				<nrg3:GenericSolarCollector gml:id="id_generic_solar_collector_3">
					<gml:description>This is GenericSolarCollector 3</gml:description>
					<gml:name>GenericSolarCollector 3</gml:name>
					<nrg3:referencePoint>
						<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:pos>15 2.473 12.523</gml:pos>
						</gml:Point>
					</nrg3:referencePoint>
					<nrg3:relatedTo>
						<nrg3:CityObjectRelation>
							<nrg3:relationType codeSpace="relation_codeSpace">installedOn</nrg3:relationType>
							<nrg3:relatedTo xlink:href="#id_building_2_roofsurface_1"/>
						</nrg3:CityObjectRelation>
					</nrg3:relatedTo>
					<nrg3:model>GenericSolarCollector Model GenericSolarCollector 3</nrg3:model>
					<nrg3:yearOfManufacture>2015</nrg3:yearOfManufacture>
					<nrg3:numberOfDevices>3</nrg3:numberOfDevices>
					<nrg3:installedPower uom="kWp">9</nrg3:installedPower>
					<nrg3:nominalEfficiency uom="unit interval">0.3</nrg3:nominalEfficiency>
					<nrg3:efficiencyIndicator>eff_indic_string_3</nrg3:efficiencyIndicator>
					<nrg3:heatDissipation uom="W/m^2">15</nrg3:heatDissipation>
					<nrg3:heatDissipationConvectiveFraction uom="unit interval">0.1</nrg3:heatDissipationConvectiveFraction>
					<nrg3:heatDissipationLatentFraction uom="unit interval">0.5</nrg3:heatDissipationLatentFraction>
					<nrg3:heatDissipationRadiantFraction uom="unit interval">0.4</nrg3:heatDissipationRadiantFraction>
					<nrg3:deviceOperation>
						<nrg3:DeviceOperation gml:id="id_operation_schedule_27">
							<gml:description>This is OperationSchedule 27</gml:description>
							<gml:name>OperationSchedule 27</gml:name>
							<nrg3:type codeSpace="deviceOperation_codeSpace">unknown</nrg3:type>
							<nrg3:yearlyGlobalEfficiency>0.3</nrg3:yearlyGlobalEfficiency>
							<nrg3:schedule xlink:href="#id_atomic_schedule_3"/>
						</nrg3:DeviceOperation>
					</nrg3:deviceOperation>
					<nrg3:moduleArea uom="m^2">27.36</nrg3:moduleArea>
					<nrg3:apertureArea uom="m^2">21.888</nrg3:apertureArea>
					<nrg3:azimuth uom="decimal degrees">180</nrg3:azimuth>
					<nrg3:inclination uom="decimal degrees">45</nrg3:inclination>
					<nrg3:lod2MultiSurface>
						<gml:MultiSurface gml:id="MultiSurf_lod2_UUID_14b3929e-522e-40d3-b35c-f5e76a544b5c" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Polygon_UUID_1903c512-2b40-4b3f-8031-d71717cba157">
									<gml:exterior>
										<gml:LinearRing>
											<gml:posList>11.2 1.2 11.25 18.8 1.2 11.25 18.8 3.745584412271571 13.795584412271571 11.2 3.745584412271571 13.795584412271571 11.2 1.2 11.25</gml:posList>
										</gml:LinearRing>
									</gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</nrg3:lod2MultiSurface>
				</nrg3:GenericSolarCollector>
			</nrg3:device>
			<nrg3:device>
				<nrg3:PhotovoltaicCollector gml:id="id_pv_collector_23">
					<gml:description>This is PhotoVoltaicCollector 23</gml:description>
					<gml:name>PhotoVoltaicCollector 23</gml:name>
					<nrg3:referencePoint>
						<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:pos>12.333 2.473 12.523</gml:pos>
						</gml:Point>
					</nrg3:referencePoint>
					<nrg3:relatedTo>
						<nrg3:CityObjectRelation>
							<nrg3:relationType codeSpace="relation_codeSpace">installedOn</nrg3:relationType>
							<nrg3:relatedTo xlink:href="#id_building_2_roofsurface_1"/>
						</nrg3:CityObjectRelation>
					</nrg3:relatedTo>
					<nrg3:model>PhotoVoltaicCollector Model PhotoVoltaicCollector 23</nrg3:model>
					<nrg3:yearOfManufacture>2017</nrg3:yearOfManufacture>
					<nrg3:numberOfDevices>1</nrg3:numberOfDevices>
					<nrg3:installedPower uom="kWp">5</nrg3:installedPower>
					<nrg3:nominalEfficiency uom="unit interval">0.3</nrg3:nominalEfficiency>
					<nrg3:efficiencyIndicator>eff_indic_string_23</nrg3:efficiencyIndicator>
					<nrg3:heatDissipation uom="W/m^2">15</nrg3:heatDissipation>
					<nrg3:heatDissipationConvectiveFraction uom="unit interval">0.1</nrg3:heatDissipationConvectiveFraction>
					<nrg3:heatDissipationLatentFraction uom="unit interval">0.5</nrg3:heatDissipationLatentFraction>
					<nrg3:heatDissipationRadiantFraction uom="unit interval">0.4</nrg3:heatDissipationRadiantFraction>
					<nrg3:deviceOperation>
						<nrg3:DeviceOperation gml:id="id_operation_schedule_47">
							<gml:description>This is OperationSchedule 47</gml:description>
							<gml:name>OperationSchedule 47</gml:name>
							<nrg3:type codeSpace="deviceOperation_codeSpace">unknown</nrg3:type>
							<nrg3:yearlyGlobalEfficiency>0.3</nrg3:yearlyGlobalEfficiency>
							<nrg3:schedule xlink:href="#id_composite_schedule_2"/>
						</nrg3:DeviceOperation>
					</nrg3:deviceOperation>
					<nrg3:moduleArea uom="m^2">8.16</nrg3:moduleArea>
					<nrg3:apertureArea uom="m^2">7.752</nrg3:apertureArea>
					<nrg3:azimuth uom="decimal degrees">180</nrg3:azimuth>
					<nrg3:inclination uom="decimal degrees">45</nrg3:inclination>
					<nrg3:lod3MultiSurface>
						<gml:MultiSurface gml:id="MultiSurf_lod3_UUID_2954e3a7-e08a-4ac7-9bab-d6e5d97cb4d6" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Polygon_UUID_eec105c0-f799-4dea-889a-0e05e850349d">
									<gml:exterior>
										<gml:LinearRing>
											<gml:posList>11.2 1.2 11.25 13.466666666666667 1.2 11.25 13.466666666666667 3.745584412271571 13.795584412271571 11.2 3.745584412271571 13.795584412271571 11.2 1.2 11.25</gml:posList>
										</gml:LinearRing>
									</gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</nrg3:lod3MultiSurface>
					<nrg3:cellType codeSpace="cell_type_codeSpace_1">polycristalline</nrg3:cellType>
				</nrg3:PhotovoltaicCollector>
			</nrg3:device>
			<nrg3:device>
				<nrg3:PhotovoltaicCollector gml:id="id_pv_collector_24">
					<gml:description>This is PhotoVoltaicCollector 24</gml:description>
					<gml:name>PhotoVoltaicCollector 24</gml:name>
					<nrg3:referencePoint>
						<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:pos>15 2.473 12.523</gml:pos>
						</gml:Point>
					</nrg3:referencePoint>
					<nrg3:relatedTo>
						<nrg3:CityObjectRelation>
							<nrg3:relationType codeSpace="relation_codeSpace">installedOn</nrg3:relationType>
							<nrg3:relatedTo xlink:href="#id_building_2_roofsurface_1"/>
						</nrg3:CityObjectRelation>
					</nrg3:relatedTo>
					<nrg3:model>PhotoVoltaicCollector Model PhotoVoltaicCollector 24</nrg3:model>
					<nrg3:yearOfManufacture>2017</nrg3:yearOfManufacture>
					<nrg3:numberOfDevices>1</nrg3:numberOfDevices>
					<nrg3:installedPower uom="kWp">5</nrg3:installedPower>
					<nrg3:nominalEfficiency uom="unit interval">0.3</nrg3:nominalEfficiency>
					<nrg3:efficiencyIndicator>eff_indic_string_24</nrg3:efficiencyIndicator>
					<nrg3:heatDissipation uom="W/m^2">15</nrg3:heatDissipation>
					<nrg3:heatDissipationConvectiveFraction uom="unit interval">0.1</nrg3:heatDissipationConvectiveFraction>
					<nrg3:heatDissipationLatentFraction uom="unit interval">0.5</nrg3:heatDissipationLatentFraction>
					<nrg3:heatDissipationRadiantFraction uom="unit interval">0.4</nrg3:heatDissipationRadiantFraction>
					<nrg3:deviceOperation>
						<nrg3:DeviceOperation gml:id="id_operation_schedule_48">
							<gml:description>This is OperationSchedule 48</gml:description>
							<gml:name>OperationSchedule 48</gml:name>
							<nrg3:type codeSpace="deviceOperation_codeSpace">unknown</nrg3:type>
							<nrg3:yearlyGlobalEfficiency>0.25</nrg3:yearlyGlobalEfficiency>
							<nrg3:schedule xlink:href="#id_composite_schedule_3"/>
						</nrg3:DeviceOperation>
					</nrg3:deviceOperation>
					<nrg3:moduleArea uom="m^2">8.16</nrg3:moduleArea>
					<nrg3:apertureArea uom="m^2">7.752</nrg3:apertureArea>
					<nrg3:azimuth uom="decimal degrees">180</nrg3:azimuth>
					<nrg3:inclination uom="decimal degrees">45</nrg3:inclination>
					<nrg3:lod3MultiSurface>
						<gml:MultiSurface gml:id="MultiSurf_lod3_UUID_cff7dfea-28a8-4a78-8688-7802b5a750b9" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Polygon_UUID_fe51c611-6715-4feb-94cc-0b653d5924cf">
									<gml:exterior>
										<gml:LinearRing>
											<gml:posList>13.866666666666665 1.2 11.25 16.133333333333333 1.2 11.25 16.133333333333333 3.745584412271571 13.795584412271571 13.866666666666665 3.745584412271571 13.795584412271571 13.866666666666665 1.2 11.25</gml:posList>
										</gml:LinearRing>
									</gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</nrg3:lod3MultiSurface>
					<nrg3:cellType codeSpace="cell_type_codeSpace_1">polycristalline</nrg3:cellType>
				</nrg3:PhotovoltaicCollector>
			</nrg3:device>
			<nrg3:device>
				<nrg3:PhotovoltaicCollector gml:id="id_pv_collector_25">
					<gml:description>This is PhotoVoltaicCollector 25</gml:description>
					<gml:name>PhotoVoltaicCollector 25</gml:name>
					<nrg3:referencePoint>
						<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:pos>17.667 2.473 12.523</gml:pos>
						</gml:Point>
					</nrg3:referencePoint>
					<nrg3:relatedTo>
						<nrg3:CityObjectRelation>
							<nrg3:relationType codeSpace="relation_codeSpace">installedOn</nrg3:relationType>
							<nrg3:relatedTo xlink:href="#id_building_2_roofsurface_1"/>
						</nrg3:CityObjectRelation>
					</nrg3:relatedTo>
					<nrg3:model>PhotoVoltaicCollector Model PhotoVoltaicCollector 25</nrg3:model>
					<nrg3:yearOfManufacture>2017</nrg3:yearOfManufacture>
					<nrg3:numberOfDevices>1</nrg3:numberOfDevices>
					<nrg3:installedPower uom="kWp">5</nrg3:installedPower>
					<nrg3:nominalEfficiency uom="unit interval">0.3</nrg3:nominalEfficiency>
					<nrg3:efficiencyIndicator>eff_indic_string_25</nrg3:efficiencyIndicator>
					<nrg3:heatDissipation uom="W/m^2">15</nrg3:heatDissipation>
					<nrg3:heatDissipationConvectiveFraction uom="unit interval">0.1</nrg3:heatDissipationConvectiveFraction>
					<nrg3:heatDissipationLatentFraction uom="unit interval">0.5</nrg3:heatDissipationLatentFraction>
					<nrg3:heatDissipationRadiantFraction uom="unit interval">0.4</nrg3:heatDissipationRadiantFraction>
					<nrg3:deviceOperation>
						<nrg3:DeviceOperation gml:id="id_operation_schedule_49">
							<gml:description>This is OperationSchedule 49</gml:description>
							<gml:name>OperationSchedule 49</gml:name>
							<nrg3:type codeSpace="deviceOperation_codeSpace">unknown</nrg3:type>
							<nrg3:yearlyGlobalEfficiency>0.2</nrg3:yearlyGlobalEfficiency>
							<nrg3:schedule xlink:href="#id_dual_value_schedule_1"/>
						</nrg3:DeviceOperation>
					</nrg3:deviceOperation>
					<nrg3:moduleArea uom="m^2">8.16</nrg3:moduleArea>
					<nrg3:apertureArea uom="m^2">7.752</nrg3:apertureArea>
					<nrg3:azimuth uom="decimal degrees">180</nrg3:azimuth>
					<nrg3:inclination uom="decimal degrees">45</nrg3:inclination>
					<nrg3:lod3MultiSurface>
						<gml:MultiSurface gml:id="MultiSurf_lod3_UUID_03cff5e7-8368-4c56-9086-3bb82ed2ba98" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Polygon_UUID_6a91b021-b41e-4de6-aa79-665e27e12fe5">
									<gml:exterior>
										<gml:LinearRing>
											<gml:posList>16.53333333333333 1.2 11.25 18.8 1.2 11.25 18.8 3.745584412271571 13.795584412271571 16.53333333333333 3.745584412271571 13.795584412271571 16.53333333333333 1.2 11.25</gml:posList>
										</gml:LinearRing>
									</gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</nrg3:lod3MultiSurface>
					<nrg3:cellType codeSpace="cell_type_codeSpace_1">polycristalline</nrg3:cellType>
				</nrg3:PhotovoltaicCollector>
			</nrg3:device>
			<nrg3:referencePoint>
				<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
					<gml:pos>15 5 7.5</gml:pos>
				</gml:Point>
			</nrg3:referencePoint>
			<nrg3:relatedTo>
				<nrg3:CityObjectRelation>
					<nrg3:relationType codeSpace="adjacent_codeList">adjacent</nrg3:relationType>
					<nrg3:relatedTo xlink:href="#id_building_1"/>
				</nrg3:CityObjectRelation>
			</nrg3:relatedTo>
			<nrg3:relatedTo>
				<nrg3:CityObjectRelation>
					<nrg3:relationType codeSpace="adjacent_codeList">adjacent</nrg3:relationType>
					<nrg3:relatedTo xlink:href="#id_building_3"/>
				</nrg3:CityObjectRelation>
			</nrg3:relatedTo>
			<nrg3:suitability>
				<nrg3:Suitability>
					<nrg3:reason codeSpace="suitability_reason_codespace">suitability reason 4</nrg3:reason>
					<nrg3:description>suitability description 4</nrg3:description>
					<nrg3:value uom="unit interval">1</nrg3:value>
				</nrg3:Suitability>
			</nrg3:suitability>
			<nrg3:suitability>
				<nrg3:Suitability>
					<nrg3:reason codeSpace="suitability_reason_codespace">suitability reason 5</nrg3:reason>
					<nrg3:description>suitability description 5</nrg3:description>
					<nrg3:value uom="unit interval">1</nrg3:value>
				</nrg3:Suitability>
			</nrg3:suitability>
			<nrg3:utilityNetworkConnection>
				<nrg3:UtilityNetworkConnection gml:id="id_util_network_conn_4">
					<gml:description>This is UtilityNetworkConnection 4</gml:description>
					<gml:name>UtilityNetworkConnection 4</gml:name>
					<nrg3:networkType codeSpace="network_conn_codespace">electricity</nrg3:networkType>
					<nrg3:connectionStatus>connected</nrg3:connectionStatus>
					<nrg3:functionInNetwork codeSpace="function_in_network_codespace">function in network</nrg3:functionInNetwork>
					<nrg3:usageInNetwork codeSpace="usage_in_network_codespace">usage in network</nrg3:usageInNetwork>
					<nrg3:networkID>network_id</nrg3:networkID>
					<nrg3:networkNodeID>network_node_id</nrg3:networkNodeID>
				</nrg3:UtilityNetworkConnection>
			</nrg3:utilityNetworkConnection>
			<nrg3:utilityNetworkConnection>
				<nrg3:UtilityNetworkConnection gml:id="id_util_network_conn_5">
					<gml:description>This is UtilityNetworkConnection 5</gml:description>
					<gml:name>UtilityNetworkConnection 5</gml:name>
					<nrg3:networkType codeSpace="network_conn_codespace">districtHeating</nrg3:networkType>
					<nrg3:connectionStatus>disconnectedButConnectable</nrg3:connectionStatus>
					<nrg3:functionInNetwork codeSpace="function_in_network_codespace">function in network</nrg3:functionInNetwork>
					<nrg3:usageInNetwork codeSpace="usage_in_network_codespace">usage in network</nrg3:usageInNetwork>
					<nrg3:networkID>network_id</nrg3:networkID>
					<nrg3:networkNodeID>network_node_id</nrg3:networkNodeID>
				</nrg3:UtilityNetworkConnection>
			</nrg3:utilityNetworkConnection>
			<nrg3:utilityNetworkConnection>
				<nrg3:UtilityNetworkConnection gml:id="id_util_network_conn_6">
					<gml:description>This is UtilityNetworkConnection 6</gml:description>
					<gml:name>UtilityNetworkConnection 6</gml:name>
					<nrg3:networkType codeSpace="network_conn_codespace">sewage</nrg3:networkType>
					<nrg3:connectionStatus>unknown</nrg3:connectionStatus>
					<nrg3:functionInNetwork codeSpace="function_in_network_codespace">function in network</nrg3:functionInNetwork>
					<nrg3:usageInNetwork codeSpace="usage_in_network_codespace">usage in network</nrg3:usageInNetwork>
					<nrg3:networkID>network_id</nrg3:networkID>
					<nrg3:networkNodeID>network_node_id</nrg3:networkNodeID>
				</nrg3:UtilityNetworkConnection>
			</nrg3:utilityNetworkConnection>
			<bldg:class codeSpace="http://www.sig3d.org/codelists/standard/building/2.0/_AbstractBuilding_class.xml">habitation</bldg:class>
			<bldg:function codeSpace="http://www.sig3d.org/codelists/standard/building/2.0/_AbstractBuilding_function.xml">residential building</bldg:function>
			<bldg:yearOfConstruction>1955</bldg:yearOfConstruction>
			<bldg:roofType codeSpace="http://www.sig3d.org/codelists/standard/building/2.0/_AbstractBuilding_roofType.xml">gabled roof</bldg:roofType>
			<bldg:measuredHeight uom="m">15</bldg:measuredHeight>
			<bldg:storeysAboveGround>3</bldg:storeysAboveGround>
			<bldg:storeysBelowGround>0</bldg:storeysBelowGround>
			<bldg:storeyHeightsAboveGround uom="m">3</bldg:storeyHeightsAboveGround>
			<bldg:lod0FootPrint>
				<gml:MultiSurface gml:id="id_building_2_footprint_MultiSurf" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
					<gml:surfaceMember>
						<gml:OrientableSurface orientation="-">
							<gml:baseSurface xlink:href="#id_building_2_polygon_3"/>
						</gml:OrientableSurface>
					</gml:surfaceMember>
				</gml:MultiSurface>
			</bldg:lod0FootPrint>
			<bldg:lod1Solid>
				<gml:Solid gml:id="id_building_2_lod1_Solid" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
					<gml:exterior>
						<gml:CompositeSurface gml:id="id_building_2_lod1_CompSurf">
							<gml:surfaceMember>
								<gml:Polygon gml:id="id_building_2_lod1_Polygon_7">
									<gml:exterior>
										<gml:LinearRing>
											<gml:posList>20 0 0 10 0 0 10 10 0 20 10 0 20 0 0</gml:posList>
										</gml:LinearRing>
									</gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
							<gml:surfaceMember>
								<gml:Polygon gml:id="id_building_2_lod1_Polygon_8">
									<gml:exterior>
										<gml:LinearRing>
											<gml:posList>20 0 0 20 10 0 20 10 12.5 20 0 12.5 20 0 0</gml:posList>
										</gml:LinearRing>
									</gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
							<gml:surfaceMember>
								<gml:Polygon gml:id="id_building_2_lod1_Polygon_9">
									<gml:exterior>
										<gml:LinearRing>
											<gml:posList>20 10 0 10 10 0 10 10 12.5 20 10 12.5 20 10 0</gml:posList>
										</gml:LinearRing>
									</gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
							<gml:surfaceMember>
								<gml:Polygon gml:id="id_building_2_lod1_Polygon_10">
									<gml:exterior>
										<gml:LinearRing>
											<gml:posList>10 10 0 10 0 0 10 0 12.5 10 10 12.5 10 10 0</gml:posList>
										</gml:LinearRing>
									</gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
							<gml:surfaceMember>
								<gml:Polygon gml:id="id_building_2_lod1_Polygon_11">
									<gml:exterior>
										<gml:LinearRing>
											<gml:posList>10 0 0 20 0 0 20 0 12.5 10 0 12.5 10 0 0</gml:posList>
										</gml:LinearRing>
									</gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
							<gml:surfaceMember>
								<gml:Polygon gml:id="id_building_2_lod1_Polygon_12">
									<gml:exterior>
										<gml:LinearRing>
											<gml:posList>20 0 12.5 20 10 12.5 10 10 12.5 10 0 12.5 20 0 12.5</gml:posList>
										</gml:LinearRing>
									</gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:CompositeSurface>
					</gml:exterior>
				</gml:Solid>
			</bldg:lod1Solid>
			<bldg:lod2Solid>
				<gml:Solid gml:id="id_building_2_lod2_Solid" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
					<gml:exterior>
						<gml:CompositeSurface gml:id="id_building_2_lod2_CompSurf">
							<gml:surfaceMember xlink:href="#id_building_2_polygon_6"/>
							<gml:surfaceMember xlink:href="#id_building_2_polygon_7"/>
							<gml:surfaceMember xlink:href="#id_building_2_polygon_1"/>
							<gml:surfaceMember xlink:href="#id_building_2_polygon_2"/>
							<gml:surfaceMember xlink:href="#id_building_2_polygon_3"/>
							<gml:surfaceMember>
								<gml:Polygon gml:id="Polygon_UUID_d59ae86b-9fe3-48ec-ab5c-7169df69141d">
									<gml:exterior>
										<gml:LinearRing>
											<gml:posList>20 0 10 20 0 0 20 10 0 20 10 10 20 5 15 20 0 10</gml:posList>
										</gml:LinearRing>
									</gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
							<gml:surfaceMember>
								<gml:Polygon gml:id="Polygon_UUID_ae483003-364f-49f5-a437-a8bf08b1c35f">
									<gml:exterior>
										<gml:LinearRing>
											<gml:posList>10 10 10 10 10 0 10 0 0 10 0 10 10 5 15 10 10 10</gml:posList>
										</gml:LinearRing>
									</gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:CompositeSurface>
					</gml:exterior>
				</gml:Solid>
			</bldg:lod2Solid>
			<bldg:boundedBy>
				<bldg:GroundSurface gml:id="id_building_2_groundsurface_1">
					<gml:description>This is GroundSurface 1 (Building 2)</gml:description>
					<gml:name>GroundSurface 1 (Building 2)</gml:name>
					<nrg3:layeredConstruction xlink:href="#id_layered_construction_ground_1"/>
					<nrg3:referencePoint>
						<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:pos>15 5 0</gml:pos>
						</gml:Point>
					</nrg3:referencePoint>
					<bldg:lod2MultiSurface>
						<gml:MultiSurface gml:id="id_building_2_groundsurface_1_lod2_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="id_building_2_polygon_3">
									<gml:exterior>
										<gml:LinearRing>
											<gml:posList>20 0 0 10 0 0 10 10 0 20 10 0 20 0 0</gml:posList>
										</gml:LinearRing>
									</gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</bldg:lod2MultiSurface>
					<nrg3:bdgBdrySurfAzimuth uom="decimal degree">-1</nrg3:bdgBdrySurfAzimuth>
					<nrg3:bdgBdrySurfGroundViewFactor uom="unit interval">1</nrg3:bdgBdrySurfGroundViewFactor>
					<nrg3:bdgBdrySurfInclination uom="decimal degree">180</nrg3:bdgBdrySurfInclination>
					<nrg3:bdgBdrySurfIsAdiabatic>false</nrg3:bdgBdrySurfIsAdiabatic>
					<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
					<nrg3:bdgBdrySurfSkyViewFactor uom="unit interval">0</nrg3:bdgBdrySurfSkyViewFactor>
					<nrg3:bdgBdrySurfTotalSurfaceArea uom="m^2">100</nrg3:bdgBdrySurfTotalSurfaceArea>
				</bldg:GroundSurface>
			</bldg:boundedBy>
			<bldg:boundedBy>
				<bldg:RoofSurface gml:id="id_building_2_roofsurface_1">
					<gml:description>This is RoofSurface 1 (Building 2)</gml:description>
					<gml:name>RoofSurface 1 (Building 2)</gml:name>
					<nrg3:layeredConstruction xlink:href="#id_layered_construction_roof_3"/>
					<nrg3:referencePoint>
						<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:pos>15 2.5 12.5</gml:pos>
						</gml:Point>
					</nrg3:referencePoint>
					<bldg:lod2MultiSurface>
						<gml:MultiSurface gml:id="id_building_2_roofsurface_1_lod2_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="id_building_2_polygon_1">
									<gml:exterior>
										<gml:LinearRing>
											<gml:posList>20 0 10 20 5 15 10 5 15 10 0 10 20 0 10</gml:posList>
										</gml:LinearRing>
									</gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</bldg:lod2MultiSurface>
					<nrg3:bdgBdrySurfAzimuth uom="decimal degree">180</nrg3:bdgBdrySurfAzimuth>
					<nrg3:bdgBdrySurfGroundViewFactor uom="unit interval">0.5</nrg3:bdgBdrySurfGroundViewFactor>
					<nrg3:bdgBdrySurfInclination uom="decimal degree">45</nrg3:bdgBdrySurfInclination>
					<nrg3:bdgBdrySurfIsAdiabatic>false</nrg3:bdgBdrySurfIsAdiabatic>
					<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0.25</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
					<nrg3:bdgBdrySurfSkyViewFactor uom="unit interval">0.6</nrg3:bdgBdrySurfSkyViewFactor>
					<nrg3:bdgBdrySurfTotalSurfaceArea uom="m^2">70.7107</nrg3:bdgBdrySurfTotalSurfaceArea>
				</bldg:RoofSurface>
			</bldg:boundedBy>
			<bldg:boundedBy>
				<bldg:RoofSurface gml:id="id_building_2_roofsurface_2">
					<gml:description>This is RoofSurface 2 (Building 2)</gml:description>
					<gml:name>RoofSurface 2 (Building 2)</gml:name>
					<nrg3:layeredConstruction xlink:href="#id_layered_construction_roof_3"/>
					<nrg3:referencePoint>
						<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:pos>15 7.5 12.5</gml:pos>
						</gml:Point>
					</nrg3:referencePoint>
					<bldg:lod2MultiSurface>
						<gml:MultiSurface gml:id="id_building_2_roofsurface_2_lod2_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="id_building_2_polygon_2">
									<gml:exterior>
										<gml:LinearRing>
											<gml:posList>20 5 15 20 10 10 10 10 10 10 5 15 20 5 15</gml:posList>
										</gml:LinearRing>
									</gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</bldg:lod2MultiSurface>
					<nrg3:bdgBdrySurfAzimuth uom="decimal degree">0</nrg3:bdgBdrySurfAzimuth>
					<nrg3:bdgBdrySurfGroundViewFactor uom="unit interval">0.5</nrg3:bdgBdrySurfGroundViewFactor>
					<nrg3:bdgBdrySurfInclination uom="decimal degree">45</nrg3:bdgBdrySurfInclination>
					<nrg3:bdgBdrySurfIsAdiabatic>false</nrg3:bdgBdrySurfIsAdiabatic>
					<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0.25</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
					<nrg3:bdgBdrySurfSkyViewFactor uom="unit interval">0.6</nrg3:bdgBdrySurfSkyViewFactor>
					<nrg3:bdgBdrySurfTotalSurfaceArea uom="m^2">70.7107</nrg3:bdgBdrySurfTotalSurfaceArea>
				</bldg:RoofSurface>
			</bldg:boundedBy>
			<bldg:boundedBy>
				<bldg:WallSurface gml:id="id_building_2_wallsurface_1">
					<gml:description>This is WallSurface 4 (split)</gml:description>
					<gml:name>WallSurface 4 (split)</gml:name>
					<nrg3:layeredConstruction xlink:href="#id_layered_construction_wall_2"/>
					<nrg3:referencePoint>
						<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:pos>20 5 12.5</gml:pos>
						</gml:Point>
					</nrg3:referencePoint>
					<bldg:lod2MultiSurface>
						<gml:MultiSurface gml:id="id_building_2_wallsurface_1_lod2_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Polygon_UUID_a1c78b6b-ddc7-434a-9899-7638cbcb9f69">
									<gml:exterior>
										<gml:LinearRing>
											<gml:posList>20 5 15 20 0 10 20 10 10 20 5 15</gml:posList>
										</gml:LinearRing>
									</gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</bldg:lod2MultiSurface>
					<nrg3:bdgBdrySurfAzimuth uom="decimal degree">90</nrg3:bdgBdrySurfAzimuth>
					<nrg3:bdgBdrySurfGroundViewFactor uom="unit interval">0.5</nrg3:bdgBdrySurfGroundViewFactor>
					<nrg3:bdgBdrySurfInclination uom="decimal degree">90</nrg3:bdgBdrySurfInclination>
					<nrg3:bdgBdrySurfIsAdiabatic>false</nrg3:bdgBdrySurfIsAdiabatic>
					<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0.25</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
					<nrg3:bdgBdrySurfSkyViewFactor uom="unit interval">0.6</nrg3:bdgBdrySurfSkyViewFactor>
					<nrg3:bdgBdrySurfTotalSurfaceArea uom="m^2">25</nrg3:bdgBdrySurfTotalSurfaceArea>
				</bldg:WallSurface>
			</bldg:boundedBy>
			<bldg:boundedBy>
				<bldg:WallSurface gml:id="id_building_2_wallsurface_2">
					<gml:description>This is WallSurface 6 (split)</gml:description>
					<gml:name>WallSurface 6 (split)</gml:name>
					<nrg3:layeredConstruction xlink:href="#id_layered_construction_wall_2"/>
					<nrg3:referencePoint>
						<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:pos>10 5 7.5</gml:pos>
						</gml:Point>
					</nrg3:referencePoint>
					<bldg:lod2MultiSurface>
						<gml:MultiSurface gml:id="id_building_2_wallsurface_2_lod2_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="Polygon_UUID_6b52b561-1122-4439-9121-cf191b5cf608">
									<gml:exterior>
										<gml:LinearRing>
											<gml:posList>10 0 10 10 5 15 10 10 10 10 0 10</gml:posList>
										</gml:LinearRing>
									</gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</bldg:lod2MultiSurface>
					<nrg3:bdgBdrySurfAzimuth uom="decimal degree">270</nrg3:bdgBdrySurfAzimuth>
					<nrg3:bdgBdrySurfGroundViewFactor uom="unit interval">0.5</nrg3:bdgBdrySurfGroundViewFactor>
					<nrg3:bdgBdrySurfInclination uom="decimal degree">90</nrg3:bdgBdrySurfInclination>
					<nrg3:bdgBdrySurfIsAdiabatic>false</nrg3:bdgBdrySurfIsAdiabatic>
					<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0.25</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
					<nrg3:bdgBdrySurfSkyViewFactor uom="unit interval">0.6</nrg3:bdgBdrySurfSkyViewFactor>
					<nrg3:bdgBdrySurfTotalSurfaceArea uom="m^2">25</nrg3:bdgBdrySurfTotalSurfaceArea>
				</bldg:WallSurface>
			</bldg:boundedBy>
			<bldg:boundedBy>
				<bldg:WallSurface gml:id="id_building_2_wallsurface_3">
					<gml:description>This is WallSurface 3 (Building 2)</gml:description>
					<gml:name>WallSurface 3 (Building 2)</gml:name>
					<nrg3:layeredConstruction xlink:href="#id_layered_construction_wall_2"/>
					<nrg3:referencePoint>
						<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:pos>15 0 5</gml:pos>
						</gml:Point>
					</nrg3:referencePoint>
					<bldg:lod2MultiSurface>
						<gml:MultiSurface gml:id="id_building_2_wallsurface_3_lod2_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="id_building_2_polygon_7">
									<gml:exterior>
										<gml:LinearRing>
											<gml:posList>20 0 0 20 0 10 10 0 10 10 0 0 20 0 0</gml:posList>
										</gml:LinearRing>
									</gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</bldg:lod2MultiSurface>
					<nrg3:bdgBdrySurfAzimuth uom="decimal degree">180</nrg3:bdgBdrySurfAzimuth>
					<nrg3:bdgBdrySurfGroundViewFactor uom="unit interval">0.5</nrg3:bdgBdrySurfGroundViewFactor>
					<nrg3:bdgBdrySurfInclination uom="decimal degree">90</nrg3:bdgBdrySurfInclination>
					<nrg3:bdgBdrySurfIsAdiabatic>false</nrg3:bdgBdrySurfIsAdiabatic>
					<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0.25</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
					<nrg3:bdgBdrySurfSkyViewFactor uom="unit interval">0.6</nrg3:bdgBdrySurfSkyViewFactor>
					<nrg3:bdgBdrySurfTotalSurfaceArea uom="m^2">100</nrg3:bdgBdrySurfTotalSurfaceArea>
				</bldg:WallSurface>
			</bldg:boundedBy>
			<bldg:boundedBy>
				<bldg:WallSurface gml:id="id_building_2_wallsurface_4">
					<gml:description>This is WallSurface 4 (Building 2)</gml:description>
					<gml:name>WallSurface 4 (Building 2)</gml:name>
					<nrg3:layeredConstruction xlink:href="#id_layered_construction_wall_2"/>
					<nrg3:referencePoint>
						<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:pos>15 10 5</gml:pos>
						</gml:Point>
					</nrg3:referencePoint>
					<bldg:lod2MultiSurface>
						<gml:MultiSurface gml:id="id_building_2_wallsurface_4_lod2_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="id_building_2_polygon_6">
									<gml:exterior>
										<gml:LinearRing>
											<gml:posList>20 10 0 10 10 0 10 10 10 20 10 10 20 10 0</gml:posList>
										</gml:LinearRing>
									</gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</bldg:lod2MultiSurface>
					<nrg3:bdgBdrySurfAzimuth uom="decimal degree">0</nrg3:bdgBdrySurfAzimuth>
					<nrg3:bdgBdrySurfGroundViewFactor uom="unit interval">0.5</nrg3:bdgBdrySurfGroundViewFactor>
					<nrg3:bdgBdrySurfInclination uom="decimal degree">90</nrg3:bdgBdrySurfInclination>
					<nrg3:bdgBdrySurfIsAdiabatic>false</nrg3:bdgBdrySurfIsAdiabatic>
					<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0.25</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
					<nrg3:bdgBdrySurfSkyViewFactor uom="unit interval">0.6</nrg3:bdgBdrySurfSkyViewFactor>
					<nrg3:bdgBdrySurfTotalSurfaceArea uom="m^2">100</nrg3:bdgBdrySurfTotalSurfaceArea>
				</bldg:WallSurface>
			</bldg:boundedBy>
			<bldg:boundedBy>
				<nrg3:PartyWallSurface gml:id="id_building_2_partywallsurface_1">
					<gml:description>This is WallSurface 12 (shared)</gml:description>
					<gml:name>WallSurface 12 (shared)</gml:name>
					<nrg3:layeredConstruction xlink:href="#id_layered_construction_wall_2"/>
					<nrg3:referencePoint>
						<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:pos>10 5 5</gml:pos>
						</gml:Point>
					</nrg3:referencePoint>
					<nrg3:relatedTo>
						<nrg3:CityObjectRelation>
							<nrg3:relationType codeSpace="adjacent_codeList">adjacent</nrg3:relationType>
							<nrg3:relatedTo xlink:href="#id_building_1_partywallsurface_1"/>
						</nrg3:CityObjectRelation>
					</nrg3:relatedTo>
					<bldg:lod2MultiSurface>
						<gml:MultiSurface gml:id="id_building_2_partywallsurface_1_lod2_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="id_building_2_polygon_cs1">
									<gml:exterior>
										<gml:LinearRing>
											<gml:posList>10 10 10 10 10 0 10 0 0 10 0 10 10 10 10</gml:posList>
										</gml:LinearRing>
									</gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</bldg:lod2MultiSurface>
					<nrg3:bdgBdrySurfAzimuth uom="decimal degree">270</nrg3:bdgBdrySurfAzimuth>
					<nrg3:bdgBdrySurfGroundViewFactor uom="unit interval">0</nrg3:bdgBdrySurfGroundViewFactor>
					<nrg3:bdgBdrySurfInclination uom="decimal degree">90</nrg3:bdgBdrySurfInclination>
					<nrg3:bdgBdrySurfIsAdiabatic>false</nrg3:bdgBdrySurfIsAdiabatic>
					<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
					<nrg3:bdgBdrySurfSkyViewFactor uom="unit interval">0</nrg3:bdgBdrySurfSkyViewFactor>
					<nrg3:bdgBdrySurfTotalSurfaceArea uom="m^2">100</nrg3:bdgBdrySurfTotalSurfaceArea>
				</nrg3:PartyWallSurface>
			</bldg:boundedBy>
			<bldg:boundedBy>
				<nrg3:PartyWallSurface gml:id="id_building_2_partywallsurface_2">
					<gml:description>This is WallSurface 3 (shared)</gml:description>
					<gml:name>WallSurface 3 (shared)</gml:name>
					<nrg3:layeredConstruction xlink:href="#id_layered_construction_wall_2"/>
					<nrg3:referencePoint>
						<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:pos>20 5 5</gml:pos>
						</gml:Point>
					</nrg3:referencePoint>
					<nrg3:relatedTo>
						<nrg3:CityObjectRelation>
							<nrg3:relationType codeSpace="adjacent_codeList">adjacent</nrg3:relationType>
							<nrg3:relatedTo xlink:href="#id_building_3_partywallsurface_1"/>
						</nrg3:CityObjectRelation>
					</nrg3:relatedTo>
					<bldg:lod2MultiSurface>
						<gml:MultiSurface gml:id="id_building_2_partywallsurface_2_lod2_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:surfaceMember>
								<gml:Polygon gml:id="id_building_2_polygon_cs2">
									<gml:exterior>
										<gml:LinearRing>
											<gml:posList>20 10 10 20 0 10 20 0 0 20 10 0 20 10 10</gml:posList>
										</gml:LinearRing>
									</gml:exterior>
								</gml:Polygon>
							</gml:surfaceMember>
						</gml:MultiSurface>
					</bldg:lod2MultiSurface>
					<nrg3:bdgBdrySurfAzimuth uom="decimal degree">90</nrg3:bdgBdrySurfAzimuth>
					<nrg3:bdgBdrySurfGroundViewFactor uom="unit interval">0</nrg3:bdgBdrySurfGroundViewFactor>
					<nrg3:bdgBdrySurfInclination uom="decimal degree">90</nrg3:bdgBdrySurfInclination>
					<nrg3:bdgBdrySurfIsAdiabatic>false</nrg3:bdgBdrySurfIsAdiabatic>
					<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
					<nrg3:bdgBdrySurfSkyViewFactor uom="unit interval">0</nrg3:bdgBdrySurfSkyViewFactor>
					<nrg3:bdgBdrySurfTotalSurfaceArea uom="m^2">100</nrg3:bdgBdrySurfTotalSurfaceArea>
				</nrg3:PartyWallSurface>
			</bldg:boundedBy>
			<bldg:address>
				<core:Address gml:id="id_address_2">
					<core:xalAddress>
						<xAL:AddressDetails>
							<xAL:Country>
								<xAL:CountryNameCode>ALD</xAL:CountryNameCode>
								<xAL:CountryName>Bespin Territories</xAL:CountryName>
								<xAL:Locality Type="Town">
									<xAL:LocalityName>Alderaan</xAL:LocalityName>
									<xAL:Thoroughfare Type="Street">
										<xAL:ThoroughfareNumber>2</xAL:ThoroughfareNumber>
										<xAL:ThoroughfareName>Bespin Square</xAL:ThoroughfareName>
									</xAL:Thoroughfare>
									<xAL:PostalCode>
										<xAL:PostalCodeNumber>1977SW</xAL:PostalCodeNumber>
									</xAL:PostalCode>
								</xAL:Locality>
							</xAL:Country>
						</xAL:AddressDetails>
					</core:xalAddress>
					<core:multiPoint>
						<gml:MultiPoint srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:pointMember>
								<gml:Point>
									<gml:pos>15 5 0</gml:pos>
								</gml:Point>
							</gml:pointMember>
						</gml:MultiPoint>
					</core:multiPoint>
				</core:Address>
			</bldg:address>
			<nrg3:bdgArea>
				<nrg3:QualifiedArea>
					<nrg3:description>This is a type of floor area</nrg3:description>
					<nrg3:source>Area value source text</nrg3:source>
					<nrg3:value uom="m^2">300</nrg3:value>
					<nrg3:type codeSpace="area_codeSpace">grossFloorArea</nrg3:type>
				</nrg3:QualifiedArea>
			</nrg3:bdgArea>
			<nrg3:bdgArea>
				<nrg3:QualifiedArea>
					<nrg3:description>This is a type of floor area</nrg3:description>
					<nrg3:source>Area value source text</nrg3:source>
					<nrg3:value uom="m^2">100</nrg3:value>
					<nrg3:type codeSpace="area_codeSpace">footprintArea</nrg3:type>
				</nrg3:QualifiedArea>
			</nrg3:bdgArea>
			<nrg3:bdgAtticThermalStatus>isOnlyCooled</nrg3:bdgAtticThermalStatus>
			<nrg3:bdgBasementThermalStatus>isOnlyHeated</nrg3:bdgBasementThermalStatus>
			<nrg3:bdgConstructionWeight codeSpace="constrWeight_codeSpace">heavy</nrg3:bdgConstructionWeight>
			<nrg3:bdgHeight>
				<nrg3:QualifiedHeight>
					<nrg3:description>This is a type of height</nrg3:description>
					<nrg3:source>Height value source text</nrg3:source>
					<nrg3:value uom="m">15</nrg3:value>
					<nrg3:type codeSpace="height_codeSpace">highestRoofEdge</nrg3:type>
				</nrg3:QualifiedHeight>
			</nrg3:bdgHeight>
			<nrg3:bdgHeight>
				<nrg3:QualifiedHeight>
					<nrg3:description>This is a type of height</nrg3:description>
					<nrg3:source>Height value source text</nrg3:source>
					<nrg3:value uom="m">0</nrg3:value>
					<nrg3:type codeSpace="height_codeSpace">bottomOfConstruction</nrg3:type>
				</nrg3:QualifiedHeight>
			</nrg3:bdgHeight>
			<nrg3:bdgIsProtected>false</nrg3:bdgIsProtected>
			<nrg3:bdgType codeSpace="bdgType_codeSpace">terracedHouse</nrg3:bdgType>
			<nrg3:bdgVolume>
				<nrg3:QualifiedVolume>
					<nrg3:description>This is a type of volume</nrg3:description>
					<nrg3:source>Volume value source text</nrg3:source>
					<nrg3:value uom="m^3">1250</nrg3:value>
					<nrg3:type codeSpace="volume_codeSpace">grossVolume</nrg3:type>
				</nrg3:QualifiedVolume>
			</nrg3:bdgVolume>
			<nrg3:bdgVolume>
				<nrg3:QualifiedVolume>
					<nrg3:description>This is a type of volume</nrg3:description>
					<nrg3:source>Volume value source text</nrg3:source>
					<nrg3:value uom="m^3">875</nrg3:value>
					<nrg3:type codeSpace="volume_codeSpace">netVolume</nrg3:type>
				</nrg3:QualifiedVolume>
			</nrg3:bdgVolume>
			<nrg3:buildingUnit>
				<nrg3:BuildingUnit gml:id="id_building_unit_2_1">
					<gml:description>This is BuildingUnit 2_1</gml:description>
					<gml:name>BuildingUnit 2_1</gml:name>
					<nrg3:referencePoint>
						<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:pos>15 5 1.5</gml:pos>
						</gml:Point>
					</nrg3:referencePoint>
					<nrg3:area>
						<nrg3:QualifiedArea>
							<nrg3:description>This is a type of floor area</nrg3:description>
							<nrg3:source>Area value source</nrg3:source>
							<nrg3:value uom="m^2">100</nrg3:value>
							<nrg3:type codeSpace="area_codeSpace">grossFloorArea</nrg3:type>
						</nrg3:QualifiedArea>
					</nrg3:area>
					<nrg3:area>
						<nrg3:QualifiedArea>
							<nrg3:description>This is a type of floor area</nrg3:description>
							<nrg3:source>Area value source</nrg3:source>
							<nrg3:value uom="m^2">75</nrg3:value>
							<nrg3:type codeSpace="area_codeSpace">energyReferenceArea</nrg3:type>
						</nrg3:QualifiedArea>
					</nrg3:area>
					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:description>This is a type of volume</nrg3:description>
							<nrg3:source>Volume value source</nrg3:source>
							<nrg3:value uom="m^3">300</nrg3:value>
							<nrg3:type codeSpace="volume_codeSpace">grossVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>
					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:description>This is a type of volume</nrg3:description>
							<nrg3:source>Volume value source</nrg3:source>
							<nrg3:value uom="m^3">210</nrg3:value>
							<nrg3:type codeSpace="volume_codeSpace">energyReferenceVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>
					<nrg3:lod1Solid>
						<gml:Solid gml:id="id_building_unit_2_1_lod1_Solid" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:exterior>
								<gml:CompositeSurface gml:id="id_building_unit_2_1_lod1_CompSurf">
									<gml:surfaceMember xlink:href="#Polygon_UUID_f7e48d89-cb96-4297-931c-433bcedaf868"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_38bc3424-399d-4bb9-a651-23e7af6cc516"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_227aa842-a73a-4f6f-b8a2-30bf14b0c58f"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_6927e785-e255-42cd-9838-86c758a37b01"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_1b4cd1d6-8320-4562-a9c7-2c2074bd9272"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_5d887b8c-921b-4264-88f7-8f4340a63ebe"/>
								</gml:CompositeSurface>
							</gml:exterior>
						</gml:Solid>
					</nrg3:lod1Solid>
					<nrg3:lod2Solid>
						<gml:Solid gml:id="id_building_unit_2_1_lod2_Solid" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:exterior>
								<gml:CompositeSurface gml:id="id_building_unit_2_1_lod2_CompSurf">
									<gml:surfaceMember xlink:href="#Polygon_UUID_6db9dba2-ddd7-4fd7-b73c-4fd47a8617fa"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_e612bb86-d24e-4be8-8c77-bd0465d7563d"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_e6349f4f-e90d-4a75-84ef-2252fa979140"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_263413c9-de3f-42ef-87e4-ebe0a6d5e8bf"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_027523db-67f8-4a47-a933-907b9d508d00"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_fc2fdf84-36d0-4e76-8d56-330bdf580243"/>
								</gml:CompositeSurface>
							</gml:exterior>
						</gml:Solid>
					</nrg3:lod2Solid>
					<nrg3:lod3Solid>
						<gml:Solid gml:id="id_building_unit_2_1_lod3_Solid" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:exterior>
								<gml:CompositeSurface gml:id="id_building_unit_2_1_lod3_CompSurf">
									<gml:surfaceMember xlink:href="#Polygon_UUID_9698f429-51ca-4038-9898-91bd53749a07"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_edd65e21-5ad8-4748-934a-66afba856d23"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_80f586db-cb54-48ec-8591-171335272d95"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_d314684b-c7ca-4c2c-857c-b3bb2551a570"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_8fa773d5-434b-4dac-bd9b-136315e69c73"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_0c6640a9-2a84-4c38-874d-cf2116b1868d"/>
								</gml:CompositeSurface>
							</gml:exterior>
						</gml:Solid>
					</nrg3:lod3Solid>
					<nrg3:type codeSpace="buildingUnit_codeSpace_123">residential</nrg3:type>
					<nrg3:numberOfRooms>3</nrg3:numberOfRooms>
					<nrg3:ownershipType codeSpace="ownership_type_codeSpace_abc">government</nrg3:ownershipType>
					<nrg3:address xlink:href="#id_address_2"/>
					<nrg3:energyPerformanceCertificate>
						<nrg3:EnergyPerformanceCertificate gml:id="id_epc_12">
							<gml:description>This is Energy Performance Certificate 12</gml:description>
							<gml:name>Energy Performance Certificate 12</gml:name>
							<nrg3:type codeSpace="epc_codeSpace_iop">heating</nrg3:type>
							<nrg3:label>A+++</nrg3:label>
							<nrg3:value uom="kWh/(m^2*a)">10</nrg3:value>
							<nrg3:issueDate>2017-05-15</nrg3:issueDate>
							<nrg3:expirationDate>2027-05-15</nrg3:expirationDate>
							<nrg3:certificationMethod>CasaClima</nrg3:certificationMethod>
							<nrg3:certificationURI>http://www.epc.nl</nrg3:certificationURI>
						</nrg3:EnergyPerformanceCertificate>
					</nrg3:energyPerformanceCertificate>
					<nrg3:energyPerformanceCertificate>
						<nrg3:EnergyPerformanceCertificate gml:id="id_epc_13">
							<gml:description>This is Energy Performance Certificate 13</gml:description>
							<gml:name>Energy Performance Certificate 13</gml:name>
							<nrg3:type codeSpace="epc_codeSpace_iop">DHW</nrg3:type>
							<nrg3:label>B</nrg3:label>
							<nrg3:value uom="kWh/(m^2*a)">50</nrg3:value>
							<nrg3:issueDate>2018-05-15</nrg3:issueDate>
							<nrg3:expirationDate>2027-05-16</nrg3:expirationDate>
							<nrg3:certificationMethod>CasaClima</nrg3:certificationMethod>
							<nrg3:certificationURI>http://www.epc.nl</nrg3:certificationURI>
						</nrg3:EnergyPerformanceCertificate>
					</nrg3:energyPerformanceCertificate>
					<nrg3:refurbishmentMeasure>
						<nrg3:RefurbishmentMeasure gml:id="id_refurbishment_12">
							<gml:description>This is Refurbishment Measure 12</gml:description>
							<gml:name>Refurbishment Measure 12</gml:name>
							<nrg3:libraryCode codeSpace="refurb_lib_codeSpace">refurb_code_12</nrg3:libraryCode>
							<nrg3:type codeSpace="refurb_codeSpace">other</nrg3:type>
							<nrg3:startDate>2020-02-12</nrg3:startDate>
							<nrg3:endDate>2020-08-12</nrg3:endDate>
						</nrg3:RefurbishmentMeasure>
					</nrg3:refurbishmentMeasure>
					<nrg3:refurbishmentMeasure>
						<nrg3:RefurbishmentMeasure gml:id="id_refurbishment_13">
							<gml:description>This is Refurbishment Measure 13</gml:description>
							<gml:name>Refurbishment Measure 13</gml:name>
							<nrg3:libraryCode codeSpace="refurb_lib_codeSpace">refurb_code_13</nrg3:libraryCode>
							<nrg3:type codeSpace="refurb_codeSpace">changedWindows</nrg3:type>
							<nrg3:startDate>2020-02-13</nrg3:startDate>
							<nrg3:endDate>2020-08-13</nrg3:endDate>
						</nrg3:RefurbishmentMeasure>
					</nrg3:refurbishmentMeasure>
				</nrg3:BuildingUnit>
			</nrg3:buildingUnit>
			<nrg3:buildingUnit>
				<nrg3:BuildingUnit gml:id="id_building_unit_2_2">
					<gml:description>This is BuildingUnit 2_2</gml:description>
					<gml:name>BuildingUnit 2_2</gml:name>
					<nrg3:referencePoint>
						<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:pos>15 5 4.5</gml:pos>
						</gml:Point>
					</nrg3:referencePoint>
					<nrg3:area>
						<nrg3:QualifiedArea>
							<nrg3:description>This is a type of floor area</nrg3:description>
							<nrg3:source>Area value source</nrg3:source>
							<nrg3:value uom="m^2">100</nrg3:value>
							<nrg3:type codeSpace="area_codeSpace">grossFloorArea</nrg3:type>
						</nrg3:QualifiedArea>
					</nrg3:area>
					<nrg3:area>
						<nrg3:QualifiedArea>
							<nrg3:description>This is a type of floor area</nrg3:description>
							<nrg3:source>Area value source</nrg3:source>
							<nrg3:value uom="m^2">75</nrg3:value>
							<nrg3:type codeSpace="area_codeSpace">energyReferenceArea</nrg3:type>
						</nrg3:QualifiedArea>
					</nrg3:area>
					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:description>This is a type of volume</nrg3:description>
							<nrg3:source>Volume value source</nrg3:source>
							<nrg3:value uom="m^3">300</nrg3:value>
							<nrg3:type codeSpace="volume_codeSpace">grossVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>
					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:description>This is a type of volume</nrg3:description>
							<nrg3:source>Volume value source</nrg3:source>
							<nrg3:value uom="m^3">210</nrg3:value>
							<nrg3:type codeSpace="volume_codeSpace">energyReferenceVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>
					<nrg3:lod1Solid>
						<gml:Solid gml:id="id_building_unit_2_2_lod1_Solid" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:exterior>
								<gml:CompositeSurface gml:id="id_building_unit_2_2_lod1_CompSurf">
									<gml:surfaceMember xlink:href="#Polygon_UUID_2d66d836-8ac1-4f78-8e3d-84d244716f58"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_0c0e2de4-a139-4e9c-bebb-05c2c8b0dd93"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_11b3a4cc-0141-4e17-b533-bd227de42539"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_076aaba5-444c-46e8-a424-3e900826577a"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_1351c08a-c20c-45a9-96b7-fe5db284bd77"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_ccdd041a-3f1d-4d5e-abcf-0c73332e64fc"/>
								</gml:CompositeSurface>
							</gml:exterior>
						</gml:Solid>
					</nrg3:lod1Solid>
					<nrg3:lod2Solid>
						<gml:Solid gml:id="id_building_unit_2_2_lod2_Solid" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:exterior>
								<gml:CompositeSurface gml:id="id_building_unit_2_2_lod2_CompSurf">
									<gml:surfaceMember xlink:href="#Polygon_UUID_ce2b1d15-1f01-45ca-88cd-c03cf129eb5f"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_6ab78a09-8b2b-4002-a427-c4e387f7b55b"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_3bb03bc6-7eaa-4949-88b5-19cb41f5e0eb"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_278fffd9-01bb-46a6-a30e-caf3df104356"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_0d3b06d4-faaa-4c09-81ba-49d71660ae25"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_8740fe35-3d35-41e2-b80b-313690d46c7f"/>
								</gml:CompositeSurface>
							</gml:exterior>
						</gml:Solid>
					</nrg3:lod2Solid>
					<nrg3:lod3Solid>
						<gml:Solid gml:id="id_building_unit_2_2_lod3_Solid" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:exterior>
								<gml:CompositeSurface gml:id="id_building_unit_2_2_lod3_CompSurf">
									<gml:surfaceMember xlink:href="#Polygon_UUID_15ddc1c0-f70c-4e9c-b8a2-be9a6005bedd"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_20a0a8ea-853b-4d2f-ae28-0ecf0b833c62"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_8446a0fa-27dd-42be-b607-2ca050e950ce"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_ce5f3fd3-63e4-4de8-bf69-efedc913f3e7"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_ef9d1019-c9cd-4ea7-87a2-75a91c1e5a86"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_b1502fe5-ac31-4b0e-b070-ff18ce79f7cb"/>
								</gml:CompositeSurface>
							</gml:exterior>
						</gml:Solid>
					</nrg3:lod3Solid>
					<nrg3:type codeSpace="buildingUnit_codeSpace_123">commercial</nrg3:type>
					<nrg3:numberOfRooms>3</nrg3:numberOfRooms>
					<nrg3:ownershipType codeSpace="ownership_type_codeSpace_abc">government</nrg3:ownershipType>
					<nrg3:energyPerformanceCertificate>
						<nrg3:EnergyPerformanceCertificate gml:id="id_epc_14">
							<gml:description>This is Energy Performance Certificate 14</gml:description>
							<gml:name>Energy Performance Certificate 14</gml:name>
							<nrg3:type codeSpace="epc_codeSpace_iop">total</nrg3:type>
							<nrg3:label>B</nrg3:label>
							<nrg3:value uom="kWh/(m^2*a)">60</nrg3:value>
							<nrg3:issueDate>2019-05-15</nrg3:issueDate>
							<nrg3:expirationDate>2027-05-17</nrg3:expirationDate>
							<nrg3:certificationMethod>CasaClima</nrg3:certificationMethod>
							<nrg3:certificationURI>http://www.epc.nl</nrg3:certificationURI>
						</nrg3:EnergyPerformanceCertificate>
					</nrg3:energyPerformanceCertificate>
					<nrg3:refurbishmentMeasure>
						<nrg3:RefurbishmentMeasure gml:id="id_refurbishment_14">
							<gml:description>This is Refurbishment Measure 14</gml:description>
							<gml:name>Refurbishment Measure 14</gml:name>
							<nrg3:libraryCode codeSpace="refurb_lib_codeSpace">refurb_code_14</nrg3:libraryCode>
							<nrg3:type codeSpace="refurb_codeSpace">changedDoors</nrg3:type>
							<nrg3:startDate>2020-02-14</nrg3:startDate>
							<nrg3:endDate>2020-08-14</nrg3:endDate>
						</nrg3:RefurbishmentMeasure>
					</nrg3:refurbishmentMeasure>
				</nrg3:BuildingUnit>
			</nrg3:buildingUnit>
			<nrg3:buildingUnit>
				<nrg3:BuildingUnit gml:id="id_building_unit_2_3">
					<gml:description>This is BuildingUnit 2_3</gml:description>
					<gml:name>BuildingUnit 2_3</gml:name>
					<nrg3:referencePoint>
						<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:pos>15 5 10.5</gml:pos>
						</gml:Point>
					</nrg3:referencePoint>
					<nrg3:area>
						<nrg3:QualifiedArea>
							<nrg3:description>This is a type of floor area</nrg3:description>
							<nrg3:source>Area value source</nrg3:source>
							<nrg3:value uom="m^2">100</nrg3:value>
							<nrg3:type codeSpace="area_codeSpace">grossFloorArea</nrg3:type>
						</nrg3:QualifiedArea>
					</nrg3:area>
					<nrg3:area>
						<nrg3:QualifiedArea>
							<nrg3:description>This is a type of floor area</nrg3:description>
							<nrg3:source>Area value source</nrg3:source>
							<nrg3:value uom="m^2">75</nrg3:value>
							<nrg3:type codeSpace="area_codeSpace">energyReferenceArea</nrg3:type>
						</nrg3:QualifiedArea>
					</nrg3:area>
					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:description>This is a type of volume</nrg3:description>
							<nrg3:source>Volume value source</nrg3:source>
							<nrg3:value uom="m^3">300</nrg3:value>
							<nrg3:type codeSpace="volume_codeSpace">grossVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>
					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:description>This is a type of volume</nrg3:description>
							<nrg3:source>Volume value source</nrg3:source>
							<nrg3:value uom="m^3">210</nrg3:value>
							<nrg3:type codeSpace="volume_codeSpace">energyReferenceVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>
					<nrg3:lod1Solid>
						<gml:Solid gml:id="id_building_unit_2_3_lod1_Solid" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:exterior>
								<gml:CompositeSurface gml:id="id_building_unit_2_3_lod1_CompSurf">
									<gml:surfaceMember xlink:href="#Polygon_UUID_8d443fb3-8c4a-40aa-9980-cc73560409c3"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_2ead1f92-3793-4610-a414-e4f4a4283880"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_af9c4620-54e9-4f46-99db-0e8ec50d7778"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_6df44798-6143-490a-802c-3763c7123586"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_4263f1fa-c57b-4d05-9541-4408313c8e9b"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_10f2c826-fe82-473a-ad39-1b8c8e26065e"/>
								</gml:CompositeSurface>
							</gml:exterior>
						</gml:Solid>
					</nrg3:lod1Solid>
					<nrg3:lod2Solid>
						<gml:Solid gml:id="id_building_unit_2_3_lod2_Solid" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:exterior>
								<gml:CompositeSurface gml:id="id_building_unit_2_3_lod2_CompSurf">
									<gml:surfaceMember xlink:href="#Polygon_UUID_15deba7f-b6f0-4e70-b2d7-f393767384a4"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_f7614c7c-06a5-4226-9dc2-62e8fc37814c"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_bc3c3b6a-a6ad-4fa4-9d53-64175d26eeb2"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_4ef67bb0-f581-489f-adfb-5bd8bbe96d34"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_c853cb08-fbcd-4261-9d6a-6c1b39e163f2"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_af7e8d84-e41f-4bd1-81e7-33fea3e29720"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_f5a3d50f-d933-400b-b0f1-d37e08af3204"/>
								</gml:CompositeSurface>
							</gml:exterior>
						</gml:Solid>
					</nrg3:lod2Solid>
					<nrg3:lod3Solid>
						<gml:Solid gml:id="id_building_unit_2_3_lod3_Solid" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:exterior>
								<gml:CompositeSurface gml:id="id_building_unit_2_3_lod3_CompSurf">
									<gml:surfaceMember xlink:href="#Polygon_UUID_18a7fbc7-b871-45cf-9d75-74dd634d5566"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_9fd63853-f47b-4751-9fdb-9486d6eadcb3"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_8b865f8e-6120-46d9-b46a-cac5ff371d52"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_20259bc6-8536-4c69-ab6d-6c8cd1236ac1"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_f5d52191-edc8-4a06-9004-365899587cc7"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_4cd1a3a3-1f1c-4670-89c8-a5668e99dec1"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_728da32e-e9f5-4f52-9b55-b52e497a71ce"/>
								</gml:CompositeSurface>
							</gml:exterior>
						</gml:Solid>
					</nrg3:lod3Solid>
					<nrg3:type codeSpace="buildingUnit_codeSpace_123">office</nrg3:type>
					<nrg3:numberOfRooms>3</nrg3:numberOfRooms>
					<nrg3:ownershipType codeSpace="ownership_type_codeSpace_abc">government</nrg3:ownershipType>
				</nrg3:BuildingUnit>
			</nrg3:buildingUnit>
			<nrg3:energyPerformanceCertificate>
				<nrg3:EnergyPerformanceCertificate gml:id="id_epc_4">
					<gml:description>This is Energy Performance Certificate 4</gml:description>
					<gml:name>Energy Performance Certificate 4</gml:name>
					<nrg3:type codeSpace="epc_codeSpace_iop">cooling</nrg3:type>
					<nrg3:label>C</nrg3:label>
					<nrg3:value uom="kWh/(m^2*a)">110</nrg3:value>
					<nrg3:issueDate>2020-05-15</nrg3:issueDate>
					<nrg3:expirationDate>2027-05-18</nrg3:expirationDate>
					<nrg3:certificationMethod>CasaClima</nrg3:certificationMethod>
					<nrg3:certificationURI>http://www.epc.nl</nrg3:certificationURI>
				</nrg3:EnergyPerformanceCertificate>
			</nrg3:energyPerformanceCertificate>
			<nrg3:refurbishmentMeasure>
				<nrg3:RefurbishmentMeasure gml:id="id_refurbishment_4">
					<gml:description>This is Refurbishment Measure 4</gml:description>
					<gml:name>Refurbishment Measure 4</gml:name>
					<nrg3:libraryCode codeSpace="refurb_lib_codeSpace">refurb_code_4</nrg3:libraryCode>
					<nrg3:type codeSpace="refurb_codeSpace">changedBoiler</nrg3:type>
					<nrg3:startDate>2020-02-04</nrg3:startDate>
					<nrg3:endDate>2020-08-04</nrg3:endDate>
				</nrg3:RefurbishmentMeasure>
			</nrg3:refurbishmentMeasure>
			<nrg3:thermalZone>
				<nrg3:ThermalZone gml:id="id_thermal_zone_2">
					<gml:description>This is ThermalZone 2</gml:description>
					<gml:name>ThermalZone 2</gml:name>
					<nrg3:referencePoint>
						<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:pos>15 5 7.5</gml:pos>
						</gml:Point>
					</nrg3:referencePoint>
					<nrg3:relatedTo>
						<nrg3:CityObjectRelation>
							<nrg3:relationType codeSpace="adjacent_codeList">adjacent</nrg3:relationType>
							<nrg3:relatedTo xlink:href="#id_thermal_zone_1"/>
						</nrg3:CityObjectRelation>
					</nrg3:relatedTo>
					<nrg3:relatedTo>
						<nrg3:CityObjectRelation>
							<nrg3:relationType codeSpace="adjacent_codeList">adjacent</nrg3:relationType>
							<nrg3:relatedTo xlink:href="#id_thermal_zone_3"/>
						</nrg3:CityObjectRelation>
					</nrg3:relatedTo>
					<nrg3:area>
						<nrg3:QualifiedArea>
							<nrg3:description>This is a type of floor area</nrg3:description>
							<nrg3:source>Area value source text</nrg3:source>
							<nrg3:value uom="m^2">300</nrg3:value>
							<nrg3:type codeSpace="area_codeSpace">grossFloorArea</nrg3:type>
						</nrg3:QualifiedArea>
					</nrg3:area>
					<nrg3:area>
						<nrg3:QualifiedArea>
							<nrg3:description>This is a type of floor area</nrg3:description>
							<nrg3:source>Area value source text</nrg3:source>
							<nrg3:value uom="m^2">100</nrg3:value>
							<nrg3:type codeSpace="area_codeSpace">footprintArea</nrg3:type>
						</nrg3:QualifiedArea>
					</nrg3:area>
					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:description>This is a type of volume</nrg3:description>
							<nrg3:source>Volume value source text</nrg3:source>
							<nrg3:value uom="m^3">1250</nrg3:value>
							<nrg3:type codeSpace="volume_codeSpace">grossVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>
					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:description>This is a type of volume</nrg3:description>
							<nrg3:source>Volume value source text</nrg3:source>
							<nrg3:value uom="m^3">875</nrg3:value>
							<nrg3:type codeSpace="volume_codeSpace">netVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>
					<nrg3:lod1Solid>
						<gml:Solid gml:id="id_thermal_zone_2_lod1_Solid" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:exterior>
								<gml:CompositeSurface gml:id="id_thermal_zone_2_lod1_CompSurf">
									<gml:surfaceMember xlink:href="#id_building_2_lod1_Polygon_7"/>
									<gml:surfaceMember xlink:href="#id_building_2_lod1_Polygon_8"/>
									<gml:surfaceMember xlink:href="#id_building_2_lod1_Polygon_9"/>
									<gml:surfaceMember xlink:href="#id_building_2_lod1_Polygon_10"/>
									<gml:surfaceMember xlink:href="#id_building_2_lod1_Polygon_11"/>
									<gml:surfaceMember xlink:href="#id_building_2_lod1_Polygon_12"/>
								</gml:CompositeSurface>
							</gml:exterior>
						</gml:Solid>
					</nrg3:lod1Solid>
					<nrg3:lod2Solid>
						<gml:Solid gml:id="id_thermal_zone_2_lod2_Solid" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:exterior>
								<gml:CompositeSurface gml:id="id_thermal_zone_2_lod2_CompSurf">
									<gml:surfaceMember xlink:href="#id_building_2_polygon_6"/>
									<gml:surfaceMember xlink:href="#id_building_2_polygon_7"/>
									<gml:surfaceMember xlink:href="#id_building_2_polygon_1"/>
									<gml:surfaceMember xlink:href="#id_building_2_polygon_2"/>
									<gml:surfaceMember xlink:href="#id_building_2_polygon_3"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_d59ae86b-9fe3-48ec-ab5c-7169df69141d"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_ae483003-364f-49f5-a437-a8bf08b1c35f"/>
								</gml:CompositeSurface>
							</gml:exterior>
						</gml:Solid>
					</nrg3:lod2Solid>
					<nrg3:lod3Solid>
						<gml:Solid gml:id="id_thermal_zone_2_lod3_Solid" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:exterior>
								<gml:CompositeSurface gml:id="id_thermal_zone_2_lod3_CompSurf">
									<gml:surfaceMember xlink:href="#Polygon_UUID_c1bfd9dc-f727-4a19-89cc-362a3966ca40"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_a0d44fbd-e0b2-4e77-9ef3-c461a6edcfb2"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_66fa26d3-42b5-4954-88dc-15fe4df9a14b"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_4ae0a075-49de-4add-993d-49815d89d011"/>
									<gml:surfaceMember xlink:href="#Polygon_UUID_af665c3a-d69b-4aca-9308-9dd9fb1b8f54"/>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_f11f2d9b-9645-4dc8-8b79-ab1335aec0d2">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>20 5 15 20 0 10 20 10 10 20 5 15</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_051db282-7fea-4525-abd1-5d6c34141429">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>10 0 10 10 5 15 10 10 10 10 0 10</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_5ff036c2-6f26-436a-8449-a2395c1de3ad">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>20 0 0 20 0 10 10 0 10 10 0 0 20 0 0</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_e3b249ac-e67b-4113-b2d5-a56944c241cd">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>20 10 0 10 10 0 10 10 10 20 10 10 20 10 0</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:CompositeSurface>
							</gml:exterior>
						</gml:Solid>
					</nrg3:lod3Solid>
					<nrg3:usageZone xlink:href="#id_usage_zone_2_1"/>
					<nrg3:usageZone xlink:href="#id_usage_zone_2_3"/>
					<nrg3:usageZone xlink:href="#id_usage_zone_2_2"/>
					<nrg3:heatCapacity uom="J/K">500</nrg3:heatCapacity>
					<nrg3:infiltrationRate uom="1/h">0.3</nrg3:infiltrationRate>
					<nrg3:isCooled>false</nrg3:isCooled>
					<nrg3:isHeated>true</nrg3:isHeated>
					<nrg3:coincidesWithLod2Hull>false</nrg3:coincidesWithLod2Hull>
					<nrg3:coincidesWithLod3Hull>false</nrg3:coincidesWithLod3Hull>
					<nrg3:thermalBoundary>
						<bldg:GroundSurface gml:id="id_thermal_zone_2_groundsurface_1">
							<gml:description>This is (ThermalBoundary) GroundSurface 1 (ThermalZone 2)</gml:description>
							<gml:name>(ThermalBoundary) GroundSurface 1 (ThermalZone 2)</gml:name>
							<nrg3:layeredConstruction xlink:href="#id_layered_construction_ground_1"/>
							<nrg3:referencePoint>
								<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
									<gml:pos>15 5 0</gml:pos>
								</gml:Point>
							</nrg3:referencePoint>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface gml:id="id_thermal_zone_2_groundsurface_1_lod2_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
									<gml:surfaceMember xlink:href="#id_building_2_polygon_3"/>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface gml:id="id_thermal_zone_2_groundsurface_1_lod3_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_66fa26d3-42b5-4954-88dc-15fe4df9a14b">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>20 0 0 10 0 0 10 10 0 20 10 0 20 0 0</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
							<nrg3:bdgBdrySurfAzimuth uom="decimal degree">-1</nrg3:bdgBdrySurfAzimuth>
							<nrg3:bdgBdrySurfGroundViewFactor uom="unit interval">1</nrg3:bdgBdrySurfGroundViewFactor>
							<nrg3:bdgBdrySurfInclination uom="decimal degree">180</nrg3:bdgBdrySurfInclination>
							<nrg3:bdgBdrySurfIsAdiabatic>false</nrg3:bdgBdrySurfIsAdiabatic>
							<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
							<nrg3:bdgBdrySurfSkyViewFactor uom="unit interval">0</nrg3:bdgBdrySurfSkyViewFactor>
							<nrg3:bdgBdrySurfTotalSurfaceArea uom="m^2">100</nrg3:bdgBdrySurfTotalSurfaceArea>
						</bldg:GroundSurface>
					</nrg3:thermalBoundary>
					<nrg3:thermalBoundary>
						<bldg:RoofSurface gml:id="id_thermal_zone_2_roofsurface_1">
							<gml:description>This is (ThermalBoundary) RoofSurface 1 (ThermalZone 2)</gml:description>
							<gml:name>(ThermalBoundary) RoofSurface 1 (ThermalZone 2)</gml:name>
							<nrg3:layeredConstruction xlink:href="#id_layered_construction_roof_3"/>
							<nrg3:referencePoint>
								<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
									<gml:pos>15 2.5 12.5</gml:pos>
								</gml:Point>
							</nrg3:referencePoint>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface gml:id="id_thermal_zone_2_roofsurface_1_lod2_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
									<gml:surfaceMember xlink:href="#id_building_2_polygon_1"/>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface gml:id="id_thermal_zone_2_roofsurface_1_lod3_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_4ae0a075-49de-4add-993d-49815d89d011">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>20 0 10 20 5 15 10 5 15 10 0 10 20 0 10</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
							<nrg3:bdgBdrySurfAzimuth uom="decimal degree">180</nrg3:bdgBdrySurfAzimuth>
							<nrg3:bdgBdrySurfGroundViewFactor uom="unit interval">0.5</nrg3:bdgBdrySurfGroundViewFactor>
							<nrg3:bdgBdrySurfInclination uom="decimal degree">45</nrg3:bdgBdrySurfInclination>
							<nrg3:bdgBdrySurfIsAdiabatic>false</nrg3:bdgBdrySurfIsAdiabatic>
							<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0.25</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
							<nrg3:bdgBdrySurfSkyViewFactor uom="unit interval">0.6</nrg3:bdgBdrySurfSkyViewFactor>
							<nrg3:bdgBdrySurfTotalSurfaceArea uom="m^2">70.7107</nrg3:bdgBdrySurfTotalSurfaceArea>
						</bldg:RoofSurface>
					</nrg3:thermalBoundary>
					<nrg3:thermalBoundary>
						<bldg:RoofSurface gml:id="id_thermal_zone_2_roofsurface_2">
							<gml:description>This is (ThermalBoundary) RoofSurface 2 (ThermalZone 2)</gml:description>
							<gml:name>(ThermalBoundary) RoofSurface 2 (ThermalZone 2)</gml:name>
							<nrg3:layeredConstruction xlink:href="#id_layered_construction_roof_3"/>
							<nrg3:referencePoint>
								<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
									<gml:pos>15 7.5 12.5</gml:pos>
								</gml:Point>
							</nrg3:referencePoint>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface gml:id="id_thermal_zone_2_roofsurface_2_lod2_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
									<gml:surfaceMember xlink:href="#id_building_2_polygon_2"/>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface gml:id="id_thermal_zone_2_roofsurface_2_lod3_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_af665c3a-d69b-4aca-9308-9dd9fb1b8f54">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>20 5 15 20 10 10 10 10 10 10 5 15 20 5 15</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
							<nrg3:bdgBdrySurfAzimuth uom="decimal degree">0</nrg3:bdgBdrySurfAzimuth>
							<nrg3:bdgBdrySurfGroundViewFactor uom="unit interval">0.5</nrg3:bdgBdrySurfGroundViewFactor>
							<nrg3:bdgBdrySurfInclination uom="decimal degree">45</nrg3:bdgBdrySurfInclination>
							<nrg3:bdgBdrySurfIsAdiabatic>false</nrg3:bdgBdrySurfIsAdiabatic>
							<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0.25</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
							<nrg3:bdgBdrySurfSkyViewFactor uom="unit interval">0.6</nrg3:bdgBdrySurfSkyViewFactor>
							<nrg3:bdgBdrySurfTotalSurfaceArea uom="m^2">70.7107</nrg3:bdgBdrySurfTotalSurfaceArea>
						</bldg:RoofSurface>
					</nrg3:thermalBoundary>
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="id_thermal_zone_2_wallsurface_1">
							<gml:description>This is (ThermalBoundary) WallSurface 4 (split)</gml:description>
							<gml:name>(ThermalBoundary) WallSurface 4 (split)</gml:name>
							<nrg3:layeredConstruction xlink:href="#id_layered_construction_wall_2"/>
							<nrg3:referencePoint>
								<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
									<gml:pos>20 5 12.5</gml:pos>
								</gml:Point>
							</nrg3:referencePoint>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface gml:id="id_thermal_zone_2_wallsurface_1_lod2_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
									<gml:surfaceMember xlink:href="#Polygon_UUID_a1c78b6b-ddc7-434a-9899-7638cbcb9f69"/>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface gml:id="id_thermal_zone_2_wallsurface_1_lod3_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_4069d235-3c23-41fa-b314-f155c148b5c4">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>20 5 15 20 0 10 20 10 10 20 5 15</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
											<gml:interior>
												<gml:LinearRing>
													<gml:posList>20 5 12.879 20 6.379 11.5 20 3.621 11.5 20 5 12.879</gml:posList>
												</gml:LinearRing>
											</gml:interior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
							<bldg:opening>
								<bldg:Window gml:id="id_thermal_zone_2_wallsurface_1_thermal_opening_4">
									<gml:description>This is Thermal Opening 4</gml:description>
									<gml:name>Thermal Opening 4</gml:name>
									<nrg3:layeredConstruction xlink:href="#id_layered_construction_glazing_5"/>
									<nrg3:referencePoint>
										<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
											<gml:pos>20 5 12.189</gml:pos>
										</gml:Point>
									</nrg3:referencePoint>
									<bldg:lod3MultiSurface>
										<gml:MultiSurface gml:id="id_thermal_zone_2_wallsurface_1_thermal_opening_4_lod3_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
											<gml:surfaceMember>
												<gml:Polygon gml:id="Polygon_UUID_c6b229fc-be42-46b7-a88e-8998b6427e86">
													<gml:exterior>
														<gml:LinearRing>
															<gml:posList>20 5 12.879 20 3.621 11.5 20 6.379 11.5 20 5 12.879</gml:posList>
														</gml:LinearRing>
													</gml:exterior>
												</gml:Polygon>
											</gml:surfaceMember>
										</gml:MultiSurface>
									</bldg:lod3MultiSurface>
									<nrg3:bdgOpnArea uom="m^2">1.9008</nrg3:bdgOpnArea>
									<nrg3:bdgOpnAzimuth uom="decimal degree">90</nrg3:bdgOpnAzimuth>
									<nrg3:bdgOpnGroundViewFactor uom="unit interval">0.5</nrg3:bdgOpnGroundViewFactor>
									<nrg3:bdgOpnInclination uom="decimal degree">90</nrg3:bdgOpnInclination>
									<nrg3:bdgOpnSkyViewFactor uom="unit interval">0.6</nrg3:bdgOpnSkyViewFactor>
								</bldg:Window>
							</bldg:opening>
							<nrg3:bdgBdrySurfAzimuth uom="decimal degree">90</nrg3:bdgBdrySurfAzimuth>
							<nrg3:bdgBdrySurfGroundViewFactor uom="unit interval">0.5</nrg3:bdgBdrySurfGroundViewFactor>
							<nrg3:bdgBdrySurfInclination uom="decimal degree">90</nrg3:bdgBdrySurfInclination>
							<nrg3:bdgBdrySurfIsAdiabatic>false</nrg3:bdgBdrySurfIsAdiabatic>
							<nrg3:bdgBdrySurfOpaqueSurfaceArea uom="m^2">23.0992</nrg3:bdgBdrySurfOpaqueSurfaceArea>
							<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0.08</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
							<nrg3:bdgBdrySurfSkyViewFactor uom="unit interval">0.6</nrg3:bdgBdrySurfSkyViewFactor>
							<nrg3:bdgBdrySurfTotalSurfaceArea uom="m^2">25</nrg3:bdgBdrySurfTotalSurfaceArea>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="id_thermal_zone_2_wallsurface_2">
							<gml:description>This is (ThermalBoundary) WallSurface 6 (split)</gml:description>
							<gml:name>(ThermalBoundary) WallSurface 6 (split)</gml:name>
							<nrg3:layeredConstruction xlink:href="#id_layered_construction_wall_2"/>
							<nrg3:referencePoint>
								<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
									<gml:pos>10 5 7.5</gml:pos>
								</gml:Point>
							</nrg3:referencePoint>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface gml:id="id_thermal_zone_2_wallsurface_2_lod2_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
									<gml:surfaceMember xlink:href="#Polygon_UUID_6b52b561-1122-4439-9121-cf191b5cf608"/>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface gml:id="id_thermal_zone_2_wallsurface_2_lod3_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="id_thermal_zone_2_wallsurface_2_lod3_polygon">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>10 10 10 10 0 10 10 5 15 10 10 10</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
											<gml:interior>
												<gml:LinearRing>
													<gml:posList>10 6.379 11.5 10 5 12.879 10 3.621 11.5 10 6.379 11.5</gml:posList>
												</gml:LinearRing>
											</gml:interior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
							<bldg:opening>
								<bldg:Window gml:id="id_thermal_zone_2_wallsurface_2_thermal_opening_5">
									<gml:description>This is Thermal Opening 5</gml:description>
									<gml:name>Thermal Opening 5</gml:name>
									<nrg3:layeredConstruction xlink:href="#id_layered_construction_glazing_5"/>
									<nrg3:referencePoint>
										<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
											<gml:pos>10 5 12.189</gml:pos>
										</gml:Point>
									</nrg3:referencePoint>
									<bldg:lod3MultiSurface>
										<gml:MultiSurface gml:id="id_thermal_zone_2_wallsurface_2_thermal_opening_5_lod3_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
											<gml:surfaceMember>
												<gml:Polygon gml:id="Polygon_UUID_1899eb39-afe0-4664-b571-339f7e21227b">
													<gml:exterior>
														<gml:LinearRing>
															<gml:posList>10 6.379 11.5 10 3.621 11.5 10 5 12.879 10 6.379 11.5</gml:posList>
														</gml:LinearRing>
													</gml:exterior>
												</gml:Polygon>
											</gml:surfaceMember>
										</gml:MultiSurface>
									</bldg:lod3MultiSurface>
									<nrg3:bdgOpnArea uom="m^2">1.9008</nrg3:bdgOpnArea>
									<nrg3:bdgOpnAzimuth uom="decimal degree">270</nrg3:bdgOpnAzimuth>
									<nrg3:bdgOpnGroundViewFactor uom="unit interval">0.5</nrg3:bdgOpnGroundViewFactor>
									<nrg3:bdgOpnInclination uom="decimal degree">90</nrg3:bdgOpnInclination>
									<nrg3:bdgOpnSkyViewFactor uom="unit interval">0.6</nrg3:bdgOpnSkyViewFactor>
								</bldg:Window>
							</bldg:opening>
							<nrg3:bdgBdrySurfAzimuth uom="decimal degree">270</nrg3:bdgBdrySurfAzimuth>
							<nrg3:bdgBdrySurfGroundViewFactor uom="unit interval">0.5</nrg3:bdgBdrySurfGroundViewFactor>
							<nrg3:bdgBdrySurfInclination uom="decimal degree">90</nrg3:bdgBdrySurfInclination>
							<nrg3:bdgBdrySurfIsAdiabatic>false</nrg3:bdgBdrySurfIsAdiabatic>
							<nrg3:bdgBdrySurfOpaqueSurfaceArea uom="m^2">23.0992</nrg3:bdgBdrySurfOpaqueSurfaceArea>
							<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0.08</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
							<nrg3:bdgBdrySurfSkyViewFactor uom="unit interval">0.6</nrg3:bdgBdrySurfSkyViewFactor>
							<nrg3:bdgBdrySurfTotalSurfaceArea uom="m^2">25</nrg3:bdgBdrySurfTotalSurfaceArea>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="id_thermal_zone_2_wallsurface_3">
							<gml:description>This is (ThermalBoundary) WallSurface 3 (ThermalZone 2)</gml:description>
							<gml:name>(ThermalBoundary) WallSurface 3 (ThermalZone 2)</gml:name>
							<nrg3:layeredConstruction xlink:href="#id_layered_construction_wall_2"/>
							<nrg3:referencePoint>
								<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
									<gml:pos>15 0 5</gml:pos>
								</gml:Point>
							</nrg3:referencePoint>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface gml:id="id_thermal_zone_2_wallsurface_3_lod2_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
									<gml:surfaceMember xlink:href="#id_building_2_polygon_7"/>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface gml:id="id_thermal_zone_2_wallsurface_3_lod3_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_ad93ecd4-ca07-4058-ad53-5ccad3d73f7e">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>20 0 0 20 0 10 10 0 10 10 0 0 20 0 0</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
											<gml:interior>
												<gml:LinearRing>
													<gml:posList>17 0 3 13 0 3 13 0 7 17 0 7 17 0 3</gml:posList>
												</gml:LinearRing>
											</gml:interior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
							<bldg:opening>
								<bldg:Window gml:id="id_thermal_zone_2_wallsurface_3_thermal_opening_6">
									<gml:description>This is Thermal Opening 6</gml:description>
									<gml:name>Thermal Opening 6</gml:name>
									<nrg3:layeredConstruction xlink:href="#id_layered_construction_glazing_5"/>
									<nrg3:referencePoint>
										<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
											<gml:pos>15 0 5</gml:pos>
										</gml:Point>
									</nrg3:referencePoint>
									<bldg:lod3MultiSurface>
										<gml:MultiSurface gml:id="id_thermal_zone_2_wallsurface_3_thermal_opening_6_lod3_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
											<gml:surfaceMember>
												<gml:Polygon gml:id="Polygon_UUID_3fdfa217-bd81-4dbc-9546-c411af8406ed">
													<gml:exterior>
														<gml:LinearRing>
															<gml:posList>17 0 3 17 0 7 13 0 7 13 0 3 17 0 3</gml:posList>
														</gml:LinearRing>
													</gml:exterior>
												</gml:Polygon>
											</gml:surfaceMember>
										</gml:MultiSurface>
									</bldg:lod3MultiSurface>
									<nrg3:bdgOpnArea uom="m^2">16</nrg3:bdgOpnArea>
									<nrg3:bdgOpnAzimuth uom="decimal degree">180</nrg3:bdgOpnAzimuth>
									<nrg3:bdgOpnGroundViewFactor uom="unit interval">0.5</nrg3:bdgOpnGroundViewFactor>
									<nrg3:bdgOpnInclination uom="decimal degree">90</nrg3:bdgOpnInclination>
									<nrg3:bdgOpnSkyViewFactor uom="unit interval">0.6</nrg3:bdgOpnSkyViewFactor>
								</bldg:Window>
							</bldg:opening>
							<nrg3:bdgBdrySurfAzimuth uom="decimal degree">180</nrg3:bdgBdrySurfAzimuth>
							<nrg3:bdgBdrySurfGroundViewFactor uom="unit interval">0.5</nrg3:bdgBdrySurfGroundViewFactor>
							<nrg3:bdgBdrySurfInclination uom="decimal degree">90</nrg3:bdgBdrySurfInclination>
							<nrg3:bdgBdrySurfIsAdiabatic>false</nrg3:bdgBdrySurfIsAdiabatic>
							<nrg3:bdgBdrySurfOpaqueSurfaceArea uom="m^2">84</nrg3:bdgBdrySurfOpaqueSurfaceArea>
							<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0.16</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
							<nrg3:bdgBdrySurfSkyViewFactor uom="unit interval">0.6</nrg3:bdgBdrySurfSkyViewFactor>
							<nrg3:bdgBdrySurfTotalSurfaceArea uom="m^2">100</nrg3:bdgBdrySurfTotalSurfaceArea>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>
					<nrg3:thermalBoundary>
						<bldg:WallSurface gml:id="id_thermal_zone_2_wallsurface_4">
							<gml:description>This is (ThermalBoundary) WallSurface 4 (ThermalZone 2)</gml:description>
							<gml:name>(ThermalBoundary) WallSurface 4 (ThermalZone 2)</gml:name>
							<nrg3:layeredConstruction xlink:href="#id_layered_construction_wall_2"/>
							<nrg3:referencePoint>
								<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
									<gml:pos>15 10 5</gml:pos>
								</gml:Point>
							</nrg3:referencePoint>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface gml:id="id_thermal_zone_2_wallsurface_4_lod2_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
									<gml:surfaceMember xlink:href="#id_building_2_polygon_6"/>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface gml:id="id_thermal_zone_2_wallsurface_4_lod3_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_693ec286-de99-4f7a-af45-fa2e55f122c1">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>20 10 0 10 10 0 10 10 10 20 10 10 20 10 0</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
											<gml:interior>
												<gml:LinearRing>
													<gml:posList>17 10 3 17 10 7 13 10 7 13 10 3 17 10 3</gml:posList>
												</gml:LinearRing>
											</gml:interior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
							<bldg:opening>
								<bldg:Window gml:id="id_thermal_zone_2_wallsurface_4_thermal_opening_7">
									<gml:description>This is Thermal Opening 7</gml:description>
									<gml:name>Thermal Opening 7</gml:name>
									<nrg3:layeredConstruction xlink:href="#id_layered_construction_glazing_5"/>
									<nrg3:referencePoint>
										<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
											<gml:pos>15 10 5</gml:pos>
										</gml:Point>
									</nrg3:referencePoint>
									<bldg:lod3MultiSurface>
										<gml:MultiSurface gml:id="id_thermal_zone_2_wallsurface_4_thermal_opening_7_lod3_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
											<gml:surfaceMember>
												<gml:Polygon gml:id="Polygon_UUID_f8325e8c-d5ad-45b1-91b2-a0e9f7390aa2">
													<gml:exterior>
														<gml:LinearRing>
															<gml:posList>17 10 3 13 10 3 13 10 7 17 10 7 17 10 3</gml:posList>
														</gml:LinearRing>
													</gml:exterior>
												</gml:Polygon>
											</gml:surfaceMember>
										</gml:MultiSurface>
									</bldg:lod3MultiSurface>
									<nrg3:bdgOpnArea uom="m^2">16</nrg3:bdgOpnArea>
									<nrg3:bdgOpnAzimuth uom="decimal degree">0</nrg3:bdgOpnAzimuth>
									<nrg3:bdgOpnGroundViewFactor uom="unit interval">0.5</nrg3:bdgOpnGroundViewFactor>
									<nrg3:bdgOpnInclination uom="decimal degree">90</nrg3:bdgOpnInclination>
									<nrg3:bdgOpnSkyViewFactor uom="unit interval">0.6</nrg3:bdgOpnSkyViewFactor>
								</bldg:Window>
							</bldg:opening>
							<nrg3:bdgBdrySurfAzimuth uom="decimal degree">0</nrg3:bdgBdrySurfAzimuth>
							<nrg3:bdgBdrySurfGroundViewFactor uom="unit interval">0.5</nrg3:bdgBdrySurfGroundViewFactor>
							<nrg3:bdgBdrySurfInclination uom="decimal degree">90</nrg3:bdgBdrySurfInclination>
							<nrg3:bdgBdrySurfIsAdiabatic>false</nrg3:bdgBdrySurfIsAdiabatic>
							<nrg3:bdgBdrySurfOpaqueSurfaceArea uom="m^2">84</nrg3:bdgBdrySurfOpaqueSurfaceArea>
							<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0.16</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
							<nrg3:bdgBdrySurfSkyViewFactor uom="unit interval">0.6</nrg3:bdgBdrySurfSkyViewFactor>
							<nrg3:bdgBdrySurfTotalSurfaceArea uom="m^2">100</nrg3:bdgBdrySurfTotalSurfaceArea>
						</bldg:WallSurface>
					</nrg3:thermalBoundary>
					<nrg3:thermalBoundary>
						<nrg3:PartyWallSurface gml:id="id_thermal_zone_2_partywallsurface_1">
							<gml:description>This is (ThermalBoundary) PartyWallSurface 12</gml:description>
							<gml:name>(ThermalBoundary) PartyWallSurface 12</gml:name>
							<nrg3:layeredConstruction xlink:href="#id_layered_construction_wall_2"/>
							<nrg3:referencePoint>
								<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
									<gml:pos>10 5 5</gml:pos>
								</gml:Point>
							</nrg3:referencePoint>
							<nrg3:relatedTo>
								<nrg3:CityObjectRelation>
									<nrg3:relationType codeSpace="adjacent_codeList">adjacent</nrg3:relationType>
									<nrg3:relatedTo xlink:href="#id_thermal_zone_1_partywallsurface_1"/>
								</nrg3:CityObjectRelation>
							</nrg3:relatedTo>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface gml:id="id_thermal_zone_2_partywallsurface_1_lod2_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
									<gml:surfaceMember xlink:href="#id_building_2_polygon_cs1"/>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface gml:id="id_thermal_zone_2_partywallsurface_1_lod3_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_c1bfd9dc-f727-4a19-89cc-362a3966ca40">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>10 10 10 10 10 0 10 0 0 10 0 10 10 10 10</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
							<nrg3:bdgBdrySurfAzimuth uom="decimal degree">270</nrg3:bdgBdrySurfAzimuth>
							<nrg3:bdgBdrySurfGroundViewFactor uom="unit interval">0</nrg3:bdgBdrySurfGroundViewFactor>
							<nrg3:bdgBdrySurfInclination uom="decimal degree">90</nrg3:bdgBdrySurfInclination>
							<nrg3:bdgBdrySurfIsAdiabatic>false</nrg3:bdgBdrySurfIsAdiabatic>
							<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
							<nrg3:bdgBdrySurfSkyViewFactor uom="unit interval">0</nrg3:bdgBdrySurfSkyViewFactor>
							<nrg3:bdgBdrySurfTotalSurfaceArea uom="m^2">100</nrg3:bdgBdrySurfTotalSurfaceArea>
						</nrg3:PartyWallSurface>
					</nrg3:thermalBoundary>
					<nrg3:thermalBoundary>
						<nrg3:PartyWallSurface gml:id="id_thermal_zone_2_partywallsurface_2">
							<gml:description>This is (ThermalBoundary) PartyWallSurface 3</gml:description>
							<gml:name>(ThermalBoundary) PartyWallSurface 3</gml:name>
							<nrg3:layeredConstruction xlink:href="#id_layered_construction_wall_2"/>
							<nrg3:referencePoint>
								<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
									<gml:pos>20 5 5</gml:pos>
								</gml:Point>
							</nrg3:referencePoint>
							<nrg3:relatedTo>
								<nrg3:CityObjectRelation>
									<nrg3:relationType codeSpace="adjacent_codeList">adjacent</nrg3:relationType>
									<nrg3:relatedTo xlink:href="#id_thermal_zone_3_partywallsurface_1"/>
								</nrg3:CityObjectRelation>
							</nrg3:relatedTo>
							<bldg:lod2MultiSurface>
								<gml:MultiSurface gml:id="id_thermal_zone_2_partywallsurface_2_lod2_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
									<gml:surfaceMember xlink:href="#id_building_2_polygon_cs2"/>
								</gml:MultiSurface>
							</bldg:lod2MultiSurface>
							<bldg:lod3MultiSurface>
								<gml:MultiSurface gml:id="id_thermal_zone_2_partywallsurface_2_lod3_geom" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_a0d44fbd-e0b2-4e77-9ef3-c461a6edcfb2">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>20 10 10 20 0 10 20 0 0 20 10 0 20 10 10</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:MultiSurface>
							</bldg:lod3MultiSurface>
							<nrg3:bdgBdrySurfAzimuth uom="decimal degree">90</nrg3:bdgBdrySurfAzimuth>
							<nrg3:bdgBdrySurfGroundViewFactor uom="unit interval">0</nrg3:bdgBdrySurfGroundViewFactor>
							<nrg3:bdgBdrySurfInclination uom="decimal degree">90</nrg3:bdgBdrySurfInclination>
							<nrg3:bdgBdrySurfIsAdiabatic>false</nrg3:bdgBdrySurfIsAdiabatic>
							<nrg3:bdgBdrySurfOpeningToSurfaceRatio uom="unit interval">0</nrg3:bdgBdrySurfOpeningToSurfaceRatio>
							<nrg3:bdgBdrySurfSkyViewFactor uom="unit interval">0</nrg3:bdgBdrySurfSkyViewFactor>
							<nrg3:bdgBdrySurfTotalSurfaceArea uom="m^2">100</nrg3:bdgBdrySurfTotalSurfaceArea>
						</nrg3:PartyWallSurface>
					</nrg3:thermalBoundary>
				</nrg3:ThermalZone>
			</nrg3:thermalZone>
			<nrg3:usageZone>
				<nrg3:UsageZone gml:id="id_usage_zone_2_1">
					<gml:description>This is UsageZone 2_1</gml:description>
					<gml:name>UsageZone 2_1</gml:name>
					<nrg3:referencePoint>
						<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:pos>15 5 1.5</gml:pos>
						</gml:Point>
					</nrg3:referencePoint>
					<nrg3:area>
						<nrg3:QualifiedArea>
							<nrg3:description>This is a type of floor area</nrg3:description>
							<nrg3:source>Area value source text</nrg3:source>
							<nrg3:value uom="m^2">100</nrg3:value>
							<nrg3:type codeSpace="area_codeSpace">grossFloorArea</nrg3:type>
						</nrg3:QualifiedArea>
					</nrg3:area>
					<nrg3:area>
						<nrg3:QualifiedArea>
							<nrg3:description>This is a type of floor area</nrg3:description>
							<nrg3:source>Area value source text</nrg3:source>
							<nrg3:value uom="m^2">75</nrg3:value>
							<nrg3:type codeSpace="area_codeSpace">energyReferenceArea</nrg3:type>
						</nrg3:QualifiedArea>
					</nrg3:area>
					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:description>This is a type of volume</nrg3:description>
							<nrg3:source>Volume value source text</nrg3:source>
							<nrg3:value uom="m^3">300</nrg3:value>
							<nrg3:type codeSpace="volume_codeSpace">grossVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>
					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:description>This is a type of volume</nrg3:description>
							<nrg3:source>Volume value source text</nrg3:source>
							<nrg3:value uom="m^3">210</nrg3:value>
							<nrg3:type codeSpace="volume_codeSpace">energyReferenceVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>
					<nrg3:lod1Solid>
						<gml:Solid gml:id="id_usage_zone_2_1_lod1_Solid" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:exterior>
								<gml:CompositeSurface gml:id="id_usage_zone_2_1_lod1_CompSurf">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_f7e48d89-cb96-4297-931c-433bcedaf868">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>20 10 0 10 10 0 10 10 3 17 10 3 20 10 3 20 10 0</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_38bc3424-399d-4bb9-a651-23e7af6cc516">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>20 9.167 3 20 7 3 20 0 3 20 0 0 20 10 0 20 10 3 20 9.167 3</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_227aa842-a73a-4f6f-b8a2-30bf14b0c58f">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>10 3 3 10 0.833 3 10 0 3 17 0 3 20 0 3 20 7 3 20 9.167 3 20 10 3 17 10 3 10 10 3 10 3 3</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_6927e785-e255-42cd-9838-86c758a37b01">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>20 0 0 10 0 0 10 10 0 20 10 0 20 0 0</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_1b4cd1d6-8320-4562-a9c7-2c2074bd9272">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>10 0 3 10 0 0 20 0 0 20 0 3 17 0 3 10 0 3</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_5d887b8c-921b-4264-88f7-8f4340a63ebe">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>10 10 0 10 0 0 10 0 3 10 0.833 3 10 3 3 10 10 3 10 10 0</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:CompositeSurface>
							</gml:exterior>
						</gml:Solid>
					</nrg3:lod1Solid>
					<nrg3:lod2Solid>
						<gml:Solid gml:id="id_usage_zone_2_1_lod2_Solid" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:exterior>
								<gml:CompositeSurface gml:id="id_usage_zone_2_1_lod2_CompSurf">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_9698f429-51ca-4038-9898-91bd53749a07">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>20 10 0 10 10 0 10 10 3 17 10 3 20 10 3 20 10 0</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_edd65e21-5ad8-4748-934a-66afba856d23">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>20 9.167 3 20 7 3 20 0 3 20 0 0 20 10 0 20 10 3 20 9.167 3</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_80f586db-cb54-48ec-8591-171335272d95">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>10 3 3 10 0.833 3 10 0 3 17 0 3 20 0 3 20 7 3 20 9.167 3 20 10 3 17 10 3 10 10 3 10 3 3</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_d314684b-c7ca-4c2c-857c-b3bb2551a570">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>20 0 0 10 0 0 10 10 0 20 10 0 20 0 0</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_8fa773d5-434b-4dac-bd9b-136315e69c73">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>10 0 3 10 0 0 20 0 0 20 0 3 17 0 3 10 0 3</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_0c6640a9-2a84-4c38-874d-cf2116b1868d">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>10 10 0 10 0 0 10 0 3 10 0.833 3 10 3 3 10 10 3 10 10 0</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:CompositeSurface>
							</gml:exterior>
						</gml:Solid>
					</nrg3:lod2Solid>
					<nrg3:lod3Solid>
						<gml:Solid gml:id="id_usage_zone_2_1_lod3_Solid" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:exterior>
								<gml:CompositeSurface gml:id="id_usage_zone_2_1_lod3_CompSurf">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_6db9dba2-ddd7-4fd7-b73c-4fd47a8617fa">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>20 10 0 10 10 0 10 10 3 17 10 3 20 10 3 20 10 0</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_e612bb86-d24e-4be8-8c77-bd0465d7563d">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>20 9.167 3 20 7 3 20 0 3 20 0 0 20 10 0 20 10 3 20 9.167 3</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_e6349f4f-e90d-4a75-84ef-2252fa979140">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>10 3 3 10 0.833 3 10 0 3 17 0 3 20 0 3 20 7 3 20 9.167 3 20 10 3 17 10 3 10 10 3 10 3 3</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_263413c9-de3f-42ef-87e4-ebe0a6d5e8bf">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>20 0 0 10 0 0 10 10 0 20 10 0 20 0 0</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_027523db-67f8-4a47-a933-907b9d508d00">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>10 0 3 10 0 0 20 0 0 20 0 3 17 0 3 10 0 3</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_fc2fdf84-36d0-4e76-8d56-330bdf580243">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>10 10 0 10 0 0 10 0 3 10 0.833 3 10 3 3 10 10 3 10 10 0</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:CompositeSurface>
							</gml:exterior>
						</gml:Solid>
					</nrg3:lod3Solid>
					<nrg3:buildingUnit xlink:href="#id_building_unit_2_1"/>
					<nrg3:type codeSpace="usageZone_codeSpace_123">residential</nrg3:type>
					<nrg3:isPrimary>true</nrg3:isPrimary>
					<nrg3:numberOfBuildingUnits>1</nrg3:numberOfBuildingUnits>
					<nrg3:internalHeatGains uom="W/m^2">100</nrg3:internalHeatGains>
					<nrg3:internalHeatGainsConvectiveFraction uom="unit interval">0.3</nrg3:internalHeatGainsConvectiveFraction>
					<nrg3:internalHeatGainsLatentFraction uom="unit interval">0.2</nrg3:internalHeatGainsLatentFraction>
					<nrg3:internalHeatGainsRadiantFraction uom="unit interval">0.5</nrg3:internalHeatGainsRadiantFraction>
					<nrg3:coolingSchedule xlink:href="#id_atomic_schedule_1"/>
					<nrg3:heatingSchedule xlink:href="#id_dual_value_schedule_1"/>
					<nrg3:ventilationSchedule xlink:href="#id_composite_schedule_1"/>
					<nrg3:occupiedBy>
						<nrg3:Occupants gml:id="id_occupants_2">
							<gml:description>This is Occupants 2</gml:description>
							<gml:name>Occupants 2</gml:name>
							<nrg3:type codeSpace="occ_codeSpace_xyz">patients</nrg3:type>
							<nrg3:numberOfOccupants>11</nrg3:numberOfOccupants>
							<nrg3:heatDissipation uom="W/m^2">100</nrg3:heatDissipation>
							<nrg3:heatDissipationConvectiveFraction uom="unit interval">0.3</nrg3:heatDissipationConvectiveFraction>
							<nrg3:heatDissipationLatentFraction uom="unit interval">0.2</nrg3:heatDissipationLatentFraction>
							<nrg3:heatDissipationRadiantFraction uom="unit interval">0.5</nrg3:heatDissipationRadiantFraction>
							<nrg3:occupancyRate xlink:href="#id_atomic_schedule_2"/>
							<nrg3:averageDietType codeSpace="diet_codeSpace">omnivorous</nrg3:averageDietType>
							<nrg3:averageIncomeLevel codeSpace="income_level codeSpace">middle</nrg3:averageIncomeLevel>
							<nrg3:averageInstructionLevel codeSpace="instruction_level_codeSpace">university</nrg3:averageInstructionLevel>
						</nrg3:Occupants>
					</nrg3:occupiedBy>
				</nrg3:UsageZone>
			</nrg3:usageZone>
			<nrg3:usageZone>
				<nrg3:UsageZone gml:id="id_usage_zone_2_2">
					<gml:description>This is UsageZone 2_2</gml:description>
					<gml:name>UsageZone 2_2</gml:name>
					<nrg3:referencePoint>
						<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:pos>15 5 4.5</gml:pos>
						</gml:Point>
					</nrg3:referencePoint>
					<nrg3:area>
						<nrg3:QualifiedArea>
							<nrg3:description>This is a type of floor area</nrg3:description>
							<nrg3:source>Area value source text</nrg3:source>
							<nrg3:value uom="m^2">100</nrg3:value>
							<nrg3:type codeSpace="area_codeSpace">grossFloorArea</nrg3:type>
						</nrg3:QualifiedArea>
					</nrg3:area>
					<nrg3:area>
						<nrg3:QualifiedArea>
							<nrg3:description>This is a type of floor area</nrg3:description>
							<nrg3:source>Area value source text</nrg3:source>
							<nrg3:value uom="m^2">75</nrg3:value>
							<nrg3:type codeSpace="area_codeSpace">energyReferenceArea</nrg3:type>
						</nrg3:QualifiedArea>
					</nrg3:area>
					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:description>This is a type of volume</nrg3:description>
							<nrg3:source>Volume value source text</nrg3:source>
							<nrg3:value uom="m^3">300</nrg3:value>
							<nrg3:type codeSpace="volume_codeSpace">grossVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>
					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:description>This is a type of volume</nrg3:description>
							<nrg3:source>Volume value source text</nrg3:source>
							<nrg3:value uom="m^3">210</nrg3:value>
							<nrg3:type codeSpace="volume_codeSpace">energyReferenceVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>
					<nrg3:lod1Solid>
						<gml:Solid gml:id="id_usage_zone_2_2_lod1_Solid" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:exterior>
								<gml:CompositeSurface gml:id="id_usage_zone_2_2_lod1_CompSurf">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_2d66d836-8ac1-4f78-8e3d-84d244716f58">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>20 9.167 6 20 4 6 20 0 6 20 0 3 20 0.833 3 20 7 3 20 10 3 20 10 6 20 9.167 6</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_0c0e2de4-a139-4e9c-bebb-05c2c8b0dd93">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>17 10 3 10 10 3 10 10 6 14 10 6 20 10 6 20 10 3 17 10 3</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_11b3a4cc-0141-4e17-b533-bd227de42539">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>17 0 3 10 0 3 10 3 3 10 9.167 3 10 10 3 17 10 3 20 10 3 20 7 3 20 0.833 3 20 0 3 17 0 3</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_076aaba5-444c-46e8-a424-3e900826577a">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>10 0 6 10 0 3 17 0 3 20 0 3 20 0 6 14 0 6 10 0 6</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_1351c08a-c20c-45a9-96b7-fe5db284bd77">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>10 6 6 10 0.833 6 10 0 6 14 0 6 20 0 6 20 4 6 20 9.167 6 20 10 6 14 10 6 10 10 6 10 6 6</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_ccdd041a-3f1d-4d5e-abcf-0c73332e64fc">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>10 9.167 3 10 3 3 10 0 3 10 0 6 10 0.833 6 10 6 6 10 10 6 10 10 3 10 9.167 3</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:CompositeSurface>
							</gml:exterior>
						</gml:Solid>
					</nrg3:lod1Solid>
					<nrg3:lod2Solid>
						<gml:Solid gml:id="id_usage_zone_2_2_lod2_Solid" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:exterior>
								<gml:CompositeSurface gml:id="id_usage_zone_2_2_lod2_CompSurf">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_15ddc1c0-f70c-4e9c-b8a2-be9a6005bedd">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>20 9.167 6 20 4 6 20 0 6 20 0 3 20 0.833 3 20 7 3 20 10 3 20 10 6 20 9.167 6</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_20a0a8ea-853b-4d2f-ae28-0ecf0b833c62">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>17 10 3 10 10 3 10 10 6 14 10 6 20 10 6 20 10 3 17 10 3</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_8446a0fa-27dd-42be-b607-2ca050e950ce">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>17 0 3 10 0 3 10 3 3 10 9.167 3 10 10 3 17 10 3 20 10 3 20 7 3 20 0.833 3 20 0 3 17 0 3</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_ce5f3fd3-63e4-4de8-bf69-efedc913f3e7">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>10 0 6 10 0 3 17 0 3 20 0 3 20 0 6 14 0 6 10 0 6</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_ef9d1019-c9cd-4ea7-87a2-75a91c1e5a86">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>10 6 6 10 0.833 6 10 0 6 14 0 6 20 0 6 20 4 6 20 9.167 6 20 10 6 14 10 6 10 10 6 10 6 6</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_b1502fe5-ac31-4b0e-b070-ff18ce79f7cb">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>10 9.167 3 10 3 3 10 0 3 10 0 6 10 0.833 6 10 6 6 10 10 6 10 10 3 10 9.167 3</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:CompositeSurface>
							</gml:exterior>
						</gml:Solid>
					</nrg3:lod2Solid>
					<nrg3:lod3Solid>
						<gml:Solid gml:id="id_usage_zone_2_2_lod3_Solid" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:exterior>
								<gml:CompositeSurface gml:id="id_usage_zone_2_2_lod3_CompSurf">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_ce2b1d15-1f01-45ca-88cd-c03cf129eb5f">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>20 9.167 6 20 4 6 20 0 6 20 0 3 20 0.833 3 20 7 3 20 10 3 20 10 6 20 9.167 6</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_6ab78a09-8b2b-4002-a427-c4e387f7b55b">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>17 10 3 10 10 3 10 10 6 14 10 6 20 10 6 20 10 3 17 10 3</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_3bb03bc6-7eaa-4949-88b5-19cb41f5e0eb">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>17 0 3 10 0 3 10 3 3 10 9.167 3 10 10 3 17 10 3 20 10 3 20 7 3 20 0.833 3 20 0 3 17 0 3</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_278fffd9-01bb-46a6-a30e-caf3df104356">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>10 0 6 10 0 3 17 0 3 20 0 3 20 0 6 14 0 6 10 0 6</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_0d3b06d4-faaa-4c09-81ba-49d71660ae25">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>10 6 6 10 0.833 6 10 0 6 14 0 6 20 0 6 20 4 6 20 9.167 6 20 10 6 14 10 6 10 10 6 10 6 6</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_8740fe35-3d35-41e2-b80b-313690d46c7f">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>10 9.167 3 10 3 3 10 0 3 10 0 6 10 0.833 6 10 6 6 10 10 6 10 10 3 10 9.167 3</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:CompositeSurface>
							</gml:exterior>
						</gml:Solid>
					</nrg3:lod3Solid>
					<nrg3:buildingUnit xlink:href="#id_building_unit_2_2"/>
					<nrg3:type codeSpace="usageZone_codeSpace_123">commercial</nrg3:type>
					<nrg3:isPrimary>false</nrg3:isPrimary>
					<nrg3:numberOfBuildingUnits>1</nrg3:numberOfBuildingUnits>
					<nrg3:internalHeatGains uom="W/m^2">100</nrg3:internalHeatGains>
					<nrg3:internalHeatGainsConvectiveFraction uom="unit interval">0.3</nrg3:internalHeatGainsConvectiveFraction>
					<nrg3:internalHeatGainsLatentFraction uom="unit interval">0.2</nrg3:internalHeatGainsLatentFraction>
					<nrg3:internalHeatGainsRadiantFraction uom="unit interval">0.5</nrg3:internalHeatGainsRadiantFraction>
					<nrg3:coolingSchedule xlink:href="#id_atomic_schedule_1"/>
					<nrg3:heatingSchedule xlink:href="#id_dual_value_schedule_1"/>
					<nrg3:ventilationSchedule xlink:href="#id_composite_schedule_1"/>
					<nrg3:occupiedBy>
						<nrg3:Occupants gml:id="id_occupants_3">
							<gml:description>This is Occupants 3</gml:description>
							<gml:name>Occupants 3</gml:name>
							<nrg3:type codeSpace="occ_codeSpace_xyz">students</nrg3:type>
							<nrg3:numberOfOccupants>15</nrg3:numberOfOccupants>
							<nrg3:heatDissipation uom="W/m^2">100</nrg3:heatDissipation>
							<nrg3:heatDissipationConvectiveFraction uom="unit interval">0.3</nrg3:heatDissipationConvectiveFraction>
							<nrg3:heatDissipationLatentFraction uom="unit interval">0.2</nrg3:heatDissipationLatentFraction>
							<nrg3:heatDissipationRadiantFraction uom="unit interval">0.5</nrg3:heatDissipationRadiantFraction>
							<nrg3:occupancyRate xlink:href="#id_atomic_schedule_2"/>
							<nrg3:averageDietType codeSpace="diet_codeSpace">omnivorous</nrg3:averageDietType>
							<nrg3:averageIncomeLevel codeSpace="income_level codeSpace">middle</nrg3:averageIncomeLevel>
							<nrg3:averageInstructionLevel codeSpace="instruction_level_codeSpace">university</nrg3:averageInstructionLevel>
						</nrg3:Occupants>
					</nrg3:occupiedBy>
				</nrg3:UsageZone>
			</nrg3:usageZone>
			<nrg3:usageZone>
				<nrg3:UsageZone gml:id="id_usage_zone_2_3">
					<gml:description>This is UsageZone 2_3</gml:description>
					<gml:name>UsageZone 2_3</gml:name>
					<nrg3:referencePoint>
						<gml:Point srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:pos>15 5 10.5</gml:pos>
						</gml:Point>
					</nrg3:referencePoint>
					<nrg3:area>
						<nrg3:QualifiedArea>
							<nrg3:description>This is a type of floor area</nrg3:description>
							<nrg3:source>Area value source text</nrg3:source>
							<nrg3:value uom="m^2">100</nrg3:value>
							<nrg3:type codeSpace="area_codeSpace">grossFloorArea</nrg3:type>
						</nrg3:QualifiedArea>
					</nrg3:area>
					<nrg3:area>
						<nrg3:QualifiedArea>
							<nrg3:description>This is a type of floor area</nrg3:description>
							<nrg3:source>Area value source text</nrg3:source>
							<nrg3:value uom="m^2">75</nrg3:value>
							<nrg3:type codeSpace="area_codeSpace">energyReferenceArea</nrg3:type>
						</nrg3:QualifiedArea>
					</nrg3:area>
					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:description>This is a type of volume</nrg3:description>
							<nrg3:source>Volume value source text</nrg3:source>
							<nrg3:value uom="m^3">300</nrg3:value>
							<nrg3:type codeSpace="volume_codeSpace">grossVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>
					<nrg3:volume>
						<nrg3:QualifiedVolume>
							<nrg3:description>This is a type of volume</nrg3:description>
							<nrg3:source>Volume value source text</nrg3:source>
							<nrg3:value uom="m^3">210</nrg3:value>
							<nrg3:type codeSpace="volume_codeSpace">energyReferenceVolume</nrg3:type>
						</nrg3:QualifiedVolume>
					</nrg3:volume>
					<nrg3:lod1Solid>
						<gml:Solid gml:id="id_usage_zone_2_3_lod1_Solid" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:exterior>
								<gml:CompositeSurface gml:id="id_usage_zone_2_3_lod1_CompSurf">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_8d443fb3-8c4a-40aa-9980-cc73560409c3">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>10 0 6 10 10 6 20 10 6 20 0 6 10 0 6</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_2ead1f92-3793-4610-a414-e4f4a4283880">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>10 0 6 20 0 6 20 0 12.5 10 0 12.5 10 0 6</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_af9c4620-54e9-4f46-99db-0e8ec50d7778">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>20 0 6 20 10 6 20 10 12.5 20 0 12.5 20 0 6</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_6df44798-6143-490a-802c-3763c7123586">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>20 10 6 10 10 6 10 10 12.5 20 10 12.5 20 10 6</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_4263f1fa-c57b-4d05-9541-4408313c8e9b">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>10 10 6 10 0 6 10 0 12.5 10 10 12.5 10 10 6</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_10f2c826-fe82-473a-ad39-1b8c8e26065e">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>10 0 12.5 20 0 12.5 20 10 12.5 10 10 12.5 10 0 12.5</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:CompositeSurface>
							</gml:exterior>
						</gml:Solid>
					</nrg3:lod1Solid>
					<nrg3:lod2Solid>
						<gml:Solid gml:id="id_usage_zone_2_3_lod2_Solid" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:exterior>
								<gml:CompositeSurface gml:id="id_usage_zone_2_3_lod2_CompSurf">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_18a7fbc7-b871-45cf-9d75-74dd634d5566">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>10 5 15 10 0 10 20 0 10 20 5 15 10 5 15</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_9fd63853-f47b-4751-9fdb-9486d6eadcb3">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>20 0 10 20 0 6 20 0.833 6 20 4 6 20 10 6 20 10 10 20 5 15 20 0 10</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_8b865f8e-6120-46d9-b46a-cac5ff371d52">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>14 0 6 10 0 6 10 6 6 10 9.167 6 10 10 6 14 10 6 20 10 6 20 4 6 20 0.833 6 20 0 6 14 0 6</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_20259bc6-8536-4c69-ab6d-6c8cd1236ac1">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>10 0 10 10 0 6 14 0 6 20 0 6 20 0 10 10 0 10</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_f5d52191-edc8-4a06-9004-365899587cc7">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>14 10 6 10 10 6 10 10 10 20 10 10 20 10 6 14 10 6</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_4cd1a3a3-1f1c-4670-89c8-a5668e99dec1">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>10 9.167 6 10 6 6 10 0 6 10 0 10 10 5 15 10 10 10 10 10 6 10 9.167 6</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_728da32e-e9f5-4f52-9b55-b52e497a71ce">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>20 10 10 10 10 10 10 5 15 20 5 15 20 10 10</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:CompositeSurface>
							</gml:exterior>
						</gml:Solid>
					</nrg3:lod2Solid>
					<nrg3:lod3Solid>
						<gml:Solid gml:id="id_usage_zone_2_3_lod3_Solid" srsName="urn:ogc:def:crs,crs:EPSG::28992,crs:EPSG::5109" srsDimension="3">
							<gml:exterior>
								<gml:CompositeSurface gml:id="id_usage_zone_2_3_lod3_CompSurf">
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_15deba7f-b6f0-4e70-b2d7-f393767384a4">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>10 5 15 10 0 10 20 0 10 20 5 15 10 5 15</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_f7614c7c-06a5-4226-9dc2-62e8fc37814c">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>20 0 10 20 0 6 20 0.833 6 20 4 6 20 10 6 20 10 10 20 5 15 20 0 10</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_bc3c3b6a-a6ad-4fa4-9d53-64175d26eeb2">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>14 0 6 10 0 6 10 6 6 10 9.167 6 10 10 6 14 10 6 20 10 6 20 4 6 20 0.833 6 20 0 6 14 0 6</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_4ef67bb0-f581-489f-adfb-5bd8bbe96d34">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>10 0 10 10 0 6 14 0 6 20 0 6 20 0 10 10 0 10</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_c853cb08-fbcd-4261-9d6a-6c1b39e163f2">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>14 10 6 10 10 6 10 10 10 20 10 10 20 10 6 14 10 6</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_af7e8d84-e41f-4bd1-81e7-33fea3e29720">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>10 9.167 6 10 6 6 10 0 6 10 0 10 10 5 15 10 10 10 10 10 6 10 9.167 6</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
									<gml:surfaceMember>
										<gml:Polygon gml:id="Polygon_UUID_f5a3d50f-d933-400b-b0f1-d37e08af3204">
											<gml:exterior>
												<gml:LinearRing>
													<gml:posList>20 10 10 10 10 10 10 5 15 20 5 15 20 10 10</gml:posList>
												</gml:LinearRing>
											</gml:exterior>
										</gml:Polygon>
									</gml:surfaceMember>
								</gml:CompositeSurface>
							</gml:exterior>
						</gml:Solid>
					</nrg3:lod3Solid>
					<nrg3:buildingUnit xlink:href="#id_building_unit_2_3"/>
					<nrg3:type codeSpace="usageZone_codeSpace_123">office</nrg3:type>
					<nrg3:isPrimary>false</nrg3:isPrimary>
					<nrg3:numberOfBuildingUnits>1</nrg3:numberOfBuildingUnits>
					<nrg3:internalHeatGains uom="W/m^2">100</nrg3:internalHeatGains>
					<nrg3:internalHeatGainsConvectiveFraction uom="unit interval">0.3</nrg3:internalHeatGainsConvectiveFraction>
					<nrg3:internalHeatGainsLatentFraction uom="unit interval">0.2</nrg3:internalHeatGainsLatentFraction>
					<nrg3:internalHeatGainsRadiantFraction uom="unit interval">0.5</nrg3:internalHeatGainsRadiantFraction>
					<nrg3:coolingSchedule xlink:href="#id_atomic_schedule_1"/>
					<nrg3:heatingSchedule xlink:href="#id_dual_value_schedule_1"/>
					<nrg3:ventilationSchedule xlink:href="#id_composite_schedule_1"/>
					<nrg3:occupiedBy>
						<nrg3:Occupants gml:id="id_occupants_4">
							<gml:description>This is Occupants 4</gml:description>
							<gml:name>Occupants 4</gml:name>
							<nrg3:type codeSpace="occ_codeSpace_xyz">visitors</nrg3:type>
							<nrg3:numberOfOccupants>46</nrg3:numberOfOccupants>
							<nrg3:heatDissipation uom="W/m^2">100</nrg3:heatDissipation>
							<nrg3:heatDissipationConvectiveFraction uom="unit interval">0.3</nrg3:heatDissipationConvectiveFraction>
							<nrg3:heatDissipationLatentFraction uom="unit interval">0.2</nrg3:heatDissipationLatentFraction>
							<nrg3:heatDissipationRadiantFraction uom="unit interval">0.5</nrg3:heatDissipationRadiantFraction>
							<nrg3:occupancyRate xlink:href="#id_atomic_schedule_2"/>
							<nrg3:averageDietType codeSpace="diet_codeSpace">omnivorous</nrg3:averageDietType>
							<nrg3:averageIncomeLevel codeSpace="income_level codeSpace">middle</nrg3:averageIncomeLevel>
							<nrg3:averageInstructionLevel codeSpace="instruction_level_codeSpace">university</nrg3:averageInstructionLevel>
						</nrg3:Occupants>
					</nrg3:occupiedBy>
				</nrg3:UsageZone>
			</nrg3:usageZone>
		</bldg:Building>
	</core:cityObjectMember>
	</core:CityModel>
