"""
report/figures.py — the report's figures, saved as PNG files in report/figures/.

One method per figure; each draws one figure from the runs and returns its file path. Every
word comes from settings.LABELS, every colour from settings.COLORS, every size from settings.
"""

import datetime
import os

import matplotlib
matplotlib.use("Agg")                         # draw into files only, never open a window
import matplotlib.pyplot as plt

from . import settings
from .results import week_starts


class Figures:
    """The report's figures (F1 ... F4), drawn from the runs."""

    def __init__(self, runs):
        """runs: {(mode, building id): Run}, for both modes and every building."""
        self.runs = runs
        os.makedirs(settings.FIGURES_DIR, exist_ok=True)
        outdoor = runs[("FAST", settings.WEATHER_BUILDING)].hourly(None, settings.OUTDOOR)
        self.hottest, self.coldest = week_starts(outdoor)

    def _style(self, axis):
        """The quiet look of every panel: light background, solid hairline grid, no box."""
        colors = settings.COLORS
        axis.set_facecolor(colors["surface"])
        axis.grid(True, color=colors["grid"], linewidth=0.6)
        axis.set_axisbelow(True)
        axis.spines["top"].set_visible(False)
        axis.spines["right"].set_visible(False)
        axis.spines["left"].set_color(colors["axis"])
        axis.spines["bottom"].set_color(colors["axis"])
        axis.tick_params(colors=colors["text_secondary"], labelsize=9)
        axis.yaxis.label.set_color(colors["text_secondary"])
        axis.xaxis.label.set_color(colors["text_secondary"])

    def _week_days(self, axis, start):
        """One tick per day under a week that starts at hour `start`, labelled like '31 Jul'.

        The weather file is one typical 365-day year, so only the day and the month are shown.
        """
        first_day = datetime.date(2021, 1, 1)     # any 365-day year: only day and month are shown
        ticks = []
        names = []
        for day in range(8):
            ticks.append(day * 24)
            date = first_day + datetime.timedelta(days=start // 24 + day)
            names.append(date.strftime("%d %b"))
        axis.set_xticks(ticks)
        axis.set_xticklabels(names)
        axis.set_xlim(0, settings.WEEK_HOURS)

    def _legend_below(self, figure, axes):
        """One legend under the whole figure, every name once, so it never covers the data."""
        lines = []
        names = []
        for axis in axes:
            axis_lines, axis_names = axis.get_legend_handles_labels()
            for line, name in zip(axis_lines, axis_names):
                if name not in names:
                    lines.append(line)
                    names.append(name)
        figure.legend(lines, names, frameon=False, fontsize=9,
                      labelcolor=settings.COLORS["text_secondary"],
                      loc="upper center", bbox_to_anchor=(0.5, 0.0), ncol=2)

    def _save(self, figure, name):
        """Save a figure as report/figures/<name>.png and return its path."""
        path = os.path.join(settings.FIGURES_DIR, f"{name}.png")
        figure.savefig(path, dpi=settings.DPI, facecolor=settings.COLORS["surface"],
                       bbox_inches="tight")
        plt.close(figure)
        return path

    def weather_response(self):
        """F1: how a free-floating house follows the weather (the LoD2 house), in the coldest and
        the hottest week: temperatures on top, sun through the windows below."""
        labels = settings.LABELS
        colors = settings.COLORS
        building = settings.WEATHER_BUILDING
        run = self.runs[("FAST", building)]
        zone = run.zone_names()[0]
        figure, axes = plt.subplots(2, 2, figsize=settings.FIGURE_SIZE_TALL, sharey="row",
                                    gridspec_kw={"height_ratios": [2, 1]})
        figure.patch.set_facecolor(colors["surface"])
        weeks = [(self.coldest, labels["coldest_week"]), (self.hottest, labels["hottest_week"])]
        for column in range(2):
            start, week_title = weeks[column]
            end = start + settings.WEEK_HOURS
            top = axes[0][column]
            bottom = axes[1][column]
            top.plot(run.hourly(None, settings.OUTDOOR)[start:end], color=colors["outdoor"],
                     linewidth=settings.LINE_WIDTH, label=labels["outdoor"])
            top.plot(run.hourly(zone, settings.INDOOR)[start:end], color=colors[building],
                     linewidth=settings.LINE_WIDTH, label=labels["indoor"])
            sun = run.hourly(zone, settings.SUN)[start:end]
            bottom.plot(sun, color=colors["sun"], linewidth=settings.LINE_WIDTH)
            week_kwh = sum(sun) / 1000                 # hourly W added up = Wh; / 1000 = kWh
            bottom.text(0.01, 0.95, labels["sun_week_total"].format(kwh=week_kwh),
                        transform=bottom.transAxes, ha="left", va="top", fontsize=9,
                        color=colors["text_secondary"])
            top.set_title(week_title, color=colors["text"], fontsize=10, loc="left")
            for axis in (top, bottom):
                self._style(axis)
                self._week_days(axis, start)
            top.set_xticklabels([])
            bottom.set_xlabel(labels["day_axis"])
        axes[0][0].set_ylabel(labels["temperature_axis"])
        axes[1][0].set_ylabel(labels["sun_axis"])
        self._legend_below(figure, [axes[0][0]])
        figure.suptitle(labels["F1"], color=colors["text"], fontsize=12, x=0.01, ha="left")
        return self._save(figure, "F1")

    def lods_week(self):
        """F2: the same house in LoD1, LoD2 and LoD3 in the hottest week: one panel per building,
        each with its indoor temperature and the outdoor air, on the same scales."""
        labels = settings.LABELS
        colors = settings.COLORS
        start = self.hottest
        end = start + settings.WEEK_HOURS
        figure, axes = plt.subplots(3, 1, figsize=settings.FIGURE_SIZE_THREE_ROWS,
                                    sharex=True, sharey=True)
        figure.patch.set_facecolor(colors["surface"])
        for row in range(3):
            building = settings.LOD_BUILDINGS[row]
            run = self.runs[("FAST", building)]
            axis = axes[row]
            axis.plot(run.hourly(None, settings.OUTDOOR)[start:end], color=colors["outdoor"],
                      linewidth=settings.LINE_WIDTH, label=labels["outdoor"])
            axis.plot(run.hourly(run.zone_names()[0], settings.INDOOR)[start:end],
                      color=colors[building], linewidth=settings.LINE_WIDTH, label=labels[building])
            axis.set_title(labels[building], color=colors["text"], fontsize=10, loc="left")
            self._style(axis)
            self._week_days(axis, start)
        axes[1].set_ylabel(labels["temperature_axis"])
        axes[2].set_xlabel(labels["day_axis"])
        self._legend_below(figure, axes)
        figure.suptitle(labels["F2"], color=colors["text"], fontsize=12, x=0.01, ha="left")
        return self._save(figure, "F2")

    def lods_monthly(self):
        """F3: the same house in LoD1, LoD2 and LoD3, month by month, one row per building.
        Left: its monthly mean indoor temperature and the monthly mean outdoor air. Right: the
        sun through its windows in each month (kWh), with the year's total above. Each column
        has one scale."""
        labels = settings.LABELS
        colors = settings.COLORS
        months = list(range(1, 13))
        figure, axes = plt.subplots(3, 2, figsize=settings.FIGURE_SIZE_THREE_ROWS,
                                    sharex=True, sharey="col")
        figure.patch.set_facecolor(colors["surface"])
        for row in range(3):
            building = settings.LOD_BUILDINGS[row]
            run = self.runs[("FAST", building)]
            zone = run.zone_names()[0]
            left = axes[row][0]
            right = axes[row][1]
            left.plot(months, run.monthly_means(None, settings.OUTDOOR), color=colors["outdoor"],
                      linewidth=settings.LINE_WIDTH, marker="o", markersize=settings.MARKER_SIZE,
                      label=labels["outdoor"])
            left.plot(months, run.monthly_means(zone, settings.INDOOR),
                      color=colors[building], linewidth=settings.LINE_WIDTH, marker="o",
                      markersize=settings.MARKER_SIZE, label=labels[building])
            left.set_title(labels[building], color=colors["text"], fontsize=10, loc="left")
            sun = run.monthly_totals(zone, settings.SUN)
            right.bar(months, sun, width=0.7, color=colors["sun"])
            right.set_title(labels["sun_year_total"].format(kwh=sum(sun)), color=colors["text"],
                            fontsize=10, loc="left")
            self._style(left)
            self._style(right)
        for column in range(2):
            axes[2][column].set_xticks(months)
            axes[2][column].set_xticklabels(labels["month_names"])
            axes[2][column].set_xlabel(labels["month_axis"])
        axes[1][0].set_ylabel(labels["temperature_axis"])
        axes[1][1].set_ylabel(labels["sun_month_axis"])
        self._legend_below(figure, [axes[0][0], axes[1][0], axes[2][0]])
        figure.suptitle(labels["F3"], color=colors["text"], fontsize=12, x=0.01, ha="left")
        return self._save(figure, "F3")

    def multizone_week(self):
        """F4: the two-zone building in the hottest week, fast against detailed: one panel per
        run, each with both floors' indoor temperature and the outdoor air, on the same scales."""
        labels = settings.LABELS
        colors = settings.COLORS
        start = self.hottest
        end = start + settings.WEEK_HOURS
        building = settings.MULTIZONE_BUILDING
        modes = ["FAST", "DETAILED"]
        figure, axes = plt.subplots(2, 1, figsize=settings.FIGURE_SIZE_TALL,
                                    sharex=True, sharey=True)
        figure.patch.set_facecolor(colors["surface"])
        for row in range(2):
            mode = modes[row]
            run = self.runs[(mode, building)]
            axis = axes[row]
            axis.plot(run.hourly(None, settings.OUTDOOR)[start:end], color=colors["outdoor"],
                      linewidth=settings.LINE_WIDTH, label=labels["outdoor"])
            for zone in settings.MULTIZONE_ZONES:
                axis.plot(run.hourly(zone, settings.INDOOR)[start:end], color=colors[zone],
                          linewidth=settings.LINE_WIDTH, label=labels[zone])
            axis.set_title(labels[mode], color=colors["text"], fontsize=10, loc="left")
            axis.set_ylabel(labels["temperature_axis"])
            self._style(axis)
            self._week_days(axis, start)
        axes[1].set_xlabel(labels["day_axis"])
        self._legend_below(figure, axes)
        figure.suptitle(labels["F4"], color=colors["text"], fontsize=12, x=0.01, ha="left")
        return self._save(figure, "F4")
