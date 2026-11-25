// ============================================================
// Per-core lead sheath version – cable_common.pro
// Version: V1.3 (= V1.2 + one-core variant: Flag_Simplify = 3, Core_Sel)
// ============================================================

DefineConstant[
  Freq          = {50.0,    Name "Cable/Excitation/Freq"},
  V_peak        = {36742.3, Name "Cable/Excitation/V_peak"},

  // Aluminium conductor (matches Q1 table)
  sigma_Al      = {3.8e7,   Name "Cable/Materials/Aluminium/sigma"},
  A_cond_Al     = {240.0,   Name "Cable/Materials/Aluminium/metal area [mm2]"},
  epsilon_r_Al  = {1.0,     Name "Cable/Materials/Aluminium/epsilon_r"},

  sigma_XLPE    = {1e-18,   Name "Cable/Materials/XLPE/sigma"},
  epsilon_r_XLPE= {2.5,     Name "Cable/Materials/XLPE/epsilon_r"},

  sigma_Semi    = {2.0,     Name "Cable/Materials/Semicon/sigma"},
  epsilon_r_Semi= {2.25,    Name "Cable/Materials/Semicon/epsilon_r"},

  sigma_Lead    = {4.55e6,  Name "Cable/Materials/Lead/sigma"},
  epsilon_r_Lead= {1.0,     Name "Cable/Materials/Lead/epsilon_r"},

  sigma_Fill    = {1e-10,   Name "Cable/Materials/Filling/sigma"},
  epsilon_r_Fill= {2.5,     Name "Cable/Materials/Filling/epsilon_r"},

  sigma_Armour  = {4.5e6,   Name "Cable/Materials/Armour/sigma"},
  epsilon_r_Armour = {1.0,  Name "Cable/Materials/Armour/epsilon_r"},

  sigma_Outer   = {1e-18,   Name "Cable/Materials/Outer/sigma"},
  epsilon_r_Outer = {2.3,   Name "Cable/Materials/Outer/epsilon_r"},

  sigma_Soil    = {0.01,     Name "Cable/Materials/Soil/sigma"},
  epsilon_r_Soil= {10.0,    Name "Cable/Materials/Soil/epsilon_r"},

  // Shared geometry (needed for the cut)
  d_trefoil     = {41.2,    Name "Geometry/d_trefoil [mm]"},
  r_lead        = {20.35,   Name "Geometry/r_lead [mm]"}
];
DefineConstant[ Flag_Simplify = {0, Name "Cable/Simplification (0 full, 1 cores only, 2 cores + grounded outer semicon, 3 one core only)"} ];
DefineConstant[ Core_Sel = {3, Name "Cable/One-core variant: core kept (1=A, 2=B, 3=C)"} ];   // NEW: used only when Flag_Simplify == 3
N_energized = (Flag_Simplify == 3) ? 1 : 3;   // NEW: number of energised cores, used in C = 2W/(N |V|^2)

DefineConstant[
  Flag_Defect    = {0,     Name "Defect/Enable (0 off, 1 on)"},
  sigma_Void     = {1e-15, Name "Cable/Materials/Void/sigma"},
  epsilon_r_Void = {1.0,   Name "Cable/Materials/Void/epsilon_r"}
];
Flag_Degree_v = 1;
V0 = V_peak;
Pa = 0.0;
Pb = -2*Pi/3;
Pc =  2*Pi/3;

// Cut coordinates for core C (lower-right), in metres
x2    = 0.5 * d_trefoil * 1e-3;
y2    = -d_trefoil / (2 * Sqrt[3]) * 1e-3;
r_cut = r_lead * 1e-3 - 1e-6;

// Cut-line variables (m): dc + 2(ti+txlpe+to+tapl) + tps = 40 mm = d_trefoil
dc = 0.0181;  ti = 0.0006;  txlpe = 0.008;  to = 0.0006;  tapl = 0.0015;  tps = 0.0005;

