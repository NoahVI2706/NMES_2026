// Q3.4 geometry simplification: equivalent mu_r=1, J=0 insulation.
// All metal regions, currents, constraints and loss calculations unchanged.
// ================================================================
// Q3 - MAGNETOQUASISTATIC MODEL (GetDP)
// Mesh: cable_magnetic_simplified.msh, generated from cable_magnetic_simplified.geo
// Length unit in mesh: METRES (Mesh.ScalingFactor = 0.001).
// Convention: x(t) = Re[x_peak * exp(i*omega*t)]
// ================================================================

DefineConstant[
  Freq = {50, Name "Magnetic/Excitation/Frequency [Hz]"},
  I_rms = {385, Name "Magnetic/Excitation/Current per phase RMS [A]"},
  // 1 = uniform imposed J, 2 = massive conductor (skin/proximity effect)
  Flag_Conductor = {1, Name "Magnetic/Model/Conductor (1 stranded, 2 massive)"},
  // 1 = bonded at both ends, 2 = zero net current in each sheath/armour
  Flag_Bonding = {1, Name "Magnetic/Model/Bonding (1 solid, 2 single point)"},
  Flag_BC = {0, Name "Magnetic/Model/Outer BC (0 Dirichlet, 1 asymptotic)"},
  Flag_Degree_a = {1, Name "Magnetic/Model/FE degree (1 or 2)"},
  m_asym = {1, Name "Magnetic/Model/Asymptotic harmonic order"},

  sigma_Al = {3.77e7, Name "Magnetic/Materials/Aluminium conductivity [S/m]"},
  alpha_Al = {0.0039, Name "Magnetic/Materials/Aluminium alpha [1/K]"},
  Theta_Al = {20, Name "Magnetic/Materials/Aluminium temperature [C]"},
  sigma_Lead = {4.55e6, Name "Magnetic/Materials/Lead conductivity [S/m]"},
  sigma_Steel = {4.7e6, Name "Magnetic/Materials/Armour conductivity [S/m]"},
  mur_Steel = {4, Name "Magnetic/Materials/Armour relative permeability"},
  sigma_Soil = {0.01, Name "Magnetic/Materials/Soil conductivity [S/m]"},
  // The two geometric values below are shared by ONELAB with .geo.
  r_cond = {9.05, Name "Geometry/r_cond [mm]"},
  r_soil = {620, Name "Geometry/r_soil [mm]"}
];

mu0 = 4e-7*Pi;
omega = 2*Pi*Freq;
Ipeak = Sqrt[2]*I_rms;
R_trunc = r_soil*1e-3;

Group {
  // These numbers are the Physical Surface tags in cable_magnetic.geo.
  Al_A = Region[1]; Al_B = Region[2]; Al_C = Region[3];
  Aluminium = Region[{Al_A, Al_B, Al_C}];
  EquivalentInsulation = Region[{4, 5, 6}]; // merged XLPE + two screens
  Lead_A = Region[13]; Lead_B = Region[14]; Lead_C = Region[15];
  Lead = Region[{Lead_A, Lead_B, Lead_C}];
  Filling = Region[16]; Steel = Region[17]; OuterJacket = Region[18];
  Soil = Region[19]; OuterBC = Region[20];

  Domain_Mag = Region[{Aluminium, EquivalentInsulation,
                       Lead, Filling, Steel, OuterJacket, Soil}];

  // Massive conductors have J = -sigma (i*omega*a + grad(v)).
  DomainC_Mag = Region[{Lead, Steel, Soil}];
  If(Flag_Conductor == 2)
    DomainC_Mag += Region[{Aluminium}];
  EndIf

  // Stranded conductors: uniform imposed J = I_k/A.
  If(Flag_Conductor == 1)
    DomainS_Mag = Region[{Aluminium}];
  Else
    DomainS_Mag = Region[{}];
  EndIf
  DomainS0_Mag = Region[{}];

  // Regions with specified net current (instead of specified voltage).
  DomainCWithI_Mag = Region[{Soil}];
  If(Flag_Conductor == 2)
    DomainCWithI_Mag += Region[{Aluminium}];
  EndIf
  If(Flag_Bonding == 2)
    DomainCWithI_Mag += Region[{Lead, Steel}];
  EndIf
}

Function {
  sigma[Aluminium] = sigma_Al/(1+alpha_Al*(Theta_Al-20));
  sigma[Lead] = sigma_Lead;
  sigma[Steel] = sigma_Steel;
  sigma[Soil] = sigma_Soil;

  nu[Region[{Aluminium, EquivalentInsulation,
             Lead, Filling, OuterJacket, Soil}]] = 1/mu0;
  nu[Steel] = 1/(mu0*mur_Steel);

  // Needed by the existing GetDP stranded-conductor formulation.
  Ns[] = 1;
  Sc[] = Pi*(r_cond*1e-3)^2;
  js0[] = 0;
}

Constraint {
  { Name MagneticVectorPotential_2D; Type Assign;
    Case {
      If(Flag_BC == 0)
        { Region OuterBC; Value 0; }  // a_z=0 at the outer boundary
      EndIf
    }
  }

  { Name Current_2D; Type Assign;
    Case {
      // Three PEAK current phasors; imposed uniformly if stranded,
      // or as global integrated current if massive.
      { Region Al_A; Value Ipeak; }
      { Region Al_B; Value Ipeak*Complex[Cos[-2*Pi/3],Sin[-2*Pi/3]]; }
      { Region Al_C; Value Ipeak*Complex[Cos[ 2*Pi/3],Sin[ 2*Pi/3]]; }

      { Region Soil; Value 0; }  // no externally supplied longitudinal soil current
      If(Flag_Bonding == 2)
        // Each sheath is constrained independently, not only their sum.
        { Region Lead_A; Value 0; }
        { Region Lead_B; Value 0; }
        { Region Lead_C; Value 0; }
        { Region Steel; Value 0; }
      EndIf
    }
  }

  { Name Voltage_2D; Type Assign;
    Case {
      If(Flag_Bonding == 1)
        // Ideal solid bonding: zero axial voltage gradient.
        { Region Lead_A; Value 0; }
        { Region Lead_B; Value 0; }
        { Region Lead_C; Value 0; }
        { Region Steel; Value 0; }
      EndIf
    }
  }
}

Include "Jacobian_Integration.pro";
Include "magnetodynamic_formulation.pro";
