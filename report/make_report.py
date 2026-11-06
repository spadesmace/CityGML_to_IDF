"""
report/make_report.py — THE ONE COMMAND that builds the report:

    python -m report.make_report

1. runs the pipeline twice on the report sample, with the weather file: fast and detailed,
   into report/runs/FAST/ and report/runs/DETAILED/
2. reads every building's results (results.Run)
3. draws the figures into report/figures/ and builds the tables
4. puts each table into REPORT.md between its markers <!-- table Tn --> and <!-- end Tn -->;
   the text around them and the figure links are never changed
"""

import os

from citygml2idf import run as pipeline
from . import settings
from .figures import Figures
from .results import Run
from .tables import Tables


def run_pipeline():
    """Run the pipeline on the report sample in both modes, with EnergyPlus (into report/runs/)."""
    for mode in ("FAST", "DETAILED"):
        detailed = False
        if mode == "DETAILED":
            detailed = True
        pipeline.main(path=settings.GML, detailed_interior=detailed,
                      out_dir=os.path.join(settings.RUNS_DIR, mode), weather=settings.WEATHER)


def read_runs():
    """Every building's results in both modes: {(mode, building id): Run}."""
    runs = {}
    for mode in ("FAST", "DETAILED"):
        for building in settings.LOD_BUILDINGS + [settings.MULTIZONE_BUILDING]:
            runs[(mode, building)] = Run(mode, building)
    return runs


def fill_table(text, name, table):
    """Put a table into the report text between <!-- table name --> and <!-- end name -->."""
    start_marker = f"<!-- table {name} -->"
    end_marker = f"<!-- end {name} -->"
    if start_marker not in text or end_marker not in text:
        raise SystemExit(f"REPORT.md has no markers {start_marker} ... {end_marker}")
    before = text.split(start_marker)[0]
    after = text.split(end_marker)[1]
    return before + start_marker + "\n" + table + "\n" + end_marker + after


def main():
    """Run the pipeline, draw the figures, fill the tables into REPORT.md."""
    run_pipeline()
    runs = read_runs()
    figures = Figures(runs)
    figures.weather_response()
    figures.lods_week()
    figures.lods_monthly()
    figures.multizone_week()
    tables = Tables(runs)
    with open(settings.REPORT_MD, encoding="utf-8") as report_file:
        text = report_file.read()
    text = fill_table(text, "T1", tables.what_was_read())
    text = fill_table(text, "T2", tables.lod_results())
    text = fill_table(text, "T3", tables.multizone_results())
    with open(settings.REPORT_MD, "w", encoding="utf-8") as report_file:
        report_file.write(text)
    print(f"report written: {settings.REPORT_MD}")


if __name__ == "__main__":
    main()
