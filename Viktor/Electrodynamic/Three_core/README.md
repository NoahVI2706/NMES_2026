# Three_core: Q2 electrodynamic screening model

## Purpose
Three screened phase cores, finite-conductivity semiconducting layers (Model A, Q2.2).
The conductors and lead sheaths are represented as boundaries, not elements in the solved region. Only the inner screen, XLPE and outer screen are solved. Fixed 45 kV line-to-line RMS, 50 Hz and 1 mm maximum mesh size are the defaults.

## Files
- `ABB_three_core.geo`: cable geometry, Physical Surfaces/Curves and mesh control.
- `ABB_three_core.pro`: material functions, excitation, potential boundary conditions and ONELAB parameters.
- `electrodynamic_three_core.pro`: shared electroquasistatic weak formulation and map export (identical in these two folders).
- `Jacobian_Integration.pro`: integration and Jacobian definitions.

## Reproduce (PowerShell, launched from this folder)
Replace the two executable paths with local installation paths. In Windows PowerShell:

```powershell
$gmsh = 'C:\Users\Vikto\Downloads\gmsh-4.15.2-Windows64\gmsh-4.15.2-Windows64\gmsh.exe'
$getdp = 'C:\Users\Vikto\Downloads\getdp-3.5.0-Windows64\getdp.exe'
& $gmsh .\ABB_three_core.geo -2 -format msh2 -o .\ABB_three_core.msh
& $getdp .\ABB_three_core.pro -msh .\ABB_three_core.msh -solve Electrodynamics
```

The calculation creates `res/potential.pos` and `res/electric_field.pos` plus GetDP solution files. The formulation currently **does not export** capacitance, mesh degrees of freedom or current-density maps; the Q2.3 result table is from a separate study and requires its own documented workflow.

## Parameters and assumptions
- Peak phase-to-ground voltage is `sqrt(2/3) * U_LL`.
- Phase(s) at 0°, -120° and +120°; outer screen/lead interface is grounded at 0 V.
- Outer screen radius = 18.75 mm and outer lead radius = 20.25 mm, as in this source. **These values differ slightly from the later MQS geometry** (18.85 and 20.35 mm); preserve baseline values until the discrepancy is assessed.
- `Coherence` makes coincident interfaces conforming after Boolean operations.
- Re-run mesh and solver after changing an ONELAB parameter. Any mesh-size sweep requires re-meshing.

## Validation still required
Gmsh/GetDP executable integration has not been tested in this audit environment. Run the commands above once after the change and compare with your original results before replacing the originals.
