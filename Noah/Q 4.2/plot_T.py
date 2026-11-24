import re
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np


HERE = Path(__file__).resolve().parent
POS = HERE / "res" / "T_domain.pos"

number = r"[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[Ee][-+]?\d+)?"
points = []
temperature = []

for line in POS.read_text().splitlines():
    if not line.startswith("ST("):
        continue
    match = re.match(r"ST\((.*?)\)\{(.*?)\};", line)
    if not match:
        continue
    coords = [float(v) for v in re.findall(number, match.group(1))]
    values = [float(v) for v in re.findall(number, match.group(2))]
    vertices = np.asarray(coords, dtype=float).reshape(3, 3)
    points.append(vertices[:, :2])
    temperature.append(values)

triangles = np.asarray(points, dtype=float)
nodal_temperature = np.asarray(temperature, dtype=float)

xy = triangles.reshape(-1, 2)
xy_temperature = nodal_temperature.reshape(-1)
unique_xy, inverse = np.unique(
    np.round(xy, decimals=12), axis=0, return_inverse=True
)
node_temperature = np.zeros(len(unique_xy))
np.add.at(node_temperature, inverse, xy_temperature)
counts = np.bincount(inverse)
node_temperature[counts > 0] /= counts[counts > 0]

tri = inverse.reshape(-1, 3)

whole = plt.figure(figsize=(8, 6))
ax = whole.add_subplot(111)
levels = np.arange(20, 69.01, 5)
field = ax.tricontourf(
    unique_xy[:, 0], unique_xy[:, 1], tri, node_temperature,
    levels=np.linspace(20, 69, 98), cmap="turbo", vmin=20, vmax=69
)
ax.tricontour(
    unique_xy[:, 0], unique_xy[:, 1], tri, node_temperature,
    levels=levels, colors="black", linewidths=0.5
)
whole.colorbar(field, ax=ax, label="T [C]")
ax.set_aspect("equal")
ax.set_xlabel("x [m]")
ax.set_ylabel("y [m]")
ax.set_title("Temperature in the whole domain")
whole.tight_layout()
whole.savefig(HERE / "T_domain.png", dpi=300)
plt.close(whole)

window = 0.15
cx, cy = 0.0, -1.0
in_window = (
    (unique_xy[:, 0] >= cx - window / 2)
    & (unique_xy[:, 0] <= cx + window / 2)
    & (unique_xy[:, 1] >= cy - window / 2)
    & (unique_xy[:, 1] <= cy + window / 2)
)
cable_min = float(node_temperature[in_window].min())
cable_max = float(node_temperature[in_window].max())

zoom = plt.figure(figsize=(7, 7))
ax = zoom.add_subplot(111)
field = ax.tricontourf(
    unique_xy[:, 0], unique_xy[:, 1], tri, node_temperature,
    levels=np.linspace(cable_min, cable_max, 98),
    cmap="turbo", vmin=cable_min, vmax=cable_max
)
zoom.colorbar(field, ax=ax, label="T [C]")
ax.set_aspect("equal")
ax.set_xlim(cx - window / 2, cx + window / 2)
ax.set_ylim(cy - window / 2, cy + window / 2)
ax.set_xlabel("x [m]")
ax.set_ylabel("y [m]")
ax.set_title("Cable temperature (0.15 m window)")
zoom.tight_layout()
zoom.savefig(HERE / "T_cable.png", dpi=300)
plt.close(zoom)

print("Wrote T_domain.png")
print("Wrote T_cable.png")
