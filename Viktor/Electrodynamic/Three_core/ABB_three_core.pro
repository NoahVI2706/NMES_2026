// Grouping
Group {

  // Material regions
  Aluminium   = Region[1];
  InnerScreen = Region[2];
  XLPE        = Region[3];
  OuterScreen = Region[4];
  Lead        = Region[5];
  Cable       = Region[{InnerScreen, XLPE, OuterScreen}];

  // Computational domain
  Domain_Ele = Region[
    {InnerScreen, XLPE, OuterScreen}
  ];

  // High-voltage boundaries
  HV_A = Region[101];
  HV_B = Region[102];
  HV_C = Region[103];

  // Grounded boundaries
  Ground = Region[201];

}

// 2. Material properties
eps0 = 8.854187817e-12; // Vacuum permittivity [F/m]
DefineConstant[
  Freq = {50, Name "Excitation/Frequency [Hz]"},
  U_LL = {45000, Name "Excitation/Line voltage RMS [V]"},
  sigma_screen = {2, Name "Materials/Screen conductivity [S/m]"},
  sigma_XLPE = {1e-18, Name "Materials/XLPE conductivity [S/m]"},
  epsr_screen = {2.25, Name "Materials/Screen relative permittivity"},
  epsr_XLPE = {2.5, Name "Materials/XLPE relative permittivity"}
];

// Three-phase operating voltage
Vpeak = Sqrt[2/3] * U_LL;     // Phase-to-ground peak voltage [V]

// Use first-order nodal elements (in professors code)
Flag_Degree_v = 1;

Function {
  // Electrical conductivity [S/m]
  sigma[InnerScreen] = sigma_screen;
  sigma[XLPE]        = sigma_XLPE;
  sigma[OuterScreen] = sigma_screen;

  // Absolute permittivity [F/m]
  epsilon[InnerScreen] = epsr_screen * eps0;
  epsilon[XLPE]        = epsr_XLPE * eps0;
  epsilon[OuterScreen] = epsr_screen * eps0;
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
      // Phase B: -120 degrees
      { Region HV_B;
        Value Vpeak;
        TimeFunction F_Cos_wt_p[]{2*Pi*Freq, -2*Pi/3};
      }
      // Phase C: +120 degrees
      { Region HV_C;
        Value Vpeak;
        TimeFunction F_Cos_wt_p[]{2*Pi*Freq, 2*Pi/3};
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
