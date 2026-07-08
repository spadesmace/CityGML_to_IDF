"""
run.py - per-building orchestrator. Read ONE CityGML/Energy ADE file and, for each
building in it, build one IDF and run EnergyPlus. PRESENCE-BASED: the file decides the
zones/windows — there are no test stages or modes.

Run:
    python -m citygml2idf.run path/to/file.gml                          # every building
    python -m citygml2idf.run --building id_building_11 path/to/file.gml  # just one
    python -m citygml2idf.run citygml2idf/input/cases/X.gml


Each building writes one folder:
    output/runs/<BuildingId>/
        middle_layer_<BuildingId>.json   the one typed middle layer (data + provenance)
        <BuildingId>.idf
        eplusout.*
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
    """Build the IDF + run EnergyPlus for one building of the middle layer."""
    building_id = building.id
    run_directory = os.path.join(RUNS_DIR, building_id)
    os.makedirs(run_directory, exist_ok=True)

    subset = model.subset_for_building(building_id)   # one building + only the objects it uses
    middle_path = os.path.join(run_directory, f"middle_layer_{building_id}.json")
    _write_json(middle_path, subset)

    idf_path = writer.build_idf(
        building,
        model.constructions,
        model.materials,
        model.window_constructions,
        out_dir=run_directory,
    )
    return_code, error_text = writer.run_energyplus(idf_path, out_dir=run_directory)

    severe_lines = [line for line in error_text.splitlines()
                    if "** Severe" in line or "** Fatal" in line]
    warning_count = sum(1 for line in error_text.splitlines() if "** Warning" in line)
    window_count = sum(len(surface.windows) for surface in building.surfaces)
    status = "OK" if (return_code == 0 and not severe_lines) else f"{len(severe_lines)} SEVERE/FATAL"
    print(f"  {building_id:<12} surfaces={len(building.surfaces):>2}  windows={window_count}"
          f"  exit={return_code}  warnings={warning_count}  {status}")
    print(f"       middle={os.path.basename(middle_path)}")
    for line in severe_lines[:8]:
        print("       ", line.strip())
    return not severe_lines


def main(building_id=None, path=None):
    doc = xml_io.CityGMLDoc(path)
    model = build_middle_layer(doc)
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
        description="Build one IDF per building from a CityGML/Energy ADE file and run EnergyPlus.")
    parser.add_argument("items", nargs="*",
                        help="Optional BuildingId and/or CityGML path, in either order.")
    parser.add_argument("--building", help="Only this building gml:id (default: every building).")
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
    return building_id, path


if __name__ == "__main__":
    building_argument, path_argument = parse_args(sys.argv[1:])
    main(building_argument, path_argument)
