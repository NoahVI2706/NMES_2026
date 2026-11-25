import re
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np


HERE = Path(__file__).resolve().parent
POS = HERE / "res" / "T_cable.pos"
NUMBER = r"[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[Ee][-+]?\d+)?"
ENTRY = re.compile(r"ST\((.*?)\)\{(.*?)\};")

triangles = []
temperatures = []
for line in POS.read_text().splitlines():
    if not line.startswith("ST("):
        continue
    match = ENTRY.fullmatch(line)
    if match is None:
        raise ValueError(f"Unrecognized ST element: {line[:100]}")
    coords = np.asarray(re.findall(NUMBER, match.group(1)), dtype=float)
    values = np.asarray(re.findall(NUMBER, match.group(2)), dtype=float)
    if coords.size != 9 or values.size != 3:
        raise ValueError("Expected three 3D vertices and three nodal temperatures")
    triangles.append(coords.reshape(3, 3)[:, :2])
    temperatures.append(values)

if not triangles:
    raise ValueError(f"No triangular temperature data found in {POS}")

xy = np.asarray(triangles).reshape(-1, 2)
values = np.asarray(temperatures).reshape(-1)
nodes, inverse = np.unique(np.round(xy, decimals=12), axis=0, return_inverse=True)
node_temperature = np.zeros(len(nodes))
np.add.at(node_temperature, inverse, values)
counts = np.bincount(inverse)
node_temperature /= counts
tri = inverse.reshape(-1, 3)

fig, ax = plt.subplots(figsize=(7, 7))
field = ax.tricontourf(
    nodes[:, 0], nodes[:, 1], tri, node_temperature,
    levels=100, cmap="turbo",
)
fig.colorbar(field, ax=ax, label="T [°C]")
ax.set_aspect("equal")
ax.set_xlabel("x [m]")
ax.set_ylabel("y [m]")
ax.set_title("Cable temperature")
fig.tight_layout()
fig.savefig(HERE / "T_cable.png", dpi=300)
plt.close(fig)
print(f"Wrote {HERE / 'T_cable.png'}")
