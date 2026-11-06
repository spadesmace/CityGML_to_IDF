"""
report/tables.py — the report's tables, as Markdown text.

One method per table; each returns the text that make_report.py puts between that table's
markers in REPORT.md. Every column title and every sentence comes from settings.LABELS; every
value comes from a Run (results.py).
"""

from . import settings


def _markdown(header, rows):
    """A Markdown table: one line of column titles, one separator line, one line per row."""
    lines = ["| " + " | ".join(header) + " |"]
    lines.append("|" + "---|" * len(header))
    for row in rows:
        lines.append("| " + " | ".join(row) + " |")
    return "\n".join(lines)


def _number(value, decimals):
    """The value as text with this many decimals; a dash when there is no value."""
    if value is None:
        return "-"
    return f"{value:.{decimals}f}"


def _largest_difference(first, second):
    """The largest hourly difference between two lists of hourly values."""
    largest = 0.0
    for a, b in zip(first, second):
        largest = max(largest, abs(a - b))
    return largest


class Tables:
    """The three tables of the report (T1, T2, T3), built from the runs."""

    def __init__(self, runs):
        """runs: {(mode, building id): Run}, for both modes and every building."""
        self.runs = runs

    def _indoor(self, mode, building, zone=None):
        """The 8760 hourly indoor (operative) temperatures of one zone (the building's only zone by default)."""
        run = self.runs[(mode, building)]
        if zone is None:
            zone = run.zone_names()[0]
        return run.hourly(zone, settings.INDOOR)

    def _year(self, values):
        """The yearly mean, the coldest hour, the hottest hour, the hours too hot and the hours too
        cold of a year of hourly temperatures, as text."""
        hot = 0
        cold = 0
        for value in values:
            if value > settings.TOO_HOT:
                hot += 1
            if value < settings.TOO_COLD:
                cold += 1
        return [_number(sum(values) / len(values), 1), _number(min(values), 1),
                _number(max(values), 1), str(hot), str(cold)]

    def what_was_read(self):
        """T1: per building, what the converter read from the GML (the FAST run's JSON)."""
        labels = settings.LABELS
        header = [labels["col_building"], labels["col_lod"], labels["col_zones"],
                  labels["col_surfaces"], labels["col_windows"], labels["col_window_area"],
                  labels["col_window_u"], labels["col_window_g"], labels["col_glazing_from"],
                  labels["col_wall_construction"], labels["col_floor_area"]]
        rows = []
        for building in settings.LOD_BUILDINGS + [settings.MULTIZONE_BUILDING]:
            facts = self.runs[("FAST", building)].facts()
            glazing_from = "-"
            if facts["glazing_from"] is not None:
                glazing_from = labels["glazing_" + facts["glazing_from"]]
            rows.append([building, str(facts["lod"]), str(facts["zones"]),
                         str(facts["surfaces"]), str(facts["windows"]),
                         _number(facts["window_area"], 1), _number(facts["window_u"], 1),
                         _number(facts["window_g"], 2), glazing_from,
                         facts["wall_construction"], _number(facts["floor_area"], 0)])
        return _markdown(header, rows)

    def lod_results(self):
        """T2: the same house in LoD1, LoD2 and LoD3 over the year (FAST run, indoor operative
        temperature), and
        the largest hourly difference between LoD2 and LoD3."""
        labels = settings.LABELS
        header = [labels["col_building"], labels["col_mean"], labels["col_min"],
                  labels["col_max"], labels["col_hours_hot"], labels["col_hours_cold"]]
        rows = []
        for building in settings.LOD_BUILDINGS:
            rows.append([building] + self._year(self._indoor("FAST", building)))
        lod2 = self._indoor("FAST", settings.LOD_BUILDINGS[1])
        lod3 = self._indoor("FAST", settings.LOD_BUILDINGS[2])
        note = labels["lod_check"].format(difference=_largest_difference(lod2, lod3),
                                          hours=len(lod2))
        return _markdown(header, rows) + "\n\n" + note

    def multizone_results(self):
        """T3: the two-zone building, fast against detailed (indoor operative temperature per
        floor); the mean gap
        between the floors; and the check that the single-zone buildings do not change."""
        labels = settings.LABELS
        header = [labels["col_run"], labels["col_floor"], labels["col_mean"], labels["col_min"],
                  labels["col_max"], labels["col_hours_hot"], labels["col_hours_cold"]]
        lower_zone = settings.MULTIZONE_ZONES[0]
        upper_zone = settings.MULTIZONE_ZONES[1]
        rows = []
        gaps = {}
        for mode in ("FAST", "DETAILED"):
            lower = self._indoor(mode, settings.MULTIZONE_BUILDING, lower_zone)
            upper = self._indoor(mode, settings.MULTIZONE_BUILDING, upper_zone)
            rows.append([labels[mode], labels[lower_zone]] + self._year(lower))
            rows.append([labels[mode], labels[upper_zone]] + self._year(upper))
            total = 0.0
            for low, up in zip(lower, upper):
                total += abs(up - low)
            gaps[mode] = total / len(lower)
        single_zone = 0.0
        for building in settings.LOD_BUILDINGS:
            difference = _largest_difference(self._indoor("FAST", building),
                                             self._indoor("DETAILED", building))
            single_zone = max(single_zone, difference)
        notes = [labels["gap_note"].format(fast=gaps["FAST"], detailed=gaps["DETAILED"]),
                 labels["single_zone_note"].format(difference=single_zone)]
        return _markdown(header, rows) + "\n\n" + "\n\n".join(notes)
