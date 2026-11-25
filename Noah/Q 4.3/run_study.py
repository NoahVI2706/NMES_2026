import csv
import re
import subprocess
from pathlib import Path


HERE = Path(__file__).resolve().parent
GMSH = Path(r"C:\Users\Noah\Downloads\BURGI\NM\FE\onelab-Windows64real\onelab-Windows64real\gmsh.exe")
GETDP = Path(r"C:\Users\Noah\Downloads\BURGI\NM\FE\onelab-Windows64real\onelab-Windows64real\getdp.exe")
RES = HERE / "res"
RES.mkdir(exist_ok=True)
CSV = HERE / "results.csv"


def last_number(path):
    text = path.read_text(errors="ignore")
    values = [float(v) for v in re.findall(r"[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[Ee][-+]?\d+)?", text)]
    return values[-1] if values else None


def run(study, lc, D, W, bottom):
    msh = HERE / "cable_thermal.msh"
    try:
        subprocess.run([
            str(GMSH), str(HERE / "cable_thermal.geo"), "-setnumber", "lc_cable", str(lc),
            "-setnumber", "lc_far", "1.5", "-setnumber", "D", str(D),
            "-setnumber", "W", str(W), "-2", "-format", "msh2",
            "-o", str(msh), "-v", "1"
        ], cwd=HERE, check=True, capture_output=True, text=True)
        proc = subprocess.run([
            str(GETDP), str(HERE / "cable_thermal.pro"), "-msh", str(msh),
            "-setnumber", "bottom_bc", str(bottom), "-setnumber", "D", str(D),
            "-setnumber", "W", str(W), "-setnumber", "lc_cable", str(lc),
            "-setnumber", "lc_far", "1.5", "-solve", "Thermal",
            "-pos", "ThermalOutputs", "-v", "3"
        ], cwd=HERE, check=True, capture_output=True, text=True)
        log = proc.stdout + proc.stderr
        match = re.search(r"System\s+\S*:\s*([0-9]+)\s+Dofs", log)
        n_dofs = int(match.group(1)) if match else None
        vals = []
        pos = RES / "T_cond_elements.txt"
        for line in pos.read_text(errors="ignore").splitlines():
            nums = re.findall(r"[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[Ee][-+]?\d+)?", line)
            if len(nums) >= 3:
                vals.extend([float(v) for v in nums[-3:]])
        T_cond_max = max(vals) if vals else None
        P_in = last_number(RES / "P_in.txt")
        P_out = last_number(RES / "P_out.txt")
        return [study, lc, D, W, bottom, n_dofs, T_cond_max, P_in, P_out]
    except Exception as exc:
        detail = getattr(exc, "stderr", "") or str(exc)
        return [study, lc, D, W, bottom, "", "", "", "ERROR: " + detail.strip()[:2000]]


cases = []
for lc in (2.0, 1.0, 0.5, 0.25):
    cases.append(("A", lc, 30, 60, 0))
for D in (10, 20, 30, 60, 100):
    for bottom in (0, 1):
        cases.append(("B", 0.5, D, 2 * D, bottom))

with CSV.open("w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["study", "lc_cable", "D", "W", "bottom_bc", "n_dofs", "T_cond_max", "P_in", "P_out"])
    for case in cases:
        writer.writerow(run(*case))

print(CSV)
