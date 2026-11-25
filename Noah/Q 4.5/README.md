# Q4.5 ground/air surface temperature

## Tools

- Gmsh 4.15.2 (ONELAB Windows bundle)
- GetDP 4.0.0-git-259f4c38
- Python 3.10 with NumPy and Matplotlib

## Files

- [cable_thermal.geo](./cable_thermal.geo): cable/seabed geometry, physical groups, and mesh fields.
- [cable_thermal.pro](./cable_thermal.pro): Onelab defaults and the surface/bottom boundary switches; includes the formulation.
- [thermal_formulation.pro](./thermal_formulation.pro): coupled MQS/thermal equations, Joule source, materials, boundary conditions, and result exports.
- [run_comparison.py](./run_comparison.py): meshes once, solves convection and surface-Dirichlet cases, and writes `results.csv` plus case-specific data under `res/`.
- [plot_results.py](./plot_results.py): reads `results.csv` and case data to create `temperature_comparison.png` and `surface_temperature.png`.
- `cable_mag_q3.pro`, `cable_common_q3.pro`, `cable_geometry_q3.geo`, and `cable_parameters_q3.geo`: Q3 reference files for the MQS model and its legacy geometry/material definitions; the Q4.5 coupled implementation is in `thermal_formulation.pro`.
- [Jacobian_Integration.pro](./Jacobian_Integration.pro): Jacobian and integration definitions used by the formulation.

## Reproduce the slide results

Run in PowerShell from this folder. `run_comparison.py` uses the Gmsh/GetDP paths installed in the script and regenerates the same default mesh for both cases.

```powershell
Set-Location 'C:\Users\Noah\Downloads\BURGI\NM\FE\Lab\NMES_2026\Noah\Q 4.5'
$python = 'C:\Users\Noah\AppData\Local\Programs\Python\Python310\python.exe'
& $python .\run_comparison.py
& $python .\plot_results.py
```

Defaults: `D=30 m`, `W=60 m`, `L=1 m`, `lc_cable=0.4 mm`, `Freq=50 Hz`, `I_rms=385 A`, and `sigma_Soil_mqs=0.5 S/m`. Both runs use `bottom_bc=1` (zero flux); `surface_bc=0` is convection and `surface_bc=1` fixes the ground/air surface to `T_amb`. Side boundaries remain zero flux. The generated plots show the cable/near-surface fields and the ground/air interface profile.

| Surface condition | Surface maximum | Conductor maximum | `P_in` | `P_out` | DoFs (MQS + thermal) |
|---|---:|---:|---:|---:|---:|
| Convection | 20.034096 °C | 59.226696 °C | 53.374274 W/m | 53.374274 W/m | 65,550 + 32,944 |
| Dirichlet, `T=T_amb` | 20.000000 °C | 59.209667 °C | 53.374274 W/m | — | 65,550 + 32,853 |

`P_out` is blank for the Dirichlet case because the reported quantity is convective surface loss.
