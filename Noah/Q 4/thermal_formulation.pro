Include "Jacobian_Integration.pro";

Group {
  Aluminium = Region[1];
  InnerScreen = Region[2];
  XLPE = Region[3];
  OuterScreen = Region[4];
  Lead = Region[5];
  Filler = Region[6];
  Steel = Region[7];
  Polyethylene = Region[8];
  Seabed = Region[9];
  Domain = Region[{Aluminium,InnerScreen,XLPE,OuterScreen,Lead,Filler,Steel,Polyethylene,Seabed}];
  Cable = Region[{Aluminium,InnerScreen,XLPE,OuterScreen,Lead,Filler,Steel,Polyethylene}];
  Gamma_surface = Region[101];
  Gamma_bottom = Region[102];
  Gamma_left = Region[103];
  Gamma_right = Region[104];
}

Function {
  kappa[Aluminium] = kappa_aluminium;
  kappa[InnerScreen] = kappa_semiconductor;
  kappa[XLPE] = kappa_xlpe;
  kappa[OuterScreen] = kappa_semiconductor;
  kappa[Lead] = kappa_lead;
  kappa[Filler] = kappa_filler;
  kappa[Steel] = kappa_steel;
  kappa[Polyethylene] = kappa_polyethylene;
  kappa[Seabed] = kappa_seabed;

  // ONE source function. Later replace these expressions by
  // 0.5*|j|^2/sigma with <a>[ ... ] in the conductor and lead regions.
  Q[Aluminium] = P_cond_per_core/(Pi*r_conductor*r_conductor);
  Q[Lead] = P_sheath_per_core/(Pi*(r_lead*r_lead-r_outerScreen*r_outerScreen));
  Q[] = 0;
}

Constraint {
  { Name TemperatureNatural; Type Assign;
    Case {}
  }
}
If (bottom == 0)
  Constraint {
    { Name Temperature; Type Assign;
      Case {
        { Region Gamma_bottom; Value T_amb; }
      }
    }
  }
EndIf

FunctionSpace {
  { Name Hgrad_T; Type Form0;
    BasisFunction {
      { Name sn; NameOfCoef tn; Function BF_Node;
        Support Domain; Entity NodesOf[All]; }
    }
    Constraint {
      If (bottom == 0)
        { NameOfCoef tn; EntityType NodesOf;
          NameOfConstraint Temperature; }
      Else
        { NameOfCoef tn; EntityType NodesOf;
          NameOfConstraint TemperatureNatural; }
      EndIf
    }
  }
}

Formulation {
  { Name ThermalSteady; Type FemEquation;
    Quantity {
      { Name T; Type Local; NameOfSpace Hgrad_T; }
    }
    Equation {
      Galerkin { [ kappa[]*Dof{d T},{d T} ];
        In Domain; Jacobian Vol; Integration I1; }
      Galerkin { [ h*Dof{T},{T} ];
        In Gamma_surface; Jacobian Sur; Integration I1; }
      Galerkin { [ -h*T_amb,{T} ];
        In Gamma_surface; Jacobian Sur; Integration I1; }
      Galerkin { [ -Q[],{T} ];
        In Domain; Jacobian Vol; Integration I1; }
    }
  }
}

Resolution {
  { Name Thermal;
    System {
      { Name Sys_T; NameOfFormulation ThermalSteady; Type FemEquation; }
    }
    Operation {
      Generate[Sys_T]; Solve[Sys_T];
      SaveSolution[Sys_T];
    }
  }
}

PostProcessing {
  { Name ThermalPost; NameOfFormulation ThermalSteady;
    Quantity {
      { Name T; Value { Term { [ {T} ]; In Domain; Jacobian Vol; } } }
      { Name P_in; Value { Integral { [ Q[] ]; In Cable; Jacobian Vol; Integration I1; } } }
      { Name P_out; Value { Integral { [ h*({T}-T_amb) ]; In Gamma_surface; Jacobian Sur; Integration I1; } } }
    }
  }
}

PostOperation {
  { Name ThermalOutputs; NameOfPostProcessing ThermalPost;
    Operation {
      Print[ T, OnElementsOf Domain, File "res/T_domain.pos" ];
      Print[ T, OnElementsOf Cable, File "res/T_cable.pos" ];
      Print[ P_in, OnGlobal, Format Table, File "res/P_in.txt" ];
      Print[ P_out, OnGlobal, Format Table, File "res/P_out.txt" ];
      Print[ T, OnElementsOf Aluminium, Format Table, File "res/T_cond_elements.txt" ];
      Print[ T, OnElementsOf Gamma_surface, Format Table, File "res/T_surface_elements.txt" ];
      Print[ T, OnPoint {{x_A,-L+y_A0,0} {x_B,-L+y_B0,0} {x_C,-L+y_C0,0}},
        Format Table, File "res/T_cond_points.txt" ];
      Print[ T, OnPoint {{0,0,0}}, Format Table, File "res/T_surface_point.txt" ];
    }
  }
}
