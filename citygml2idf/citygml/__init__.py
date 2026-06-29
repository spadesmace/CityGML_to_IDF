"""citygml — the 'read the CityGML file' duty.

The only place in citygml2idf that touches lxml/XML. Everything downstream
(geometry, semantics, model, write) consumes the clean Python this package
hands back, so swapping the XML library only ever changes code in here.
"""
