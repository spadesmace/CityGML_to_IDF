"""
report/settings.py — every choice of the report in ONE place.

What the report runs, which buildings it compares, the comfort limits, every word the reader
sees (LABELS), every colour (COLORS) and the figure sizes. Change a word or a colour here and it
changes in every figure and table: nothing else in report/ holds a label or a colour.
"""

import os

# ---- where things are ---------------------------------------------------------------------
REPORT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_DIR = os.path.dirname(REPORT_DIR)
GML = os.path.join(REPO_DIR, "citygml2idf", "input", "cases", "report_4buildings_synth.gml")
WEATHER = os.path.join(REPO_DIR, "citygml2idf", "input",
                       "ITA_PM_Torino.AF.160595_TMYx.2011-2025.epw")
RUNS_DIR = os.path.join(REPORT_DIR, "runs")          # runs/FAST/<building>/, runs/DETAILED/<building>/
FIGURES_DIR = os.path.join(REPORT_DIR, "figures")
REPORT_MD = os.path.join(REPORT_DIR, "REPORT.md")

# ---- what is compared ---------------------------------------------------------------------
LOD_BUILDINGS = ["B1_LoD1_1zone", "B2_LoD2_1zone", "B3_LoD3_1zone"]   # one house, three LoDs
WEATHER_BUILDING = "B2_LoD2_1zone"                                     # F1
MULTIZONE_BUILDING = "B4_LoD2_2zone"                                   # F4, T3
MULTIZONE_ZONES = ["B4_ZONE_LOWER", "B4_ZONE_UPPER"]

# ---- limits -------------------------------------------------------------------------------
TOO_HOT = 26.0       # °C: an hour above this counts as "too hot"
TOO_COLD = 18.0      # °C: an hour below this counts as "too cold"
WEEK_HOURS = 7 * 24

# ---- the EnergyPlus results read from eplusout.csv (a column is "<KEY>:<variable>") -------
OUTDOOR = "Environment:Site Outdoor Air Drybulb Temperature [C](Hourly)"
INDOOR = "Zone Operative Temperature [C](Hourly)"   # what a person feels: 0.5 × air + 0.5 × mean radiant (E+ I/O Reference)
SUN = "Enclosure Windows Total Transmitted Solar Radiation Rate [W](Hourly)"

# ---- every word the reader sees -----------------------------------------------------------
LABELS = {
    # buildings, zones, slab faces, runs
    "B1_LoD1_1zone": "LoD1 (no windows: LoD1 allows none)",
    "B2_LoD2_1zone": "LoD2 (windows from the opening ratio)",
    "B3_LoD3_1zone": "LoD3 (windows from Window objects)",
    "B4_LoD2_2zone": "LoD2, two stacked zones",
    "B4_ZONE_LOWER": "lower floor (on the ground)",
    "B4_ZONE_UPPER": "upper floor (under the roof)",
    "FAST": "fast (no heat between zones)",
    "DETAILED": "detailed (heat through the slab)",
    # lines
    "outdoor": "outdoor air",
    "indoor": "indoor (operative)",
    # axes
    "temperature_axis": "Temperature [°C]",
    "sun_axis": "Sun through the windows [W]",
    "day_axis": "Day",
    "month_axis": "Month",
    "month_names": ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
    # figure titles
    "F1": "A free-floating house follows the weather (LoD2 house)",
    "F2": "One house in LoD1, LoD2 and LoD3: the hottest week",
    "F3": "One house in LoD1, LoD2 and LoD3, month by month: temperature and sun through the windows",
    "F4": "Two stacked zones, fast against detailed: the hottest week",
    "coldest_week": "Coldest week",
    "hottest_week": "Hottest week",
    # table columns
    "col_building": "Building",
    "col_lod": "LoD",
    "col_zones": "Zones",
    "col_surfaces": "Surfaces",
    "col_windows": "Windows",
    "col_window_area": "Window area [m²]",
    "col_window_u": "Window U [W/m²K]",
    "col_window_g": "Window g [-]",
    "col_glazing_from": "U and g came from",
    "col_wall_construction": "Wall construction",
    "col_floor_area": "Floor area [m²]",
    "col_run": "Run",
    "col_floor": "Floor",
    "col_mean": "Yearly mean [°C]",
    "col_min": "Coldest hour [°C]",
    "col_max": "Hottest hour [°C]",
    "col_hours_hot": f"Hours above {TOO_HOT:g} °C",
    "col_hours_cold": f"Hours below {TOO_COLD:g} °C",
    # values and sentences in the figures and tables ({...} is filled in by the script)
    "sun_week_total": "{kwh:.0f} kWh this week",
    "sun_month_axis": "Sun through the windows [kWh per month]",
    "sun_year_total": "{kwh:.0f} kWh this year",
    "glazing_file": "the GML file",
    "glazing_default": "the converter's default",
    "lod_check": "Largest hourly difference between LoD2 and LoD3: {difference:.4f} K over {hours} hours.",
    "gap_note": "Mean gap between the two floors over the year: {fast:.2f} K in the fast run, "
                "{detailed:.2f} K in the detailed run.",
    "single_zone_note": "The three single-zone buildings give the same result in both runs: "
                        "largest hourly difference {difference:.4f} K.",
}

# ---- every colour: the tested colour-blind-safe palette, used in its fixed order ----------
COLORS = {
    "B1_LoD1_1zone": "#2a78d6",     # slot 1, blue
    "B2_LoD2_1zone": "#eb6834",     # slot 2, orange
    "B3_LoD3_1zone": "#1baf7a",     # slot 3, aqua
    "sun": "#eda100",               # slot 4, yellow
    "B4_ZONE_LOWER": "#e87ba4",     # slot 5, magenta
    "B4_ZONE_UPPER": "#008300",     # slot 6, green
    "outdoor": "#898781",           # muted grey: the reference line, not a series
    "text": "#0b0b0b",              # titles
    "text_secondary": "#52514e",    # axis labels, ticks, legend
    "grid": "#e1e0d9",              # hairline grid
    "axis": "#c3c2b7",              # axis lines
    "surface": "#fcfcfb",           # figure background
}

# ---- sizes --------------------------------------------------------------------------------
LINE_WIDTH = 1.5                    # points
MARKER_SIZE = 4                     # points: about 8 pixels at DPI 150, the smallest readable dot
FIGURE_SIZE = (10, 4.5)             # inches
FIGURE_SIZE_TALL = (10, 6.5)        # figures with two rows of panels
FIGURE_SIZE_THREE_ROWS = (10, 8.5)  # figures with three rows of panels
DPI = 150
