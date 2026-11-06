"""
tools/energyplus.py — run EnergyPlus on an IDF the converter wrote, and summarise the result.

    python -m citygml2idf.tools.energyplus <file.idf> --weather <file.epw> [--out-dir <dir>]

EnergyPlus is found by tools/config.py (ENERGYPLUS_EXE, else the PATH) and must be the version
the IDF is written for. The results land next to the IDF, or in --out-dir: eplusout.err
(warnings), eplusout.sql (every result) and eplusout.csv (the hourly outputs, written by
EnergyPlus itself: the IDF's OutputControl:Files).
"""

import argparse
import os
import subprocess

from .config import check_energyplus_version, find_energyplus


def _err_summary(err_text):
    """(Severe / Fatal lines, number of warnings) of an eplusout.err text."""
    severe_lines = []
    warning_count = 0
    for line in err_text.splitlines():
        if "** Severe" in line or "** Fatal" in line:
            severe_lines.append(line.strip())
        if "** Warning" in line:
            warning_count += 1
    return severe_lines, warning_count


def run_idf(idf_path, weather, out_dir=None):
    """Run one IDF and print the outcome; True when E+ exits 0 with no Severe / Fatal."""
    idf_path = os.path.abspath(idf_path)
    if not os.path.isfile(idf_path):
        raise SystemExit(f"IDF file not found: {idf_path}")
    weather = os.path.abspath(weather)
    if not os.path.isfile(weather):
        raise SystemExit(f"Weather file not found: {weather}")
    energyplus = find_energyplus()
    check_energyplus_version(energyplus)
    if out_dir:
        out_dir = os.path.abspath(out_dir)
    else:
        out_dir = os.path.dirname(idf_path)
    os.makedirs(out_dir, exist_ok=True)

    command = [energyplus, "--weather", weather, "--output-directory", out_dir, idf_path]
    process = subprocess.run(command, capture_output=True, text=True)
    err_path = os.path.join(out_dir, "eplusout.err")
    err_text = "(no eplusout.err)"
    if os.path.exists(err_path):
        with open(err_path, encoding="utf-8", errors="replace") as err_file:
            err_text = err_file.read()
    severe_lines, warning_count = _err_summary(err_text)

    ok = process.returncode == 0 and not severe_lines
    status = "OK"
    if not ok:
        status = f"FAILED ({len(severe_lines)} Severe/Fatal)"
    print(f"energyplus={energyplus}")
    print(f"idf={idf_path}")
    print(f"weather={weather}")
    print(f"out={out_dir}")
    print(f"exit={process.returncode}  warnings={warning_count}  {status}")
    for line in severe_lines:
        print("   ", line)
    return ok


def main(argv=None):
    """Command line: the IDF, --weather (required), an optional --out-dir; exit 0 when clean."""
    parser = argparse.ArgumentParser(description="Run EnergyPlus on an IDF written by citygml2idf.")
    parser.add_argument("idf", help="the .idf file to simulate")
    parser.add_argument("--weather", "-w", required=True, help="the EPW weather file")
    parser.add_argument("--out-dir", help="where the results go (default: the IDF's folder)")
    args = parser.parse_args(argv)          # None -> argparse reads the command line itself
    if run_idf(args.idf, args.weather, args.out_dir):
        return 0
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
