"""
run.py - per-building orchestrator + test harness.

Run examples:
    python -m citygml2idf.run --stage 1z-nowin --building Building_B1
    python -m citygml2idf.run --stage 1z-nowin --building id_building_11 path/to/file.gml

Each run writes one folder per building:
    output/runs/<BuildingId>__<stage>/
        middle_layer_trace_<BuildingId>.json   parser evidence / audit view
        middle_layer_idf_<BuildingId>.json     clean writer contract
        <BuildingId>.idf
        eplusout.*

The parser path is the same for test and real input. Stage flags only gate existing
zone/window behavior.
"""

from __future__ import annotations

import argparse
import json
import os
import sys

from . import config
from .citygml import xml_io
from .idf_building_visualize import preview_building
from .model.reader import build_both_middle_layers
from .write import writer

_HERE = os.path.dirname(os.path.abspath(__file__))
RUNS_DIR = os.path.join(_HERE, "output", "runs")

STAGES = {
    "1z-nowin": {"force_single_zone": True, "enable_windows": False},
    "1z-win": {"force_single_zone": True, "enable_windows": True},
    "mz-nowin": {"force_single_zone": False, "enable_windows": False},
    "mz-win": {"force_single_zone": False, "enable_windows": True},
    "real": {"force_single_zone": False, "enable_windows": True},
}


def apply_stage(stage_name=None, default_wwr=None):
    """Apply named runtime config overrides for this process only."""
    if stage_name:
        stage = STAGES[stage_name]
        config.FORCE_SINGLE_ZONE = stage["force_single_zone"]
        config.ENABLE_WINDOWS = stage["enable_windows"]
        config.DEFAULT_WWR = None
    if default_wwr is not None:
        config.DEFAULT_WWR = default_wwr


def flag_tag():
    """Short label for the current test stage, e.g. 1Z_noWin / MZ_Win."""
    zone_tag = "1Z" if config.FORCE_SINGLE_ZONE else "MZ"
    window_tag = "Win" if config.ENABLE_WINDOWS else "noWin"
    tag = f"{zone_tag}_{window_tag}"
    if config.DEFAULT_WWR is not None:
        wwr = int(round(config.DEFAULT_WWR * 100))
        tag += f"_DWWR{wwr}"
    return tag


def _building_by_id(middle, building_id):
    for building in middle.get("buildings", []):
        if building.get("id") == building_id:
            return building
    return None


def single_building_middle_layer(middle, building_id):
    """Return a per-building subset for either trace or IDF middle-layer view."""
    building = _building_by_id(middle, building_id)
    if building is None:
        raise KeyError(f"building '{building_id}' not found in {middle.get('view', 'middle')} view")

    construction_names = {surface.get("construction") for surface in building.get("surfaces", [])}
    constructions_used = {
        name: middle["constructions"][name]
        for name in construction_names
        if name in middle.get("constructions", {})
    }
    material_names = {
        material
        for construction in constructions_used.values()
        for material in construction.get("layers", [])
    }
    materials_used = {
        name: middle["materials"][name]
        for name in material_names
        if name in middle.get("materials", {})
    }
    return {
        "view": middle.get("view"),
        "crs": middle.get("crs"),
        "buildings": [building],
        "constructions": constructions_used,
        "materials": materials_used,
        "window_construction": middle.get("window_construction"),
    }


def _write_json(path, payload):
    with open(path, "w", encoding="utf-8") as out_file:
        json.dump(payload, out_file, indent=2)


def run_building(building, trace_middle, idf_middle, stage_tag):
    """Build the IDF + run EnergyPlus for one clean-IDF building view."""
    building_id = building["id"]
    run_directory = os.path.join(RUNS_DIR, f"{building_id}__{stage_tag}")
    os.makedirs(run_directory, exist_ok=True)

    trace_one = single_building_middle_layer(trace_middle, building_id)
    idf_one = single_building_middle_layer(idf_middle, building_id)

    trace_path = os.path.join(run_directory, f"middle_layer_trace_{building_id}.json")
    idf_middle_path = os.path.join(run_directory, f"middle_layer_idf_{building_id}.json")
    _write_json(trace_path, trace_one)
    _write_json(idf_middle_path, idf_one)

    preview_path = preview_building(building, run_directory)

    idf_path = writer.build_idf(
        building,
        idf_middle["constructions"],
        idf_middle["materials"],
        idf_middle.get("window_construction"),
        out_dir=run_directory,
    )
    return_code, error_text = writer.run_energyplus(idf_path, out_dir=run_directory)

    severe_lines = [line for line in error_text.splitlines()
                    if "** Severe" in line or "** Fatal" in line]
    warning_count = sum(1 for line in error_text.splitlines() if "** Warning" in line)
    window_count = sum(len(surface.get("windows", [])) for surface in building.get("surfaces", []))
    status = "OK" if (return_code == 0 and not severe_lines) else f"{len(severe_lines)} SEVERE/FATAL"
    print(f"  {building_id:<12} surfaces={len(building.get('surfaces', [])):>2}  windows={window_count}"
          f"  exit={return_code}  warnings={warning_count}  {status}")
    if preview_path:
        print(f"       preview={os.path.basename(preview_path)}")
    print(f"       trace={os.path.basename(trace_path)}")
    print(f"       idf_middle={os.path.basename(idf_middle_path)}")
    for line in severe_lines[:8]:
        print("       ", line.strip())
    return not severe_lines


def main(building_id=None, path=None, stage=None, default_wwr=None):
    apply_stage(stage, default_wwr)
    stage_tag = flag_tag()
    print(f"STAGE flags: FORCE_SINGLE_ZONE={config.FORCE_SINGLE_ZONE}  "
          f"ENABLE_WINDOWS={config.ENABLE_WINDOWS}  DEFAULT_WWR={config.DEFAULT_WWR}  -> '{stage_tag}'")
    doc = xml_io.CityGMLDoc(path or xml_io.DEFAULT_INPUT)
    trace_middle, idf_middle = build_both_middle_layers(doc)
    target_buildings = [building for building in idf_middle["buildings"]
                        if building_id is None or building["id"] == building_id]
    if not target_buildings:
        available_ids = [building["id"] for building in idf_middle["buildings"]]
        print(f"No building '{building_id}'. Available: {available_ids}")
        return

    print(f"Building(s): {[building['id'] for building in target_buildings]}"
          f"  -> output/runs/<id>__{stage_tag}/")
    for building in target_buildings:
        run_building(building, trace_middle, idf_middle, stage_tag)


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
        if path is None and (item.lower().endswith(".gml") or os.path.exists(item)):
            path = item
        elif building_id is None:
            building_id = item
        else:
            parser.error(f"unexpected extra argument: {item}")
    return args, building_id, path


if __name__ == "__main__":
    parsed, building_argument, path_argument = parse_args(sys.argv[1:])
    main(building_argument, path_argument, parsed.stage, parsed.default_wwr)
