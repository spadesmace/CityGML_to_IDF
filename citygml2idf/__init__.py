# cityjson2idf — CityJSON/CityGML (Energy ADE) to EnergyPlus IDF converter.
#
# This package is fully independent from the existing GeoJSON pipeline (src/).
# It NEVER modifies anything in src/ or templates/ — it only imports the
# SingleFamilyHouse IDF writer from src/BuildingClasses.py (read-only) and
# reuses templates/singleFamilyHouse_test.idf + Energy+.idd (EnergyPlus 23.1).
