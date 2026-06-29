"""write — MIDDLE LAYER → EnergyPlus IDF.

writer.py builds one empty IDF per building (eppy newidfobject, block by block) from
output/middle_layer.json — Zone + BuildingSurface:Detailed + Construction +
Material/NoMass/AirGap — then runs EnergyPlus 23.1 to check for Severe/Fatal.
Reuses the old internship code only as an eppy PATTERN, never its extrusion.
"""
