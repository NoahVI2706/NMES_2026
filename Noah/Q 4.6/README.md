# Q4.6 coupled MQS-thermal result

## Tools

- Gmsh 4.15.2 (ONELAB Windows bundle)
- GetDP 4.0.0-git-259f4c38

## Files

- `cable_thermal.geo`: cable/seabed geometry, physical groups, and mesh fields.
- `cable_thermal.pro`: Onelab parameters for MQS, thermal materials, and boundary conditions; includes the formulation.
- `thermal_formulation.pro`: coupled MQS and thermal equations, Joule heating, and result exports.
- `Jacobian_Integration.pro`: Jacobians and integration rules included by the formulation.
- `results.txt`: reported regional losses, per-core conductor maxima, and total input/output power.
- `res/`: GetDP solution files, temperature maps, and detailed power/temperature outputs.

## Reproduce the result

Run these commands in PowerShell from this folder. They reproduce the mesh and the single coupled solve using the Q4.6 parameter values:

```powershell
$gmsh = 'C:\Users\Noah\Downloads\BURGI\NM\FE\onelab-Windows64real\onelab-Windows64real\gmsh.exe'
$getdp = 'C:\Users\Noah\Downloads\BURGI\NM\FE\onelab-Windows64real\onelab-Windows64real\getdp.exe'
Set-Location 'C:\Users\Noah\Downloads\BURGI\NM\FE\Lab\NMES_2026\Noah\Q 4.6'
& $gmsh .\cable_thermal.geo -2 -format msh2 -o .\cable_thermal.msh -v 1
& $getdp .\cable_thermal.pro -msh .\cable_thermal.msh -setnumber sigma_conductor 2.4425e7 -setnumber kappa_xlpe 0.2857 -setnumber kappa_filler 0.1667 -setnumber kappa_polyethylene 0.2857 -setnumber sigma_Soil_mqs 0.01 -setnumber bottom_bc 1 -solve Coupled -pos ThermalOutputs -v 5
```

The specified conductor conductivity is used directly as the effective aluminium conductivity. Other model settings retain Q4.4 values; the prior Q4.4 run used `sigma_Soil_mqs=0.01 S/m`.
