"""semantics — what each CityGML / Energy ADE thing MEANS for EnergyPlus.

surface_types.py      = the type -> role -> E+ Surface_Type + boundary table.
building_surfaces.py  = collect building envelope surfaces and choose geometry per object.
No XML and no geometry math here — just meaning/lookup, so the rules live in one
obvious place to edit.
"""
