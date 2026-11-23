# Three-core cable thermal model

Run from this directory.

```powershell
mkdir res -Force
gmsh -2 cable_thermal.geo -o cable_thermal.msh
getdp cable_thermal.pro -solve Thermal -pos ThermalOutputs
```

The bottom boundary defaults to zero flux (`bottom=1`). To solve with
Dirichlet T=T_amb, use:

```powershell
getdp cable_thermal.pro -setnumber bottom 0 -solve Thermal -pos ThermalOutputs
```

Mesh/solve with the GUI:

```text
gmsh cable_thermal.geo
getdp cable_thermal.pro -solve Thermal -pos ThermalOutputs
```

Outputs:

- `res/T_domain.pos`: temperature map for the full seabed.
- `res/T_cable.pos`: temperature map for cable regions.
- `res/P_in.txt`: placeholder volume-source power.
- `res/P_out.txt`: surface convection power.
- `res/T_cond_elements.txt`: sampled conductor-element temperatures.
- `res/T_surface_elements.txt`: sampled seabed-surface temperatures.
- `res/T_cond_points.txt`: temperature at all three conductor centres.
- `res/T_surface_point.txt`: temperature at (0,0) on the seabed surface.

Compute the conductor maximum and power balance with Python:

```powershell
python -c "import re; vals=lambda f:[float(v) for v in re.findall(r'[-+]?(?:\d+\.\d*|\d*\.\d+|\d+)(?:[Ee][-+]?\d+)?',open(f).read())]; tc=max(vals('res/T_cond_points.txt')); ts=vals('res/T_surface_point.txt')[0]; pin=vals('res/P_in.txt')[-1]; pout=vals('res/P_out.txt')[-1]; print(f'T_cond_max={tc:.6g} C'); print(f'T_surface={ts:.6g} C'); print(f'P_in={pin:.6g} W/m'); print(f'P_out={pout:.6g} W/m'); print(f'relative balance={(abs(pout-pin)/pin):.3e}')"
```

`P_in.txt` and `P_out.txt` are GetDP global table outputs. The
acceptance power balance is `|P_out-P_in|/P_in`.
