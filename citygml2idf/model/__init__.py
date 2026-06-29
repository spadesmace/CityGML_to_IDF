"""model — assemble the writer-neutral MIDDLE LAYER (the firewall).

reader.py turns the parsed CityGML into output/middle_layer.json (geometry now;
constructions wired in next). The writer reads ONLY the middle layer, so the reader
and writer can change independently.
"""
