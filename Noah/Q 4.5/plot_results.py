import csv
import re
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np


HERE = Path(__file__).resolve().parent
RES = HERE / "res"
NUMBER = r"[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[Ee][-+]?\d+)?"


def read_field(path):
    triangles = []
    temperatures = []
    for line in path.read_text().splitlines():
        if not line.startswith("ST("):
            continue
        match = re.fullmatch(r"ST\((.*?)\)\{(.*?)\};", line)
        if match is None:
            raise ValueError(f"Unrecognized triangle in {path}: {line[:100]}")
        coords = np.asarray(re.findall(NUMBER, match.group(1)), dtype=float)
        values = np.asarray(re.findall(NUMBER, match.group(2)), dtype=float)
        if coords.size != 9 or values.size != 3:
            raise ValueError(f"Unexpected nodal triangle in {path}")
        triangles.append(coords.reshape(3, 3)[:, :2])
        temperatures.append(values)
    if not triangles:
        raise ValueError(f"No triangular temperature data found in {path}")

    xy = np.asarray(triangles).reshape(-1, 2)
    values = np.asarray(temperatures).reshape(-1)
    nodes, inverse = np.unique(
        np.round(xy, decimals=12), axis=0, return_inverse=True
    )
    nodal_values = np.zeros(len(nodes))
    np.add.at(nodal_values, inverse, values)
    nodal_values /= np.bincount(inverse)
    return nodes, inverse.reshape(-1, 3), nodal_values


def read_surface(path):
    x_values = []
    t_values = []
    for line in path.read_text().splitlines():
        numbers = [float(value) for value in re.findall(NUMBER, line)]
        if not numbers:
            continue
        if len(numbers) < 10:
            raise ValueError(f"Unexpected surface element in {path}: {line[:100]}")
        x_values.extend((numbers[2], numbers[5]))
        t_values.extend(numbers[-2:])
    if not x_values:
        raise ValueError(f"No surface temperature data found in {path}")
    order = np.argsort(x_values)
    return np.asarray(x_values)[order], np.asarray(t_values)[order]


with (HERE / "results.csv").open(newline="", encoding="utf-8") as source:
    rows = {row["case"]: row for row in csv.DictReader(source)}
if set(rows) != {"convection", "dirichlet"}:
    raise ValueError("results.csv must contain convection and dirichlet cases")

fields = {
    case: read_field(RES / case / "T_domain.pos")
    for case in ("convection", "dirichlet")
}
vmin = min(float(row["T_domain_min_C"]) for row in rows.values())
vmax = max(float(row["T_domain_max_C"]) for row in rows.values())
levels = np.linspace(vmin, vmax, 100)
fig, axes = plt.subplots(2, 2, figsize=(11, 10), constrained_layout=True)
for column, case in enumerate(("convection", "dirichlet")):
    nodes, triangles, temperature = fields[case]
    label = "Convection" if case == "convection" else "Surface Dirichlet"
    surface_max = float(rows[case]["T_surface_max_C"])
    for row, window in enumerate((1.1, 0.075)):
        ax = axes[row, column]
        image = ax.tricontourf(
            nodes[:, 0], nodes[:, 1], triangles, temperature,
            levels=levels, cmap="turbo", vmin=vmin, vmax=vmax,
        )
        ax.axhline(0, color="white", linestyle="--", linewidth=0.8)
        ax.set_xlim(-window, window)
        ax.set_ylim(-1.0 - window, -1.0 + window)
        ax.set_aspect("equal")
        ax.set_xlabel("x [m]")
        ax.set_ylabel("y [m]")
        ax.set_title(
            f"{label} (surface max {surface_max:.5f} C)"
            if row == 0 else f"{label}, cable zoom"
        )
fig.colorbar(image, ax=axes, label="T [C]", shrink=0.85)
fig.savefig(HERE / "temperature_comparison.png", dpi=250)
plt.close(fig)

fig, ax = plt.subplots(figsize=(9, 4.5))
for case, label, color in (
    ("convection", "Convection", "#0072B2"),
    ("dirichlet", "Surface Dirichlet", "#D55E00"),
):
    x, temperature = read_surface(RES / case / "T_surface_elements.txt")
    surface_max = float(rows[case]["T_surface_max_C"])
    ax.plot(x, temperature, color=color, linewidth=1.2,
            label=f"{label} (max {surface_max:.5f} C)")
ax.axhline(20, color="black", linestyle="--", linewidth=0.8, label="T_amb")
ax.set_xlabel("x along ground/air interface [m]")
ax.set_ylabel("T [C]")
ax.set_title("Ground/air interface temperature")
ax.grid(True, alpha=0.3)
ax.legend()
fig.tight_layout()
fig.savefig(HERE / "surface_temperature.png", dpi=250)
plt.close(fig)

print("Wrote temperature_comparison.png and surface_temperature.png")
