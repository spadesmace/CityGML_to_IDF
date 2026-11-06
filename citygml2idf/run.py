"""
run.py — the command line: one CityGML file in, one IDF (+ its audit JSON) per building out.

HOW A RUN GOES (with the command for each branch)

    python -m citygml2idf.run  ...
              │
       Did you type a .gml file?
       ├─ NO  → it ASKS you:  1. which .gml file
       │                      2. fast or detailed?
       │                      3. also run EnergyPlus?  (if yes → 4. which weather file)
       │        command:  python -m citygml2idf.run
       └─ YES → it does exactly what you typed, and asks nothing
                command:  python -m citygml2idf.run file.gml   (+ any option below)
              │
       it reads the GML → writes one IDF + one JSON per building
              │
       Is there a weather file (typed, or answered)?
       ├─ NO  → stops here:  output/<gml name>_FAST (or _DETAILED)/<building>/   IDF + JSON
       │        command:  python -m citygml2idf.run file.gml
       └─ YES → also runs EnergyPlus → adds eplusout.err / .csv / .sql in the same building folder
                command:  python -m citygml2idf.run file.gml --weather file.epw

OPTIONS (after the file, in any order, any combination)
    --detailed-interior     detailed instead of fast: a face between two zones passes heat
    --weather <file.epw>    also run EnergyPlus on each IDF (short: -w)
    --out-dir <folder>      your own run folder instead of output/<gml name>_<FAST or DETAILED>/
    --building <gml:id>     only that one building

Without a .gml file it always asks: a typed --out-dir or --building still counts, and the answers
decide fast or detailed and EnergyPlus. A building that gets no IDF is warned once
(model/reader.py). EnergyPlus alone, on one IDF you already have:
    python -m citygml2idf.tools.energyplus <file.idf> --weather <file.epw>
"""

from __future__ import annotations

import argparse
import json
import os
import sys

from .citygml import xml_io
from .model.model import to_jsonable
from .model.reader import build_middle_layer
from .tools import energyplus          # importing it does not need EnergyPlus installed
from .write import writer

_HERE = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.join(_HERE, "output")


def _write_json(path, payload):
    """Write one building's slice of the Model as indented JSON (the audit trail)."""
    with open(path, "w", encoding="utf-8") as out_file:
        json.dump(payload, out_file, indent=2, default=to_jsonable)


def default_out_dir(path, detailed_interior):
    """output/<gml file name>_<FAST or DETAILED>: one folder per run, so runs never overwrite each other."""
    file_name = os.path.splitext(os.path.basename(path))[0]
    mode = "FAST"
    if detailed_interior:
        mode = "DETAILED"
    return os.path.join(OUTPUT_DIR, f"{file_name}_{mode}")


def run_building(building, model, out_dir):
    """Write one building's IDF and its middle-layer JSON into the building's own folder.

    Parameters
    ----------
    building : model.Building
        The building to write (one IDF per building).
    model : model.Model
        Everything read from the GML file; only this building's part is written.
    out_dir : str
        The run folder; this building gets the folder out_dir/<building id>/.

    Returns
    -------
    str
        The path of the IDF that was written.

    Notes
    -----
    The JSON and the IDF are written from the same part of the model
    (Model.subset_for_building), so the two files can never disagree.
    """
    building_id = building.id
    run_directory = os.path.join(out_dir, building_id)
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


def main(building_id=None, path=None, detailed_interior=False, out_dir=None, weather=None):
    """Read one CityGML file and write an IDF + JSON for each of its buildings.

    Parameters
    ----------
    building_id : str, optional
        Write only this building (its gml:id); None writes every building that has an IDF.
    path : str
        The CityGML (.gml) file to read.
    detailed_interior : bool, optional
        False (default, "fast"): a face between two zones passes no heat (Adiabatic).
        True ("detailed"): that face is paired with its twin in the other zone, so heat
        flows between the zones.
    out_dir : str, optional
        The run folder; None means output/<gml name>_<FAST or DETAILED>.
    weather : str, optional
        An EPW weather file. When given, EnergyPlus also runs each IDF and its results
        (eplusout.err / .csv / .sql) land in the building's folder; None stops after the IDF.
    """
    if out_dir is None:
        out_dir = default_out_dir(path, detailed_interior)
    doc = xml_io.CityGMLDoc(path)
    model = build_middle_layer(doc, detailed_interior=detailed_interior)
    buildable = [building for building in model.buildings if building.surfaces]
    target_buildings = [building for building in buildable
                        if building_id is None or building.id == building_id]
    if not target_buildings:
        available_ids = [building.id for building in buildable]
        print(f"No building '{building_id}'. Available: {available_ids}")
        return

    print(f"Building(s): {[building.id for building in target_buildings]}  -> {out_dir}")
    for building in target_buildings:
        idf_path = run_building(building, model, out_dir)
        if weather is not None:
            energyplus.run_idf(idf_path, weather)


def ask_user():
    """Ask, in the terminal, what to run (used when no file was typed).

    Returns
    -------
    (str, bool, str or None)
        The CityGML file to read; detailed_interior (False = fast, True = detailed); the
        weather file (None = stop after the IDF).

    Notes
    -----
    The answers set the same values as the options --detailed-interior and --weather.
    A file name that does not exist is asked again; quotes around a pasted path are removed.
    """
    path = ""
    while not os.path.isfile(path):
        path = input("CityGML file to read (.gml): ").strip().strip('"')
    answer = input("Fast or detailed (heat between zones)? [F/d]: ").strip().lower()
    detailed_interior = False
    if answer == "d":
        detailed_interior = True
    weather = None
    answer = input("Also run EnergyPlus on each IDF? [y/N]: ").strip().lower()
    if answer == "y":
        weather = ""
        while not os.path.isfile(weather):
            weather = input("Weather file (.epw): ").strip().strip('"')
    return path, detailed_interior, weather


def parse_args(argv):
    """Read the command line into (building_id, path, detailed_interior, out_dir, weather).

    Parameters
    ----------
    argv : list of str
        The words typed after `python -m citygml2idf.run`.

    Returns
    -------
    tuple
        building_id (str or None), path (str or None), detailed_interior (bool),
        out_dir (str or None), weather (str or None).

    Notes
    -----
    The building id and the .gml path may come in either order: a word that ends in .gml,
    or names an existing file, is taken as the path.
    """
    parser = argparse.ArgumentParser(
        description="Build one IDF per building from a CityGML/Energy ADE file.")
    parser.add_argument("items", nargs="*",
                        help="Optional BuildingId and/or CityGML path, in either order.")
    parser.add_argument("--building", help="Only this building gml:id (default: every building).")
    parser.add_argument("--detailed-interior", action="store_true",
                        help="Model interior heat transfer (interior faces become Surface pairs). "
                             "Default: fast (interior faces Adiabatic).")
    parser.add_argument("--out-dir",
                        help="Where the building folders go (default: output/<gml name>_<FAST or DETAILED>).")
    parser.add_argument("--weather", "-w",
                        help="Also run EnergyPlus on each IDF with this EPW weather file "
                             "(default: stop after the IDF).")
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
    return building_id, path, args.detailed_interior, args.out_dir, args.weather


if __name__ == "__main__":
    (building_argument, path_argument, detailed_interior_argument,
     out_dir_argument, weather_argument) = parse_args(sys.argv[1:])
    if path_argument is None:                        # no file typed: ask
        path_argument, detailed_interior_argument, weather_argument = ask_user()
    main(building_argument, path_argument, detailed_interior=detailed_interior_argument,
         out_dir=out_dir_argument, weather=weather_argument)
