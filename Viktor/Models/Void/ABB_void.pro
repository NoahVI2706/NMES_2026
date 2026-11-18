// Grouping
Group {

  // Material regions
  Aluminium   = Region[1];
  InnerScreen = Region[2];
  XLPE        = Region[3];
  OuterScreen = Region[4];
  Lead        = Region[5];
  AirVoid     = Region[6];
  Cable       = Region[{InnerScreen, XLPE, OuterScreen}];

  // Computational domain
  // Solve electric potential only in XLPE
  Domain_Ele = Region[{XLPE, AirVoid}];

  // High-voltage boundaries
  HV_A = Region[101];

  // Grounded boundaries
  Ground = Region[201];
}

// 2. Material properties
eps0 = 8.854187817e-12; // Vacuum permittivity [F/m]
Freq = 50; // Frequency [Hz]

// Three-phase operating voltage
U_LL = 45000;                  // Line-to-line RMS voltage [V]
Vpeak = Sqrt[2/3] * U_LL;     // Phase-to-ground peak voltage [V]

// Use first-order nodal elements (in professors code)
Flag_Degree_v = 1;

Function {
  // Electrical conductivity [S/m]
  sigma[InnerScreen] = 2;
  sigma[XLPE]        = 1e-18;
  sigma[OuterScreen] = 2;
  sigma[AirVoid]     = 1e-15;

  // Absolute permittivity [F/m]
  epsilon[InnerScreen] = 2.25 * eps0;
  epsilon[XLPE]        = 2.5 * eps0;
  epsilon[OuterScreen] = 2.25 * eps0;
  epsilon[AirVoid]     = 1.0 * eps0;
}

// 3. Electric potential boundary conditions
Constraint {
  { Name ElectricScalarPotential; Type Assign;
    Case {
      // Phase A: 0 degrees
      { Region HV_A;
        Value Vpeak;
        TimeFunction F_Cos_wt_p[]{2*Pi*Freq, 0};
      }
      // All three grounded screens
      { Region Ground; Value 0; }
    }
  }
}


//////////////////////////////////////////////////
// 4. FEM formulation and numerical integration
//////////////////////////////////////////////////

Include "Jacobian_Integration.pro";

Include "electrodynamic_three_core.pro";
