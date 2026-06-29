"""
idf_building_visualize.py - standalone 3D preview for middle-layer buildings.

It draws surfaces straight from a middle_layer*.json file. If zones are present,
surfaces are coloured by zone so multizone ownership is visible. Windows are drawn
as blue panels on their host walls, and interzone Surface-pair boundaries get a
strong purple outline.

Usage, from the repo root:
    python -m citygml2idf.idf_building_visualize path/to/middle_layer.json

Saves one PNG per building next to the JSON: <building_id>_preview.png.
"""

from __future__ import annotations

import json
import os
import sys

import matplotlib
import matplotlib.pyplot as plt
import numpy as np
from mpl_toolkits.mplot3d.art3d import Poly3DCollection

matplotlib.use("Agg")  # headless: write a PNG instead of opening a window

_HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_MIDDLE = os.path.join(_HERE, "output", "middle_layer.json")

ROLE_COLORS = {
    "wall": "#9ecae1",
    "roof": "#fc9272",
    "ground": "#a1d99b",
    "party_wall": "#fdd0a2",
    "intermediate_floor": "#dadaeb",
    "attic_floor": "#bcbddc",
    "basement_ceiling": "#9e9ac8",
}

ZONE_COLORS = [
    "#8dd3c7", "#ffffb3", "#bebada", "#fb8072", "#80b1d3",
    "#fdb462", "#b3de69", "#fccde5", "#d9d9d9", "#bc80bd",
]

WINDOW_COLOR = "#2171b5"
INTERZONE_EDGE_COLOR = "#54278f"


def load_middle(path=DEFAULT_MIDDLE):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def _zone_color_map(building):
    zone_names = [zone["name"] for zone in building.get("zones", [])]
    if not zone_names:
        zone_names = sorted({s.get("zone") for s in building.get("surfaces", []) if s.get("zone")})
    return {name: ZONE_COLORS[i % len(ZONE_COLORS)] for i, name in enumerate(zone_names)}


def _surface_color(surface, zone_colors):
    zone = surface.get("zone")
    if zone in zone_colors:
        return zone_colors[zone]
    return ROLE_COLORS.get(surface.get("role"), "#cccccc")


def _add_zone_labels(ax, building):
    by_zone = {}
    for surface in building.get("surfaces", []):
        zone = surface.get("zone")
        if zone:
            by_zone.setdefault(zone, []).extend(surface.get("points", []))

    for zone, points in by_zone.items():
        if not points:
            continue
        centre = np.mean(np.array(points, dtype=float), axis=0)
        ax.text(
            centre[0],
            centre[1],
            centre[2],
            zone,
            fontsize=8,
            weight="bold",
            bbox={"boxstyle": "round,pad=0.2", "fc": "white", "alpha": 0.65, "ec": "none"},
        )


def _draw_windows(ax, surface, pts):
    for window in surface.get("windows", []):
        window_points = np.array(window["points"], dtype=float)
        if len(window_points) >= 3:
            normal = np.cross(window_points[1] - window_points[0], window_points[2] - window_points[0])
            length = np.linalg.norm(normal)
            if length > 0:
                window_points = window_points + (normal / length) * 0.05
        pts.extend(window_points.tolist())
        ax.add_collection3d(
            Poly3DCollection(
                [window_points.tolist()],
                alpha=0.85,
                facecolor=WINDOW_COLOR,
                edgecolor="#08306b",
                linewidths=1.2,
            )
        )


def _set_axes_equal(ax, pts):
    mins = pts.min(axis=0)
    maxs = pts.max(axis=0)
    spans = np.maximum(maxs - mins, 1e-6)
    centres = (mins + maxs) / 2.0
    radius = spans.max() / 2.0
    ax.set_xlim(centres[0] - radius, centres[0] + radius)
    ax.set_ylim(centres[1] - radius, centres[1] + radius)
    ax.set_zlim(centres[2] - radius, centres[2] + radius)
    ax.set_box_aspect((1, 1, 1))


def _add_legend(ax, zone_colors):
    if not zone_colors:
        return
    handles = [
        plt.Line2D(
            [0],
            [0],
            marker="s",
            color="w",
            markerfacecolor=color,
            markeredgecolor="black",
            markersize=9,
            label=name,
        )
        for name, color in zone_colors.items()
    ]
    handles.append(
        plt.Line2D(
            [0], [0], marker="s", color="w", markerfacecolor=WINDOW_COLOR,
            markeredgecolor="#08306b", markersize=9, label="window"
        )
    )
    handles.append(
        plt.Line2D([0], [0], color=INTERZONE_EDGE_COLOR, linewidth=2, label="interzone pair")
    )
    ax.legend(handles=handles, loc="upper left", bbox_to_anchor=(0.0, 1.0), fontsize=7)


def preview_building(building, out_dir):
    fig = plt.figure(figsize=(8, 7))
    ax = fig.add_subplot(111, projection="3d")

    pts = []
    zone_colors = _zone_color_map(building)
    surfaces = building.get("surfaces", [])

    for surface in surfaces:
        verts = surface["points"]
        pts.extend(verts)
        edge_color = INTERZONE_EDGE_COLOR if surface.get("boundary") == "Surface" else "black"
        line_width = 1.8 if surface.get("boundary") == "Surface" else 0.8
        ax.add_collection3d(
            Poly3DCollection(
                [verts],
                alpha=0.55,
                facecolor=_surface_color(surface, zone_colors),
                edgecolor=edge_color,
                linewidths=line_width,
            )
        )

        if len(surfaces) <= 12:
            centre = np.mean(np.array(verts, dtype=float), axis=0)
            ax.text(centre[0], centre[1], centre[2], surface["source_id"], fontsize=6)

        _draw_windows(ax, surface, pts)

    if not pts:
        plt.close(fig)
        return None

    pts_array = np.array(pts, dtype=float)
    _set_axes_equal(ax, pts_array)
    ax.set_xlabel("X (m, east)")
    ax.set_ylabel("Y (m, north)")
    ax.set_zlabel("Z (m, up)")
    ax.set_title(f"{building['id']} - zones/windows from middle_layer.json")
    ax.view_init(elev=20, azim=-60)
    _add_zone_labels(ax, building)
    _add_legend(ax, zone_colors)

    out_path = os.path.join(out_dir, f"{building['id']}_preview.png")
    plt.savefig(out_path, dpi=120, bbox_inches="tight")
    plt.close(fig)
    return out_path


def main(middle_path=None):
    path = middle_path or DEFAULT_MIDDLE
    middle = load_middle(path)
    out_dir = os.path.dirname(os.path.abspath(path))
    for building in middle["buildings"]:
        out = preview_building(building, out_dir)
        print(f"saved {out}" if out else f"{building['id']}: no surfaces to draw")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else None)
