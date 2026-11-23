"""Render analytical plots and choropleths from already aggregated Gold rows."""

from io import BytesIO
import json

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.collections import PatchCollection
from matplotlib.colors import BoundaryNorm, ListedColormap, TwoSlopeNorm
from matplotlib.patches import PathPatch, Patch
from matplotlib.path import Path
from matplotlib.ticker import FuncFormatter, PercentFormatter
import numpy as np


BLUE = "#126880"
ORANGE = "#bf5a26"
INK = "#183143"
MISSING = "#d9dee3"


def _png(figure):
    buffer = BytesIO()
    figure.savefig(buffer, format="png", dpi=155, facecolor="white", bbox_inches="tight")
    plt.close(figure)
    return buffer.getvalue()


def _style(axis):
    axis.spines[["top", "right"]].set_visible(False)
    axis.grid(axis="y", color="#e3ebef", linewidth=0.7)
    axis.set_axisbelow(True)


def hourly_profile(rows):
    figure, axes = plt.subplots(1, 2, figsize=(10.4, 3.9), sharey=True, layout="constrained")
    for axis, basis, names, title in zip(
        axes, ("calendar", "cluster"), (("weekday", "weekend"), ("cluster_2", "cluster_1")),
        ("Calendar days", "K-means groups"), strict=True,
    ):
        for pattern, color in zip(names, (BLUE, ORANGE), strict=True):
            series = [(hour, trips / 1_000_000) for b, name, hour, trips in rows if b == basis and name == pattern]
            if series:
                hours, trips = zip(*series)
                axis.plot(hours, trips, label=pattern.replace("_", " ").capitalize(), color=color, linewidth=2.2)
        _style(axis)
        axis.set(title=title, xlabel="Hour of day", xlim=(0, 23), ylim=(0, None), xticks=range(0, 24, 3))
        axis.legend(frameon=False, loc="upper left")
    axes[0].set_ylabel("Average published trips (millions)")
    return _png(figure)


def gravity_coverage(rows):
    figure, axis = plt.subplots(figsize=(8.0, 3.8), layout="constrained")
    coverage, ratio = zip(*rows)
    colors = np.where(np.array(ratio) < 1, ORANGE, BLUE)
    axis.scatter(coverage, ratio, s=11, alpha=0.50, c=colors, linewidths=0)
    axis.axhline(1, color=INK, linewidth=0.9, linestyle="--", label="Observed = estimated")
    _style(axis)
    axis.set(
        xlabel="Share of eligible destinations with a published flow",
        ylabel="Observed / estimated trips",
        yscale="symlog", xlim=(0, 1), ylim=(0, None),
    )
    axis.xaxis.set_major_formatter(PercentFormatter(1))
    axis.yaxis.set_major_formatter(FuncFormatter(_multiple))
    axis.legend(frameon=False, loc="upper right")
    return _png(figure)


def _patches(geometry):
    kind = geometry["type"]
    if kind == "GeometryCollection":
        for part in geometry["geometries"]:
            yield from _patches(part)
        return
    if kind not in ("Polygon", "MultiPolygon"):
        return
    polygons = [geometry["coordinates"]] if kind == "Polygon" else geometry["coordinates"]
    for rings in polygons:
        vertices, codes = [], []
        for ring in rings:
            if len(ring) >= 4:
                vertices.extend(ring)
                codes.extend([Path.MOVETO, *([Path.LINETO] * (len(ring) - 2)), Path.CLOSEPOLY])
        if vertices:
            yield PathPatch(Path(vertices, codes))


def choropleths(rows):
    # Parse each municipality boundary once, then color it for both maps.
    groups = {False: ([], [], []), True: ([], [], [])}
    for province, raw_geometry, weekend_change, service_ratio in rows:
        if raw_geometry is None:
            continue
        patches, changes, ratios = groups[province in ("35", "38")]
        for patch in _patches(json.loads(raw_geometry)):
            patches.append(patch)
            changes.append(weekend_change)
            ratios.append(service_ratio)
    weekend = _map(
        groups, 1, TwoSlopeNorm(0, vmin=-0.65, vmax=0.65), "Weekend change vs. weekday trips",
        cmap=plt.get_cmap("RdBu").with_extremes(bad=MISSING), extend="both", formatter=PercentFormatter(1),
    )
    ratio_bands = [0, 0.25, 0.5, 1, 2, 5, 10, 20, 40]
    ratio_colors = ListedColormap([
        "#9c2c45", "#db745d", "#f4c5ad", "#e1edf1", "#b3d1e3", "#77abcf", "#3d7db7", "#20568b",
    ]).with_extremes(bad=MISSING, over="#0a2e57")
    gravity = _map(
        groups, 2, BoundaryNorm(ratio_bands, ratio_colors.N), "Observed / estimated trips",
        cmap=ratio_colors, extend="max", formatter=FuncFormatter(_multiple), ticks=ratio_bands,
    )
    return weekend, gravity


def _multiple(value, _position):
    return f"{value:g}×"


def _map(groups, value_index, norm, scale_label, *, cmap, extend, formatter, ticks=None):
    figure = plt.figure(figsize=(9.6, 6.3))
    main = figure.add_axes((0.035, 0.20, 0.92, 0.75))
    islands = figure.add_axes((0.04, 0.12, 0.26, 0.23))
    for axis, key, label in (
        (main, False, "Peninsula, Balearics, Ceuta and Melilla"), (islands, True, "Canary Islands"),
    ):
        patches = groups[key][0]
        values = np.array([np.nan if v is None else v for v in groups[key][value_index]], dtype=float)
        collection = PatchCollection(patches, cmap=cmap, norm=norm, edgecolor="#64748b", linewidth=0.15)
        collection.set_array(np.ma.masked_invalid(values))
        axis.add_collection(collection)
        axis.autoscale_view()
        axis.set_aspect("equal")
        if key:
            axis.set_xticks([])
            axis.set_yticks([])
            for spine in axis.spines.values():
                spine.set_color("#d9dee3")
        else:
            axis.set_axis_off()
        axis.set_title(label, color=INK, fontsize=9, loc="left", pad=5)
    scalar = plt.cm.ScalarMappable(norm=norm, cmap=cmap)
    scale = figure.add_axes((0.35, 0.11, 0.57, 0.028))
    figure.colorbar(scalar, cax=scale, orientation="horizontal", extend=extend, format=formatter, ticks=ticks, label=scale_label)
    figure.legend(handles=[Patch(facecolor=MISSING, label="No comparable data")],
                  loc="lower left", bbox_to_anchor=(0.06, 0.018), frameon=False, fontsize=8)
    return _png(figure)
