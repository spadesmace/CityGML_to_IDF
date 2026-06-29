"""
run.py — per-building orchestrator + test harness (the professor's step-by-step method).

    python -m citygml2idf.run [BuildingId] [path-to-gml]
    python -m citygml2idf.run --stage 1z-nowin Building_B1

For each building (or just the named one): build its middle layer, write the IDF, run
EnergyPlus, and put EVERYTHING for that test in ONE self-contained folder, so you can
keep and analyse each run:

    output/runs/<BuildingId>__<zone>_<win>/
        <BuildingId>.idf
        middle_layer_<BuildingId>.json          (the per-building bridge, to inspect)
        eplusout.err, eplusout.dxf, eplusout.eso, ...   (ALL EnergyPlus output)

The <zone>_<win> tag comes from the active stage flags (e.g. 1Z_noWin, MZ_Win), so
different test STAGES (RULES_code section F) land in different folders and never
overwrite each other.
"""

from __future__ import annotations

import argparse
import json
import os
import sys

from . import config
from .citygml import xml_io
from .idf_building_visualize import preview_building
from .model.reader import build_middle_layer
from .write import writer

_HERE = os.path.dirname(os.path.abspath(__file__))
RUNS_DIR = os.path.join(_HERE, "output", "runs")

STAGES = {
    # Stage flags override config.py for THIS process only. They do not create a
    # second parser path; build_middle_layer still runs the same production code.
    "1z-nowin": {"force_single_zone": True, "enable_windows": False},
    "1z-win": {"force_single_zone": True, "enable_windows": True},
    "mz-nowin": {"force_single_zone": False, "enable_windows": False},
    "mz-win": {"force_single_zone": False, "enable_windows": True},
    "real": {"force_single_zone": False, "enable_windows": True},
}


def apply_stage(stage_name=None, default_wwr=None):
    """Apply a named test stage as runtime config overrides.

    This keeps test and real pipeline code identical: the stage changes only the
    gates already used by openings.py and zones.py. config.py remains the default
    production configuration unless a command explicitly overrides it.
    """
    if stage_name:
        stage = STAGES[stage_name]
        config.FORCE_SINGLE_ZONE = stage["force_single_zone"]
        config.ENABLE_WINDOWS = stage["enable_windows"]
        config.DEFAULT_WWR = None
    if default_wwr is not None:
        config.DEFAULT_WWR = default_wwr


def flag_tag():
    """Short label for the current test stage, e.g. '1Z_noWin' / 'MZ_Win'."""
    zone_tag = "1Z" if config.FORCE_SINGLE_ZONE else "MZ"
    window_tag = "Win" if config.ENABLE_WINDOWS else "noWin"
    tag = f"{zone_tag}_{window_tag}"
    if config.DEFAULT_WWR is not None:
        wwr = int(round(config.DEFAULT_WWR * 100))
        tag += f"_DWWR{wwr}"
    return tag


def single_building_middle_layer(middle, building):
    """A self-contained middle layer for ONE building (its surfaces + only the
    constructions/materials it uses), saved beside its IDF/outputs for inspection."""
    construction_names = {surface.get("construction") for surface in building["surfaces"]}
    constructions_used = {name: middle["constructions"][name]
                          for name in construction_names if name in middle.get("constructions", {})}
    material_names = {material for construction in constructions_used.values()
                      for material in construction["layers"]}
    materials_used = {name: middle["materials"][name]
                      for name in material_names if name in middle.get("materials", {})}
    return {"crs": middle["crs"], "buildings": [building],
            "constructions": constructions_used, "materials": materials_used,
            "window_construction": middle.get("window_construction")}


def run_building(building, middle, stage_tag):
    """Build the IDF + run EnergyPlus for one building, all into its own run folder."""
    run_directory = os.path.join(RUNS_DIR, f"{building['id']}__{stage_tag}")
    os.makedirs(run_directory, exist_ok=True)

    # 1. the per-building middle layer (the bridge — kept beside its IDF/outputs)
    middle_layer_path = os.path.join(run_directory, f"middle_layer_{building['id']}.json")
    with open(middle_layer_path, "w", encoding="utf-8") as middle_file:
        json.dump(single_building_middle_layer(middle, building), middle_file, indent=2)
    preview_path = preview_building(building, run_directory)

    # 2. the IDF and 3. EnergyPlus — both into the SAME folder
    idf_path = writer.build_idf(building, middle["constructions"], middle["materials"],
                                middle.get("window_construction"), out_dir=run_directory)
    return_code, error_text = writer.run_energyplus(idf_path, out_dir=run_directory)

    severe_lines = [line for line in error_text.splitlines()
                    if "** Severe" in line or "** Fatal" in line]
    warning_count = sum(1 for line in error_text.splitlines() if "** Warning" in line)
    window_count = sum(len(surface.get("windows", [])) for surface in building["surfaces"])
    status = "OK" if (return_code == 0 and not severe_lines) else f"{len(severe_lines)} SEVERE/FATAL"
    print(f"  {building['id']:<12} surfaces={len(building['surfaces']):>2}  windows={window_count}"
          f"  exit={return_code}  warnings={warning_count}  {status}")
    if preview_path:
        print(f"       preview={os.path.basename(preview_path)}")
    for line in severe_lines[:8]:
        print("       ", line.strip())
    return not severe_lines


def main(building_id=None, path=None, stage=None, default_wwr=None):
    apply_stage(stage, default_wwr)
    stage_tag = flag_tag()
    print(f"STAGE flags: FORCE_SINGLE_ZONE={config.FORCE_SINGLE_ZONE}  "
          f"ENABLE_WINDOWS={config.ENABLE_WINDOWS}  DEFAULT_WWR={config.DEFAULT_WWR}  -> '{stage_tag}'")
    doc = xml_io.CityGMLDoc(path or xml_io.DEFAULT_INPUT)
    middle = build_middle_layer(doc)
    target_buildings = [building for building in middle["buildings"]
                        if building_id is None or building["id"] == building_id]
    if not target_buildings:
        available_ids = [building["id"] for building in middle["buildings"]]
        print(f"No building '{building_id}'. Available: {available_ids}")
        return

    print(f"Building(s): {[building['id'] for building in target_buildings]}"
          f"  -> output/runs/<id>__{stage_tag}/")
    for building in target_buildings:
        run_building(building, middle, stage_tag)


def parse_args(argv):
    parser = argparse.ArgumentParser(
        description="Build and run staged CityGML -> IDF tests without editing config.py.")
    parser.add_argument("items", nargs="*",
                        help="Optional BuildingId and/or CityGML path, in either order.")
    parser.add_argument("--stage", choices=sorted(STAGES),
                        help="Runtime stage: 1z-nowin, 1z-win, mz-nowin, mz-win, or real.")
    parser.add_argument("--building", help="Building gml:id to run, e.g. Building_B3.")
    parser.add_argument("--default-wwr", type=float,
                        help="TEST ONLY: synthesize windows on walls with no window source.")
    args = parser.parse_args(argv)

    building_id = args.building
    path = None
    for item in args.items:
        if item.startswith("Building") and building_id is None:
            building_id = item
        elif path is None:
            path = item
        else:
            parser.error(f"unexpected extra argument: {item}")
    return args, building_id, path


if __name__ == "__main__":
    parsed, building_argument, path_argument = parse_args(sys.argv[1:])
    main(building_argument, path_argument, parsed.stage, parsed.default_wwr)
