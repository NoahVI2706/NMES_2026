"""Q4.7: reproducible staggered electrothermal iteration and mesh comparison.

Requires Gmsh, GetDP; matplotlib optional. Run: python run_nonlinear.py --gmsh PATH --getdp PATH
The formulation still solves one MQS and one thermal problem per outer iteration.
"""
from __future__ import annotations
import argparse
import csv
import math
import re
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent
NUMBER = r"[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[Ee][-+]?\d+)?"
ENTRY = re.compile(r"ST\((.*?)\)\{(.*?)\};")
SIGMA_20 = 3.51646e7  # effective 20 C conductivity from the Q4.4 reference
ALPHA = 0.00390       # aluminium [1/K]
TREF = 20.0           # deg C
I_RMS = 385.0         # A per phase
R_COND = 0.00905      # metres
CENTRES = ((0.0, -1.0 + 0.0254), (-0.022, -1.0 - 0.0127), (0.022, -1.0 - 0.0127))


def run_command(args: list[str], logfile: Path) -> None:
    logfile.parent.mkdir(parents=True, exist_ok=True)
    with logfile.open('w', encoding='utf-8', errors='replace') as f:
        f.write('COMMAND: ' + ' '.join(map(str, args)) + '\n\n')
        f.flush()
        result = subprocess.run(args, cwd=ROOT, stdout=f, stderr=subprocess.STDOUT, check=False)
    if result.returncode:
        tail = logfile.read_text(encoding='utf-8', errors='replace').splitlines()[-25:]
        raise RuntimeError(f"Command failed, exit {result.returncode}: {logfile}\n" + '\n'.join(tail))


def read_number(path: Path) -> float:
    # GetDP 'Format Table' global output usually: '0  value  0'.
    lines = [line for line in path.read_text(errors='replace').splitlines()
             if line.strip() and not line.lstrip().startswith(('#', '//'))]
    if not lines:
        raise ValueError(f'Empty GetDP result: {path}')
    for line in reversed(lines):
        values = re.findall(NUMBER, line)
        if len(values) >= 2:
            return float(values[1])
    raise ValueError(f'Could not parse global quantity in {path}')


def read_core_temperatures(pos_file: Path):
    """Area-weighted conductor averages and maximum nodal temperatures (deg C).

    Reads Gmsh ASCII scalar-triangle entries, as in the teammate's plot_T.py.
    Identifies conductor triangles by their centroid. Also computes the thermal
    nodal maxima per core, avoiding a fragile dependency on GetDP log formatting.
    """
    sums = [0.0] * 3
    areas = [0.0] * 3
    maxima = [-math.inf] * 3
    counted = 0
    for line in pos_file.open(encoding='utf-8', errors='replace'):
        if not line.startswith('ST('):
            continue
        match = ENTRY.fullmatch(line.strip())
        if not match:
            raise ValueError(f'Unexpected ST format: {line[:100]}')
        xyz = [float(v) for v in re.findall(NUMBER, match.group(1))]
        vals = [float(v) for v in re.findall(NUMBER, match.group(2))]
        if len(xyz) != 9 or len(vals) != 3:
            raise ValueError('Expected 3 3D vertices and 3 scalar temperatures')
        x1,y1 = xyz[0],xyz[1]
        x2,y2 = xyz[3],xyz[4]
        x3,y3 = xyz[6],xyz[7]
        cx,cy = (x1+x2+x3)/3,(y1+y2+y3)/3
        core = next((j for j,(x0,y0) in enumerate(CENTRES)
                     if (cx-x0)**2+(cy-y0)**2 < (R_COND-1e-9)**2), None)
        if core is None:
            continue
        area = abs((x2-x1)*(y3-y1)-(x3-x1)*(y2-y1))/2
        sums[core] += area * sum(vals)/3
        areas[core] += area
        maxima[core] = max(maxima[core], *vals)
        counted += 1
    if counted == 0 or any(a == 0 for a in areas):
        raise ValueError('No conductor triangles found in T_cable.pos; check geometry and POS format')
    theoretical = math.pi*R_COND**2
    for j,a in enumerate(areas):
        if abs(a/theoretical - 1) > 0.05:
            raise ValueError(f'Core {j} area differs >5% from expected; cannot trust temperature extraction: {a}')
    return [s/a for s,a in zip(sums,areas)], maxima


