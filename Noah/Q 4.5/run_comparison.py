import csv
import re
import shutil
import subprocess
from pathlib import Path


HERE = Path(__file__).resolve().parent
GMSH = Path(r"C:\Users\Noah\Downloads\BURGI\NM\FE\onelab-Windows64real\onelab-Windows64real\gmsh.exe")
GETDP = Path(r"C:\Users\Noah\Downloads\BURGI\NM\FE\onelab-Windows64real\onelab-Windows64real\getdp.exe")
RES = HERE / "res"
MESH = HERE / "cable_thermal.msh"
CSV_PATH = HERE / "results.csv"
NUMBER = r"[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[Ee][-+]?\d+)?"


def values_from_table(path, count):
    values = []
    for line in path.read_text().splitlines():
        numbers = re.findall(NUMBER, line)
        if len(numbers) >= count:
            values.extend(float(value) for value in numbers[-count:])
    if not values:
        raise ValueError(f"No temperature values found in {path}")
    return values


def domain_temperatures(path):
    values = []
    for line in path.read_text().splitlines():
        if not line.startswith("ST("):
            continue
        match = re.fullmatch(r"ST\(.*?\)\{(.*?)\};", line)
        if match is None:
            raise ValueError(f"Unrecognized triangle in {path}: {line[:100]}")
        values.extend(float(value) for value in re.findall(NUMBER, match.group(1)))
    if not values:
        raise ValueError(f"No triangular temperature data found in {path}")
    return values


def read_scalar(path):
    values = re.findall(NUMBER, path.read_text())
    if not values:
        raise ValueError(f"No numeric result found in {path}")
    return float(values[-1])


def run_case(case, surface_bc):
    proc = subprocess.run(
        [
            str(GETDP), str(HERE / "cable_thermal.pro"), "-msh", str(MESH),
            "-setnumber", "surface_bc", str(surface_bc),
            "-setnumber", "bottom_bc", "1",
            "-solve", "Coupled", "-pos", "ThermalOutputs", "-v", "3",
        ],
        cwd=HERE, check=True, capture_output=True, text=True,
    )
    log = proc.stdout + proc.stderr
    dofs = [int(value) for value in re.findall(
        r"System\s+\d+/\d+:\s+(\d+)\s+Dofs", log
    )]
    if len(dofs) != 2:
        raise ValueError(f"Could not read both DoF counts from GetDP output:\n{log}")

    case_dir = RES / case
    case_dir.mkdir(parents=True, exist_ok=True)
    for name in ("T_domain.pos", "T_cable.pos", "T_surface_elements.txt"):
        shutil.copy2(RES / name, case_dir / name)

    surface_values = values_from_table(RES / "T_surface_elements.txt", 2)
    conductor_values = values_from_table(RES / "T_cond_elements.txt", 3)
    domain_values = domain_temperatures(RES / "T_domain.pos")
    row = {
        "case": case,
        "surface_bc": surface_bc,
        "bottom_bc": 1,
        "n_dofs_mqs": dofs[0],
        "n_dofs_thermal": dofs[1],
        "T_surface_max_C": max(surface_values),
        "T_cond_max_C": max(conductor_values),
        "T_domain_min_C": min(domain_values),
        "T_domain_max_C": max(domain_values),
        "P_in_W_per_m": read_scalar(RES / "P_in.txt"),
    }
    if surface_bc == 0:
        row["P_out_W_per_m"] = read_scalar(RES / "P_out.txt")
    else:
        row["P_out_W_per_m"] = ""
    return row


RES.mkdir(exist_ok=True)
mesh_result = subprocess.run(
    [
        str(GMSH), str(HERE / "cable_thermal.geo"), "-2",
        "-format", "msh2", "-o", str(MESH), "-v", "1",
    ],
    cwd=HERE, check=True, capture_output=True, text=True,
)

columns = [
    "case", "surface_bc", "bottom_bc", "n_dofs_mqs", "n_dofs_thermal",
    "T_surface_max_C", "T_cond_max_C", "T_domain_min_C", "T_domain_max_C",
    "P_in_W_per_m", "P_out_W_per_m",
]
with CSV_PATH.open("w", newline="", encoding="utf-8") as output:
    writer = csv.DictWriter(output, fieldnames=columns)
    writer.writeheader()
    for case, surface_bc in (("convection", 0), ("dirichlet", 1)):
        row = run_case(case, surface_bc)
        writer.writerow(row)
        print(
            f"{case}: surface max={row['T_surface_max_C']:.8f} C, "
            f"conductor max={row['T_cond_max_C']:.8f} C"
        )
print(f"Wrote {CSV_PATH}")