Group {
  Ind_1 = Region[ 1 ];  Ind_2 = Region[ 2 ];  Ind_3 = Region[ 3 ];
  XLPE_A = Region[ 4 ]; XLPE_B = Region[ 5 ]; XLPE_C = Region[ 6 ];
  SemiIn  = Region[ {7, 8, 9} ];
  SemiOut = Region[ {10, 11, 12} ];
  Lead    = Region[ {13, 14, 15} ];
  Filling = Region[ 16 ];
  Armour  = Region[ 17 ];
  Outer   = Region[ 18 ];
  Soil    = Region[ 19 ];
  OuterBC = Region[ 20 ];
  
  If(Flag_Defect)
    Void = Region[21];
  Else
    Void = Region[{}];
  EndIf

  If(Flag_Simplify == 0)
    Cable = Region[ {Ind_1, Ind_2, Ind_3, XLPE_A, XLPE_B, XLPE_C,
                     SemiIn, SemiOut, Lead, Filling, Armour, Outer, Void} ];
    Domain_Ele = Region[ {Cable, Soil} ];
  ElseIf(Flag_Simplify == 1)
    Cable = Region[ {Ind_1, Ind_2, Ind_3, XLPE_A, XLPE_B, XLPE_C, SemiIn, SemiOut, Lead, Void} ];
    Domain_Ele = Region[ Cable ];
  ElseIf(Flag_Simplify == 2)
    Cable = Region[ {Ind_1, Ind_2, Ind_3, XLPE_A, XLPE_B, XLPE_C, SemiIn, SemiOut, Void} ];
    Domain_Ele = Region[ Cable ];
  ElseIf(Flag_Simplify == 3)   // NEW: one core (conductor, inner semi, XLPE, outer semi, lead) selected by Core_Sel
    Ind_Keep  = Region[ Core_Sel ];
    Cable = Region[ {Ind_Keep, (3+Core_Sel), (6+Core_Sel), (9+Core_Sel), (12+Core_Sel), Void} ];
    Lead_Keep = Region[ (12+Core_Sel) ];
    Domain_Ele = Region[ Cable ];
  EndIf
  DomainDummy = Region[ 1 ];
}

Function {
  eps0 = 8.8541878128e-12;

  sigma_Al_eff = sigma_Al*A_cond_Al/(Pi*9.05^2);
  sigma[Region[{Ind_1,Ind_2,Ind_3}]]    = sigma_Al_eff;
  epsilon[Region[{Ind_1,Ind_2,Ind_3}]]  = epsilon_r_Al * eps0;

  sigma[Region[{XLPE_A,XLPE_B,XLPE_C}]]   = sigma_XLPE;
  epsilon[Region[{XLPE_A,XLPE_B,XLPE_C}]] = epsilon_r_XLPE * eps0;

  sigma[SemiIn]    = sigma_Semi;    epsilon[SemiIn]    = epsilon_r_Semi * eps0;
  sigma[SemiOut]   = sigma_Semi;    epsilon[SemiOut]   = epsilon_r_Semi * eps0;

  sigma[Lead]      = sigma_Lead;    epsilon[Lead]      = epsilon_r_Lead * eps0;
  sigma[Filling]   = sigma_Fill;    epsilon[Filling]   = epsilon_r_Fill * eps0;
  sigma[Armour]    = sigma_Armour;  epsilon[Armour]    = epsilon_r_Armour * eps0;
  sigma[Outer]     = sigma_Outer;   epsilon[Outer]     = epsilon_r_Outer * eps0;
  sigma[Soil]      = sigma_Soil;    epsilon[Soil]      = epsilon_r_Soil * eps0;
  If(Flag_Defect)
    sigma[Void] = sigma_Void;  epsilon[Void] = epsilon_r_Void * eps0;
  EndIf
}

Constraint {
  { Name ElectricScalarPotential; Type Assign;
    Case {
      { Region Ind_1; Value V_peak * Complex[Cos[Pa], Sin[Pa]]; }
      { Region Ind_2; Value V_peak * Complex[Cos[Pb], Sin[Pb]]; }
      { Region Ind_3; Value V_peak * Complex[Cos[Pc], Sin[Pc]]; }
      If(Flag_Simplify == 0)
        { Region Lead;    Value 0.0; }
        { Region OuterBC; Value 0.0; }
      ElseIf(Flag_Simplify == 1)
        { Region Lead;    Value 0.0; }
      ElseIf(Flag_Simplify == 2)
        { Region SemiOut; Value 0.0; }
      ElseIf(Flag_Simplify == 3)   // NEW: only the kept core's sheath is grounded
        { Region Lead_Keep; Value 0.0; }
      EndIf
    }
  }
}

Include "Jacobian_Integration.pro"
Include "electrodynamic_formulation.pro"