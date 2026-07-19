"""
run_energyplus.py - run EnergyPlus for an already-created IDF.

Use this after `python -m citygml2idf.run ...` has created the IDF, or use
EP-Launch manually with the same IDF and weather file.

Run:
    python -m citygml2idf.run_energyplus output/runs/id_building_2/id_building_2.idf --weather path/to/weather.epw
    like : python -m citygml2idf.run_energyplus citygml2idf/output/runs/Case31_LoD2_2zone_fast/Case31_LoD2_2zone.idf --weather citygml2idf/input/weather.epw

"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_TEMPLATES = os.path.join(_HERE, "templates")
DEFAULT_EPLUS_EXE = os.path.join(
    _TEMPLATES,
    "EnergyPlus-23.1.0-87ed9199d4-Windows-x86_64",
    "energyplus.exe",
)


def _error_summary(error_text):
    severe_lines = [line for line in error_text.splitlines()
                    if "** Severe" in line or "** Fatal" in line]
    warning_count = sum(1 for line in error_text.splitlines() if "** Warning" in line)
    return severe_lines, warning_count


def _run_energyplus(idf_path, weather, out_dir, energyplus_exe=DEFAULT_EPLUS_EXE):
    cmd = [energyplus_exe, "--weather", weather, "--output-directory", out_dir, idf_path]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    err_file = os.path.join(out_dir, "eplusout.err")
    error_text = open(err_file, encoding="utf-8").read() if os.path.exists(err_file) else "(no .err)"
    return proc.returncode, error_text


def run_idf(idf_path, weather, out_dir=None, energyplus_exe=DEFAULT_EPLUS_EXE):
    idf_path = os.path.abspath(idf_path)
    if not os.path.isfile(idf_path):
        raise SystemExit(f"IDF file not found: {idf_path}")

    weather = os.path.abspath(weather)
    if not os.path.isfile(weather):
        raise SystemExit(f"Weather file not found: {weather}")

    energyplus_exe = os.path.abspath(energyplus_exe)
    if not os.path.isfile(energyplus_exe):
        raise SystemExit(f"EnergyPlus executable not found: {energyplus_exe}")

    out_dir = os.path.abspath(out_dir) if out_dir else os.path.dirname(idf_path)
    os.makedirs(out_dir, exist_ok=True)
    return_code, error_text = _run_energyplus(idf_path, weather, out_dir, energyplus_exe)
    severe_lines, warning_count = _error_summary(error_text)

    status = "OK" if return_code == 0 and not severe_lines else f"{len(severe_lines)} SEVERE/FATAL"
    print(f"idf={idf_path}")
    print(f"weather={weather}")
    print(f"out={out_dir}")
    print(f"exit={return_code}  warnings={warning_count}  {status}")
    for line in severe_lines[:8]:
        print("   ", line.strip())
    return return_code == 0 and not severe_lines


def parse_args(argv):
    parser = argparse.ArgumentParser(
        description="Run EnergyPlus for an already-created IDF.")
    parser.add_argument("idf", help="Path to the .idf file to simulate.")
    parser.add_argument("--weather", "-w", required=True,
                        help="EPW weather file for the free-floating weather run.")
    parser.add_argument("--energyplus", default=DEFAULT_EPLUS_EXE,
                        help="Path to energyplus.exe. Defaults to the bundled EnergyPlus 23.1 executable.")
    parser.add_argument("--out-dir", help="Output directory. Defaults to the IDF folder.")
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(sys.argv[1:] if argv is None else argv)
    ok = run_idf(args.idf, weather=args.weather, out_dir=args.out_dir,
                 energyplus_exe=args.energyplus)
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
