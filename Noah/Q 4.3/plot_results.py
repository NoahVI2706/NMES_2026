import csv
from pathlib import Path

import matplotlib.pyplot as plt


HERE = Path(__file__).resolve().parent
BLUE = "#0072B2"
ORANGE = "#D55E00"


def read_rows():
    with (HERE / "results.csv").open(newline="", encoding="utf-8") as file:
        rows = list(csv.DictReader(file))
    for row in rows:
        for key in ("lc_cable", "D", "bottom_bc", "n_dofs", "T_cond_max"):
            row[key] = float(row[key])
    return rows


def zoom_y_axis(axis, values):
    low, high = min(values), max(values)
    padding = max((high - low) * 0.2, 0.02)
    axis.set_ylim(low - padding, high + padding)


rows = read_rows()
mesh_rows = sorted(
    (row for row in rows if row["study"] == "A"),
    key=lambda row: row["n_dofs"],
)

fig, ax = plt.subplots(figsize=(8, 4.5))
dofs = [row["n_dofs"] for row in mesh_rows]
temps = [row["T_cond_max"] for row in mesh_rows]
ax.plot(dofs, temps, marker="o", color=BLUE, label="Study A")
ax.set_xscale("log")
for index, row in enumerate(mesh_rows):
    offset = (0, 9 if index % 2 == 0 else -15)
    ax.annotate(
        f'{row["lc_cable"]:g} mm',
        (row["n_dofs"], row["T_cond_max"]),
        xytext=offset,
        textcoords="offset points",
        ha="center",
    )
ax.set_xlabel("DoFs")
ax.set_ylabel("T_cond,max [°C]")
ax.set_title("Mesh convergence (study A)")
ax.grid(True, which="both", alpha=0.3)
ax.legend()
zoom_y_axis(ax, temps)
fig.tight_layout()
fig.savefig(HERE / "fig_mesh.png", dpi=200)
plt.close(fig)

domain_rows = [row for row in rows if row["study"] == "B"]
fig, ax = plt.subplots(figsize=(8, 4.5))
limits = []
all_temps = []
labels = {0.0: "T = T_amb", 1.0: "zero flux"}
colors = {0.0: BLUE, 1.0: ORANGE}

for bottom_bc in (0.0, 1.0):
    curve = sorted(
        (row for row in domain_rows if row["bottom_bc"] == bottom_bc),
        key=lambda row: row["D"],
    )
    if len(curve) < 2:
        raise ValueError(f"Study B needs at least two points for bottom_bc={bottom_bc:g}")
    depths = [row["D"] for row in curve]
    temps = [row["T_cond_max"] for row in curve]
    all_temps.extend(temps)
    limits.append(temps[-1] + (temps[-1] - temps[-2]) / 3)
    ax.plot(depths, temps, marker="o", color=colors[bottom_bc], label=labels[bottom_bc])

mean_limit = sum(limits) / len(limits)
limit_label = (
    f"Mean extrapolated limit = {mean_limit:.4f} °C "
    f"(BC0 {limits[0]:.4f}, BC1 {limits[1]:.4f})"
)
ax.axhline(mean_limit, color="#333333", linestyle="--", label=limit_label)
ax.set_xscale("log")
ax.set_xlabel("D [m]")
ax.set_ylabel("T_cond,max [°C]")
ax.set_title("Domain-size convergence (study B)")
ax.grid(True, which="both", alpha=0.3)
ax.legend()
zoom_y_axis(ax, all_temps + [mean_limit])
fig.tight_layout()
fig.savefig(HERE / "fig_domain.png", dpi=200)
plt.close(fig)