def save_rows(path: Path, rows: list[dict]) -> None:
    if not rows: return
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)


def copy_results(dest: Path) -> None:
    dest.mkdir(parents=True, exist_ok=True)
    for name in ['T_cable.pos','T_domain.pos','loss_conductors.txt',
                 'loss_sheaths.txt','loss_armour.txt','loss_other.txt',
                 'P_in.txt','P_out.txt','B_magnitude.pos','J_magnitude.pos']:
        src = ROOT/'res'/name
        if src.exists(): shutil.copy2(src, dest/name)


def plot_histories(results: list[dict], output: Path) -> None:
    try:
        import matplotlib.pyplot as plt
    except ImportError:
        print('matplotlib not installed: CSVs are ready; skipping PNG plots')
        return
    fig, ax = plt.subplots(figsize=(8.2, 4.5))
    for mesh in sorted({r['mesh_mm'] for r in results}, reverse=True):
        data = [r for r in results if r['mesh_mm'] == mesh and r['iteration'] > 0]
        if data:
            ax.semilogy([r['iteration'] for r in data], [r['relative_increment'] for r in data],
                        '-o', label=f'{mesh:g} mm')
    ax.axhline(1e-6, linestyle='--', linewidth=1.2, label='Tolerance: 1e-6')
    ax.set(xlabel='Electrothermal iteration', ylabel='Relative increment of core-average temperatures',
           title='Q4.7 — Nonlinear convergence')
    ax.legend()
    fig.tight_layout()
    fig.savefig(output/'convergence.png', dpi=250)
    plt.close(fig)

    fig, ax = plt.subplots(figsize=(8.2, 4.5))
    for mesh in sorted({r['mesh_mm'] for r in results}, reverse=True):
        data = [r for r in results if r['mesh_mm'] == mesh]
        ax.plot([r['iteration'] for r in data], [r['T_cond_max_C'] for r in data], '-o', label=f'{mesh:g} mm')
    ax.set(xlabel='Electrothermal iteration',ylabel='Maximum conductor temperature [°C]',
           title='Q4.7 — Conductor temperature versus iteration')
    ax.legend()
    fig.tight_layout()
    fig.savefig(output/'temperature_iteration.png', dpi=250)
    plt.close(fig)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--gmsh', default='gmsh', help='Full path to gmsh.exe, or gmsh on PATH')
    ap.add_argument('--getdp', default='getdp', help='Full path to getdp.exe, or getdp on PATH')
    ap.add_argument('--meshes', type=float, nargs='+', default=[1.0, 0.5],
                    help='Cable mesh sizes [mm]; 0.25 mm optional for fine verification')
    ap.add_argument('--tol', type=float, default=1e-6)
    ap.add_argument('--max-iterations', type=int, default=20)
    args = ap.parse_args()
    out = ROOT/'outputs'
    out.mkdir(exist_ok=True)
    all_rows, summary = [], []
    for mesh in args.meshes:
        mesh_out = out/f'mesh_{mesh:g}mm'
        mesh_out.mkdir(parents=True, exist_ok=True)
        print(f'\n=== Mesh {mesh:g} mm ===', flush=True)
        run_command([args.gmsh, 'cable_thermal.geo', '-2', '-format', 'msh2',
                     '-setnumber', 'lc_cable', str(mesh), '-o','cable_thermal.msh', '-v','2'],
                    mesh_out/'gmsh.log')
        sigma = SIGMA_20
        previous_means = None
        mesh_rows = []
        converged = False
        for it in range(args.max_iterations+1):
            # The GetDP operation already does one MQS solve followed by one thermal solve.
            cmd = [args.getdp, 'cable_thermal.pro', '-msh','cable_thermal.msh',
                   '-setnumber','sigma_conductor',format(sigma,'.12g'),
                   '-setnumber','sigma_Soil_mqs','0.01',
                   '-setnumber','bottom_bc','0',
                   '-setnumber','kappa_xlpe','0.46',
                   '-setnumber','kappa_filler','0.40',
                   '-setnumber','kappa_polyethylene','0.46',
                   '-solve','Coupled','-pos','ThermalOutputs','-v','4']
            run_command(cmd, mesh_out/f'getdp_iter_{it:02d}.log')
            means, maxima = read_core_temperatures(ROOT/'res'/'T_cable.pos')
            # The current formulation has one effective sigma for all 3 aluminium cores.
            # We update it using the equal-area mean of the 3 mean core temperatures.
            representative_T = sum(means)/3
            sigma_next = SIGMA_20/(1+ALPHA*(representative_T-TREF))
            if previous_means is None:
                err = float('nan')
            else:
                err = max(abs(a-b) for a,b in zip(means,previous_means)) / max(
                    1.0, max(t+273.15 for t in means))
            row = dict(mesh_mm=mesh, iteration=it, sigma_used_Spm=sigma,
                       sigma_next_Spm=sigma_next, T_A_mean_C=means[0],
                       T_B_mean_C=means[1], T_C_mean_C=means[2],
                       T_A_max_C=maxima[0], T_B_max_C=maxima[1],
                       T_C_max_C=maxima[2], T_cond_max_C=max(maxima),
                       relative_increment=err,
                       P_Al_Wpm=read_number(ROOT/'res'/'loss_conductors.txt'),
                       P_Lead_Wpm=read_number(ROOT/'res'/'loss_sheaths.txt'),
                       P_Armour_Wpm=read_number(ROOT/'res'/'loss_armour.txt'),
                       P_Other_Wpm=read_number(ROOT/'res'/'loss_other.txt'),
                       P_total_Wpm=read_number(ROOT/'res'/'P_in.txt'),
                       P_out_Wpm=read_number(ROOT/'res'/'P_out.txt'))
            row['R_ac_eff_Ohm_per_km'] = 1000*row['P_total_Wpm']/(3*I_RMS**2)
            if it == 0:
                copy_results(mesh_out/'linear_reference')
            mesh_rows.append(row); all_rows.append(row)
            print(f'Iteration {it:02d}: max T={row["T_cond_max_C"]:.6f} C; '
                  f'P={row["P_total_Wpm"]:.6f} W/m; '
                  f'sigma={sigma:.7g}; err={err:.3e}',flush=True)
            if it > 0 and err < args.tol:
                converged = True
                copy_results(mesh_out/'nonlinear_final')
                break
            previous_means = means
            sigma = sigma_next
        save_rows(mesh_out/'iterations.csv', mesh_rows)
        last = mesh_rows[-1]
        summary.append(dict(mesh_mm=mesh, converged=converged,
                            iterations=last['iteration'],
                            linear_T_max_C=mesh_rows[0]['T_cond_max_C'],
                            nonlinear_T_max_C=last['T_cond_max_C'],
                            delta_T_C=last['T_cond_max_C']-mesh_rows[0]['T_cond_max_C'],
                            linear_total_Wpm=mesh_rows[0]['P_total_Wpm'],
                            nonlinear_total_Wpm=last['P_total_Wpm'],
                            nonlinear_Rac_Ohm_per_km=last['R_ac_eff_Ohm_per_km'],
                            convective_surface_Wpm=last['P_out_Wpm']))
        if not converged:
            print('WARNING: did not reach tolerance; inspect iteration history.')
    save_rows(out/'all_iterations.csv', all_rows)
    save_rows(out/'mesh_summary.csv', summary)
    plot_histories(all_rows, out)
    print('\nDone. Read outputs/mesh_summary.csv, outputs/convergence.png,')
    print('and per-mesh iterations.csv. Baseline/final .pos maps are in each mesh folder.')

if __name__ == '__main__':
    main()
