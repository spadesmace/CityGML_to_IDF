"""
Generate IDFs from a CityGML/Energy ADE file.

This command builds the middle layer and writes one output folder per buildable
building. It does not run EnergyPlus.

Run:
    python -m citygml2idf.run path/to/file.gml

Each building writes:
    output/runs/<BuildingId>/
        middle_layer_<BuildingId>.json
        <BuildingId>.idf

Run the generated IDF manually in EP-Launch, or with:
    python -m citygml2idf.run_energyplus output/runs/<BuildingId>/<BuildingId>.idf --weather path/to/weather.epw
"""

from __future__ import annotations

import argparse
import json
import os
import sys

from .citygml import xml_io
from .model.model import to_jsonable
from .model.reader import build_middle_layer
from .write import writer

_HERE = os.path.dirname(os.path.abspath(__file__))
RUNS_DIR = os.path.join(_HERE, "output", "runs")


def _write_json(path, payload):
    with open(path, "w", encoding="utf-8") as out_file:
        json.dump(payload, out_file, indent=2, default=to_jsonable)


def run_building(building, model):
    """Build the middle-layer JSON and IDF for one building."""
    building_id = building.id
    run_directory = os.path.join(RUNS_DIR, building_id)
    os.makedirs(run_directory, exist_ok=True)

    # ONE slice, used for BOTH outputs: the audit JSON and the IDF cannot disagree.
    subset = model.subset_for_building(building_id)
    middle_path = os.path.join(run_directory, f"middle_layer_{building_id}.json")
    _write_json(middle_path, subset)

    idf_path = writer.build_idf(
        building,
        subset.constructions,
        subset.materials,
        subset.window_constructions,
        out_dir=run_directory,
    )
    window_count = sum(len(surface.windows) for surface in building.surfaces)
    print(f"  {building_id:<12} surfaces={len(building.surfaces):>2}  windows={window_count}"
          f"  IDF_CREATED")
    print(f"       idf={idf_path}")
    print(f"       middle={middle_path}")
    return idf_path


def main(building_id=None, path=None, detailed_interior=False):
    doc = xml_io.CityGMLDoc(path)
    model = build_middle_layer(doc, detailed_interior=detailed_interior)
    buildable = [building for building in model.buildings if building.surfaces]
    target_buildings = [building for building in buildable
                        if building_id is None or building.id == building_id]
    if not target_buildings:
        available_ids = [building.id for building in buildable]
        print(f"No building '{building_id}'. Available: {available_ids}")
        return

    print(f"Building(s): {[building.id for building in target_buildings]}  -> output/runs/<id>/")
    for building in target_buildings:
        run_building(building, model)


def parse_args(argv):
    parser = argparse.ArgumentParser(
        description="Build one IDF per building from a CityGML/Energy ADE file.")
    parser.add_argument("items", nargs="*",
                        help="Optional BuildingId and/or CityGML path, in either order.")
    parser.add_argument("--building", help="Only this building gml:id (default: every building).")
    parser.add_argument("--detailed-interior", action="store_true",
                        help="Model interior heat transfer (interior faces become Surface pairs). "
                             "Default: fast (interior faces Adiabatic).")
    args = parser.parse_args(argv)

    building_id = args.building
    path = None
    for item in args.items:
        if path is None and (item.lower().endswith(".gml") or os.path.exists(item)):
            path = item
        elif building_id is None:
            building_id = item
        else:
            parser.error(f"unexpected extra argument: {item}")
    return building_id, path, args.detailed_interior


if __name__ == "__main__":
    building_argument, path_argument, detailed_interior_argument = parse_args(sys.argv[1:])
    main(building_argument, path_argument, detailed_interior=detailed_interior_argument)


"""
how to run : 
1- test one zone sample : 
python -m citygml2idf.run citygml2idf\input\cases\case6.1_lod3_1zone_hull_win_SpecificationADE.gml

2- test two zones sample (for detailed and fast):
 FAST :  python -m citygml2idf.run citygml2idf\input\cases\case3.1_lod2_2zone_nowin_synth.gml
 DETAILED : python -m citygml2idf.run --detailed-interior citygml2idf\input\cases\case3.1_lod2_2zone_nowin_synth.gml

"""
