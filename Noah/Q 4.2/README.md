# Q4.2 cable thermal model

## Tools

- Gmsh 4.15.2 (ONELAB Windows bundle)
- GetDP 4.0.0-git-259f4c38
- Python 3.10 with NumPy and Matplotlib

## Files

- [cable_thermal.geo](./cable_thermal.geo): cable/seabed geometry, physical groups, and mesh fields.
- [cable_thermal.pro](./cable_thermal.pro): thermal Onelab parameters; includes the formulation.
- [thermal_formulation.pro](./thermal_formulation.pro): regions, materials, sources, weak form, boundary conditions, and result exports.
- [Jacobian_Integration.pro](./Jacobian_Integration.pro): Jacobians and integration rules included by the formulation.
- [plot_T.py](./plot_T.py): reads `res/T_domain.pos` and writes `T_domain.png` and `T_cable.png`.
- `ABB_three_core.geo` / `ABB_three_core.pro`: legacy electrodynamic model files; not included or needed by the Q4.2 thermal workflow.

## Reproduce current slide figures

Run in PowerShell. These defaults use zero flux at the bottom, convection at the surface, and the current mesh-normalized total source of 53.2927608 W/m.

```powershell
$gmsh = 'C:\Users\Noah\Downloads\BURGI\NM\FE\onelab-Windows64real\onelab-Windows64real\gmsh.exe'
$getdp = 'C:\Users\Noah\Downloads\BURGI\NM\FE\onelab-Windows64real\onelab-Windows64real\getdp.exe'
$python = 'C:\Users\Noah\AppData\Local\Programs\Python\Python310\python.exe'
Set-Location 'C:\Users\Noah\Downloads\BURGI\NM\FE\Lab\NMES_2026\Noah\Q 4.2'
New-Item -ItemType Directory -Force .\res | Out-Null
& $gmsh .\cable_thermal.geo -2 -format msh2 -o .\cable_thermal.msh
& $getdp .\cable_thermal.pro -msh .\cable_thermal.msh -setnumber bottom 1 -solve Thermal -pos ThermalOutputs
& $python .\plot_T.py
```

`bottom=1` is zero flux; use `-setnumber bottom 0` for `T=T_amb` at the bottom. Other defaults are in the two model files.
