// Electrodynamic model for the parameterized cable cross-section.

DefineConstant[
  NumberOfCores = {3, Name "Geometry/Number of cores", Min 1, Max 3, Step 2},
  ElecFrequency = {50, Name "Excitation/Frequency [Hz]"},
  Flag_Degree_v = {1, Name "Solver/Element degree", Choices {1,2}},
  V0 = {25980.762, Name "Post-processing/Reference phase voltage [V]"},
  Pa = {0, Name "Post-processing/Phase A angle [rad]"},
  Pb = {2*Pi/3, Name "Post-processing/Phase B angle [rad]"},
  Pc = {4*Pi/3, Name "Post-processing/Phase C angle [rad]"},
  UPhase = {25980.762, Name "Excitation/Phase voltage RMS [V]"},
  dc = {18.1e-3, Name "Geometry/Conductor diameter [m]"},
  ti = {0.5e-3, Name "Geometry/Inner screen thickness [m]"},
  txlpe = {8.0e-3, Name "Geometry/XLPE insulation thickness [m]"},
  to = {0.5e-3, Name "Geometry/Outer screen thickness [m]"},
  tapl = {1.5e-3, Name "Geometry/Lead sheath thickness [m]"},
  tps = {1.0e-3, Name "Geometry/Inter-core separation allowance [m]"},
  V1 = {UPhase, Name "Excitation/Core 1 voltage [V]"},
  V2 = {UPhase, Name "Excitation/Core 2 voltage [V]"},
  V3 = {UPhase, Name "Excitation/Core 3 voltage [V]"},

  SigmaConductor = {3.5e7, Name "Materials/Aluminium conductivity [S/m]"},
  SigmaInnerScreen = {1.0e6, Name "Materials/Inner screen conductivity [S/m]"},
  SigmaXLPE = {1.0e-15, Name "Materials/XLPE conductivity [S/m]"},
  SigmaOuterScreen = {1.0e6, Name "Materials/Outer screen conductivity [S/m]"},
  SigmaLead = {4.8e6, Name "Materials/Lead conductivity [S/m]"},
  EpsilonRConductor = {1, Name "Materials/Aluminium relative permittivity"},
  EpsilonRInnerScreen = {1, Name "Materials/Inner screen relative permittivity"},
  EpsilonRXLPE = {2.3, Name "Materials/XLPE relative permittivity"},
  EpsilonROuterScreen = {1, Name "Materials/Outer screen relative permittivity"},
  EpsilonRLead = {1, Name "Materials/Lead relative permittivity"}
];

Freq = ElecFrequency;

Group {
  Conductor = Region[1001];
  InnerScreen = Region[1002];
  XLPE = Region[1003];
  OuterScreen = Region[1004];
  LeadSheath = Region[1005];
  ConductorBoundary1 = Region[1101];
  ConductorBoundary2 = Region[1102];
  ConductorBoundary3 = Region[1103];
  SheathBoundary = Region[1105];
  Cable = Region[{Conductor,InnerScreen,XLPE,OuterScreen,LeadSheath}];
  Domain_Ele = Region[{Conductor,InnerScreen,XLPE,OuterScreen,LeadSheath}];
  DomainDummy = Region[LeadSheath];
  Ind_1 = Region[Conductor];
  If (NumberOfCores > 1)
    Ind_2 = Region[Conductor];
    Ind_3 = Region[Conductor];
  EndIf
}

Function {
  sigma[Conductor] = SigmaConductor;
  sigma[InnerScreen] = SigmaInnerScreen;
  sigma[XLPE] = SigmaXLPE;
  sigma[OuterScreen] = SigmaOuterScreen;
  sigma[LeadSheath] = SigmaLead;

  epsilon[Conductor] = EpsilonRConductor * 8.8541878128e-12;
  epsilon[InnerScreen] = EpsilonRInnerScreen * 8.8541878128e-12;
  epsilon[XLPE] = EpsilonRXLPE * 8.8541878128e-12;
  epsilon[OuterScreen] = EpsilonROuterScreen * 8.8541878128e-12;
  epsilon[LeadSheath] = EpsilonRLead * 8.8541878128e-12;
}

Constraint {
  { Name ElectricScalarPotential;
    Case {
      { Region ConductorBoundary1; Value V1; }
      If (NumberOfCores > 1)
        { Region ConductorBoundary2; Value V2; }
        { Region ConductorBoundary3; Value V3; }
      EndIf
      { Region SheathBoundary; Value 0; }
    }
  }
}

Include "Jacobian_Integration.pro";
Include "electrodynamic_formulation(1).pro";
