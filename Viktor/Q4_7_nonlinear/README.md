# Q4.7–Q4.9 nonlinear electrothermal study

This folder is **separate from the Q4.4/Q4.6 linear model**. It starts from the latest supplied Q4.6 source geometry/formulation but resets the parameters to the agreed Q4.4 **linear reference**. Do not mix its outputs with the prior Q4.6 modified-property sensitivity case.

## Files

- `cable_thermal.geo`: original full three-core thermal mesh geometry, unchanged.
- `cable_thermal.pro`: same FEM model, with Q4.4 reference defaults (see below).
- `thermal_formulation.pro`: original sequential MQS + thermal problem, with **post-processing only** extended to output B and J field maps. The underlying governing equations are unchanged.
- `Jacobian_Integration.pro`: unchanged.
- `run_nonlinear.py`: external automated fixed-point iteration with a small mesh-sensitivity study; no external Python dependencies for the calculations, matplotlib optional for plots.

## Reference material and boundary settings

- 385 A RMS, 50 Hz, stranded phase currents; solid-bonded lead and armour.
- effective aluminium conductivity at 20 °C: **3.51646e7 S/m** (the user's Q4.4 reference, scaled for conductor area).
- aluminium resistivity coefficient: **alpha = 0.00390 K^-1**, with sigma(T) = sigma20/[1 + alpha(T-20 °C)].
- XLPE conductivity 0.46 W/(m K); filler 0.40 W/(m K); outer polyethylene 0.46 W/(m K). These remain constant.
- 20 °C ambient, h=500 W/(m² K), seabed thermal conductivity 1 W/(m K), soil electrical conductivity 0.01 S/m.
- 60 m × 30 m thermal domain, cable axis depth 1 m, **Dirichlet T=20 °C at bottom (`bottom_bc=0`)**; convection at top; sides insulated.

## Running on Windows

Make sure Python >= 3.9 is installed. In PowerShell, from this folder:

```powershell
python .\run_nonlinear.py --gmsh "C:\path\to\gmsh.exe" --getdp "C:\path\to\getdp.exe"
```

The paths should be the real paths from your ONELAB Windows bundle. Use quotes. The default run performs **both a 1.0 mm and 0.5 mm** mesh study, automatically, without changing parameters manually. First you may test just the coarser case:

```powershell
python .\run_nonlinear.py --gmsh "C:\path\to\gmsh.exe" --getdp "C:\path\to\getdp.exe" --meshes 1.0
```

Optional finer convergence test (more expensive):

```powershell
python .\run_nonlinear.py --gmsh "C:\path\to\gmsh.exe" --getdp "C:\path\to\getdp.exe" --meshes 1.0 0.5 0.25
```

The Python script will create/reuse `res/` for each GetDP iteration, but make **copies of baseline and final outputs** under `outputs/mesh_Xmm/`. It regenerates the mesh only once for each requested mesh size, then repeats the electromagnetic + thermal solves for each updated conductivity. Each mesh starts from sigma20.

## Numerical procedure

1. Fix sigma = sigma20 for iteration 0 and solve MQS followed by thermal.
2. Read `res/T_cable.pos` and compute the **area-weighted mean temperature of each conductor** from nodal FE temperatures and triangle areas.
3. Since the existing GetDP model has **one shared aluminium conductivity**, use the mean of the three core mean temperatures to update this one value: `sigma_next = sigma20/[1 + alpha*(mean(T_A,T_B,T_C)-20)]`.
4. Recompute MQS and thermal with the new scalar sigma.
5. Stop when `max(|T_A(k)-T_A(k-1)|, |T_B(k)-T_B(k-1)|, |T_C(k)-T_C(k-1)|) / max(1 K, max(T_i(k)+273.15 K)) < 1e-6`.

**Important modelling qualification:** This is temperature-dependent *shared* effective conductor conductivity, not a per-element locally temperature-dependent material law. It is a good controlled extension of the team's current **uniform stranded-conductor** model, particularly because the three core temperatures differ very little. For a fully spatially nonlinear sigma(T), the GetDP formulation would need additional coefficient/mapping changes. The driver logs individual core averages and maxima so this approximation can be checked.

An extra GetDP process is run for each iteration — the algorithm cannot physically update losses without recalculating the EM field — but the entire sweep is automatic. `lc_cable` controls the cable mesh; distant soil is progressively coarsened as in the original geometry.

## Output files and use on your slides

- `outputs/mesh_Xmm/iterations.csv`: for slide 2 (iteration table) and slide 3 (convergence values).
- `outputs/all_iterations.csv`: all mesh sizes combined.
- `outputs/convergence.png`: semilog relative increment vs iteration (slide 3); generated if matplotlib installed.
- `outputs/temperature_iteration.png`: temperature vs iteration (use on slide 3 or 4).
- `outputs/mesh_summary.csv`: mesh density, iteration count, linear/nonlinear maximum T, total losses and effective AC resistance (slides 5 and 6).
- `outputs/mesh_Xmm/linear_reference/` and `outputs/mesh_Xmm/nonlinear_final/`: source `.pos` maps for linear/nonlinear comparisons in Q4.8, plus numerical loss exports. `T_cable.pos`, `T_domain.pos`, `B_magnitude.pos`, `J_magnitude.pos` are suitable for Gmsh figure exports.
- `outputs/mesh_Xmm/getdp_iter_XX.log` and `gmsh.log`: reproducibility and troubleshooting.

Current `P_out.txt` integrates **top convective heat only**. It does NOT include heat passing through the Dirichlet bottom boundary. Therefore, do not use `P_in-P_out` as a global heat-balance error for this model without also accounting for bottom flux. `P_in` is total generated Joule heat per unit cable length.

## Limitations / verification required

- The Gmsh/GetDP binaries are not installed in the preparation environment, so **the actual mesh, GetDP formulation and post-processing have not been run**. The first 1.0-mm test should be used to validate the model; compare iteration 0 against the Q4.4 reference (~59.23 °C for the chosen reference mesh/BC, ~53.293 W/m total losses).
- Q4.8 also asks about **inductance**. The team's latest Q4.6 thermal formulation does not currently export phase impedance/inductance. Do not invent this value. If needed, a consistent impedance extraction needs to be implemented after the nonlinear temperature/loss loop is verified.
- Thermal conductivity is deliberately held constant. The older Q4.6 changed-property case with 87.7 °C is NOT part of this study.
- A true convergence rate/iteration count may vary with mesh size and numerical settings. Check `converged=True` in `mesh_summary.csv` before using the results.
