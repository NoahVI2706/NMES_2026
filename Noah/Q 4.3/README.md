# Q4.3 mesh and domain convergence

## Tools

- Gmsh 4.15.2 (ONELAB Windows bundle)
- GetDP 4.0.0-git-259f4c38
- Python 3.10 with NumPy and Matplotlib

## Files

- [cable_thermal.geo](./cable_thermal.geo): parameterized cable/seabed geometry, physical groups, and mesh fields.
- [cable_thermal.pro](./cable_thermal.pro): Onelab defaults and thermal parameters; includes the formulation.
- [thermal_formulation.pro](./thermal_formulation.pro): regions, material conductivities, mesh-normalized heat sources, thermal equation, boundary conditions, and result exports.
- [Jacobian_Integration.pro](./Jacobian_Integration.pro): Jacobian and integration definitions included by the formulation.
- [run_study.py](./run_study.py): runs Gmsh/GetDP cases A and B, recording DoFs, temperatures, and powers in `results.csv`.
- [plot_results.py](./plot_results.py): reads `results.csv` and creates `fig_mesh.png` and `fig_domain.png`.

## Reproduce the slide results

Run from PowerShell in this folder. `run_study.py` contains the installed Gmsh/GetDP paths and the exact sweeps below; it overwrites `results.csv`. Then generate both figures:

```powershell
Set-Location 'C:\Users\Noah\Downloads\BURGI\NM\FE\Lab\NMES_2026\Noah\Q 4.3'
$python = 'C:\Users\Noah\AppData\Local\Programs\Python\Python310\python.exe'
& $python .\run_study.py
& $python .\plot_results.py
```

| Study | Parameters |
|---|---|
| A — mesh | `D=30 m`, `W=60 m`, `bottom_bc=0`; `lc_cable=2, 1, 0.5, 0.25 mm` |
| B — domain | `lc_cable=0.5 mm`; `D=10, 20, 30, 60, 100 m`; `W=2D`; both `bottom_bc=0` and `1` |

`bottom_bc=0` fixes the bottom at `T_amb`; `1` gives zero flux. The mesh uses `lc_near=5*lc_cable` and `lc_far=1.5*D/30 m`. Other values, including the 53.2927608 W/m total source, use the model-file defaults. `fig_domain.png` reports a mean extrapolated limit of 59.2428 °C.
