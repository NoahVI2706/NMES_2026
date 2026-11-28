# Q4.4 coupled MQS-thermal model

## Tools

- Gmsh 4.15.2 (ONELAB Windows bundle)
- GetDP 4.0.0-git-259f4c38
- Python 3.10 with NumPy and Matplotlib

## Files

- [cable_thermal.geo](./cable_thermal.geo): Q4.4 cable/seabed geometry, physical groups, and mesh fields.
- [cable_thermal.pro](./cable_thermal.pro): Onelab defaults for geometry, MQS, materials, and thermal boundaries; includes the coupled formulation.
- [thermal_formulation.pro](./thermal_formulation.pro): MQS and thermal groups, material functions, equations, coupled solve order, Joule source, and result exports.
- [Jacobian_Integration.pro](./Jacobian_Integration.pro): Jacobian and integration definitions included by the formulation.
- [plot_T.py](./plot_T.py): reads `res/T_cable.pos` and writes the zoomed `T_cable.png`.
- Q3 reference files: `cable_mag_q3.pro` (MQS model and excitation), `cable_geometry_q3.geo` / `cable_parameters_q3.geo` (Q3 geometry and parameters), and `cable_common_q3.pro` (older common electrical model). Their MQS data informed Q4.4; the current coupled implementation is in `thermal_formulation.pro`.
- `results.txt`: summary of the reported coupled-solve results.

## Reproduce the slide result

Run in PowerShell from this folder. The mesh defaults are `L=1 m`, `D=30 m`, `W=60 m`, `lc_cable=0.4 mm`, and `lc_far=1.5 m`. The solve uses 50 Hz, 385 A RMS per phase, solid sheath/armour bonding, `bottom_bc=1` (zero flux), and `sigma_Soil_mqs=0.01 S/m`. Other parameters use the defaults in `cable_thermal.pro`.

```powershell
$gmsh = 'C:\Users\Noah\Downloads\BURGI\NM\FE\onelab-Windows64real\onelab-Windows64real\gmsh.exe'
$getdp = 'C:\Users\Noah\Downloads\BURGI\NM\FE\onelab-Windows64real\onelab-Windows64real\getdp.exe'
$python = 'C:\Users\Noah\AppData\Local\Programs\Python\Python310\python.exe'
Set-Location 'C:\Users\Noah\Downloads\BURGI\NM\FE\Lab\NMES_2026\Noah\Q 4.4'
New-Item -ItemType Directory -Force .\res | Out-Null
& $gmsh .\cable_thermal.geo -2 -format msh2 -o .\cable_thermal.msh
& $getdp .\cable_thermal.pro -msh .\cable_thermal.msh -setnumber sigma_Soil_mqs 0.01 -setnumber bottom_bc 1 -solve Coupled -pos ThermalOutputs
& $python .\plot_T.py
```

GetDP writes the loss, temperature, and power tables plus `T_domain.pos` and `T_cable.pos` under `res/`; the Python command creates the cable zoom shown in the slide. The conductor/sheath placeholder power parameters are not used by the coupled Joule source.


| Result                            |                         Reproduced value |
| ----------------------------------- | -----------------------------------------: |
| Conductor losses                  |                            49.011611 W/m |
| Sheath losses                     |                             1.354085 W/m |
| Armour losses                     |                             2.927065 W/m |
| Other losses                      |                          0.000000153 W/m |
| Total losses /`P_in` / `P_out`    |                            53.292761 W/m |
| `T_cond_max` (A / B / C); hotspot | 59.217547 / 59.251610 / 59.253187 °C; C |
| `T_surface_max`                   |                            20.034043 °C |
| Relative power error              |                                 5.58e-12 |
| DoFs (MQS + thermal)              |                          64,960 + 32,649 |
