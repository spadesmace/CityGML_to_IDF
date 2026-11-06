"""
report/results.py — the results of ONE building in ONE run, read from its folder.

The folder is the one the pipeline writes, <runs>/<FAST or DETAILED>/<building id>/. Two files
are read: what went IN is middle_layer_<building id>.json (what the converter read from the
GML), what came OUT is eplusout.csv (what EnergyPlus computed, hour by hour).
"""

import csv
import json
import os

from . import settings


class Run:
    """One building in one run (FAST or DETAILED): its hourly results and its facts."""

    def __init__(self, mode, building):
        self.mode = mode
        self.building = building
        self.folder = os.path.join(settings.RUNS_DIR, mode, building)
        self.months, self.columns = self._read_csv()
        self.model = self._read_json()

    def _read_csv(self):
        """The month of every hour, and every column of eplusout.csv as {name: hourly values}."""
        with open(os.path.join(self.folder, "eplusout.csv"), newline="") as csv_file:
            rows = list(csv.reader(csv_file))
        names = [name.strip() for name in rows[0]]
        months = []
        for row in rows[1:]:
            months.append(int(row[0].strip()[:2]))            # " 01/31  24:00:00" -> 1
        columns = {}
        for index in range(1, len(names)):                    # column 0 is the date and time
            values = []
            for row in rows[1:]:
                values.append(float(row[index]))
            columns[names[index]] = values
        return months, columns

    def _read_json(self):
        """The middle layer the converter wrote for this building (what it read from the GML)."""
        path = os.path.join(self.folder, f"middle_layer_{self.building}.json")
        with open(path, encoding="utf-8") as json_file:
            return json.load(json_file)

    def hourly(self, key, variable):
        """The 8760 hourly values of one result.

        Parameters
        ----------
        key : str or None
            The zone or surface name as EnergyPlus writes it (upper case), e.g. "B2_ZONE";
            None for a value of the whole site (the outdoor temperature).
        variable : str
            The variable, e.g. settings.INDOOR.

        Returns
        -------
        list of float
            One value per hour of the year.
        """
        if key is None:
            return self.columns[variable]
        return self.columns[f"{key}:{variable}"]

    def monthly_means(self, key, variable):
        """The 12 monthly means of one result, January first.

        Parameters
        ----------
        key : str or None
            As in hourly(): the zone or surface name, or None for the outdoor temperature.
        variable : str
            The variable, e.g. settings.INDOOR.

        Returns
        -------
        list of float
            One mean per month.
        """
        values = self.hourly(key, variable)
        means = []
        for month in range(1, 13):
            total = 0.0
            count = 0
            for hour in range(len(values)):
                if self.months[hour] == month:
                    total += values[hour]
                    count += 1
            means.append(total / count)
        return means

    def monthly_totals(self, key, variable):
        """The 12 monthly totals of one hourly rate in watts, in kWh, January first.

        Parameters
        ----------
        key : str or None
            As in hourly(): the zone or surface name, or None for a value of the whole site.
        variable : str
            A rate in W, e.g. settings.SUN.

        Returns
        -------
        list of float
            One total per month: the month's hourly values added up (W for one hour = Wh),
            divided by 1000 (kWh).
        """
        values = self.hourly(key, variable)
        totals = []
        for month in range(1, 13):
            total = 0.0
            for hour in range(len(values)):
                if self.months[hour] == month:
                    total += values[hour]
            totals.append(total / 1000)
        return totals

    def zone_names(self):
        """The building's zone names as EnergyPlus writes them (upper case)."""
        names = []
        for zone in self.model["buildings"][0]["zones"]:
            names.append(zone["name"].upper())
        return names

    def facts(self):
        """What the converter read for this building (from its JSON).

        Returns
        -------
        dict
            lod, zones, surfaces, windows, window_area [m2]; window_u, window_g and
            glazing_from ("file" or "default"; all three None without windows);
            wall_construction (the walls' construction); floor_area [m2] (all floors together).

        Notes
        -----
        The glazing is the first window's and the wall construction the first wall's: in the
        report sample all windows of a building share one glazing and all walls one
        construction. "file" means the JSON notes the window U as read from the file
        (status "ok").
        """
        building = self.model["buildings"][0]
        windows = []
        wall_construction = None
        floor_area = 0.0
        for surface in building["surfaces"]:
            for window in surface["windows"]:
                windows.append(window)
            if surface["surface_type"] == "Wall" and wall_construction is None:
                wall_construction = surface["construction"]
            if surface["surface_type"] == "Floor":
                floor_area += surface["area"]
        window_area = 0.0
        for window in windows:
            window_area += window["area"]
        window_u = None
        window_g = None
        glazing_from = None
        if windows:
            glazing = self.model["window_constructions"][windows[0]["construction"]]
            window_u = glazing["u_factor"]
            window_g = glazing["shgc"]
            glazing_from = "default"
            u_note = glazing["provenance"].get("u_factor")
            if u_note is not None and u_note["status"] == "ok":
                glazing_from = "file"
        return {"lod": building["lod"], "zones": len(building["zones"]),
                "surfaces": len(building["surfaces"]), "windows": len(windows),
                "window_area": window_area, "window_u": window_u, "window_g": window_g,
                "glazing_from": glazing_from, "wall_construction": wall_construction,
                "floor_area": floor_area}


def week_starts(outdoor):
    """The first hour of the hottest and of the coldest week of the year.

    Parameters
    ----------
    outdoor : list of float
        The 8760 hourly outdoor temperatures.

    Returns
    -------
    (int, int)
        The first hour of the hottest week and of the coldest week (each week starts at
        midnight and is the one with the highest / lowest mean outdoor temperature).
    """
    starts = list(range(0, len(outdoor) - settings.WEEK_HOURS + 1, 24))
    means = []
    for start in starts:
        week = outdoor[start:start + settings.WEEK_HOURS]
        means.append(sum(week) / len(week))
    hottest = starts[means.index(max(means))]
    coldest = starts[means.index(min(means))]
    return hottest, coldest
