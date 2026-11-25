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
  Gamma_surface = Region[301];
  Gamma_bottom = Region[302];
  Gamma_left = Region[303];
  Gamma_right = Region[304];
}

Function {
  If(kappa_uniform == 1)
    kappa[Aluminium] = 1; kappa[InnerScreen] = 1; kappa[XLPE] = 1;
    kappa[OuterScreen] = 1; kappa[Lead] = 1; kappa[Filler] = 1;
    kappa[Steel] = 1; kappa[Polyethylene] = 1; kappa[Seabed] = 1;
  Else
    kappa[Aluminium] = kappa_aluminium;
    kappa[InnerScreen] = kappa_semiconductor;
    kappa[XLPE] = kappa_xlpe;
    kappa[OuterScreen] = kappa_semiconductor;
    kappa[Lead] = kappa_lead;
    kappa[Filler] = kappa_filler;
    kappa[Steel] = kappa_steel;
    kappa[Polyethylene] = kappa_polyethylene;
    kappa[Seabed] = kappa_seabed;
  EndIf

  // Q3.9 losses mapped to mesh-normalized thermal source densities.
  Q[Aluminium] = 3*P_cond_per_core/SurfaceArea[];
  Q[Lead] = 3*P_sheath_per_core/SurfaceArea[];
  Q[Steel] = P_armour_total/SurfaceArea[];
  Q[Seabed] = P_seabed_total/SurfaceArea[];
  Q[InnerScreen] = 0;
  Q[XLPE] = 0;
  Q[OuterScreen] = 0;
  Q[Filler] = 0;
  Q[Polyethylene] = 0;
  h[] = h;
  Tamb[] = T_amb;
}

Constraint {
  { Name TemperatureNatural; Type Assign;
    Case {}
  }
}
If (bottom == 0)
  Constraint {
    { Name Dirichlet_T; Type Assign;
      Case {
        { Region Gamma_bottom; Value T_amb; }
      }
    }
  }
EndIf
If (outer_all_dirichlet == 1)
  Constraint {
    { Name Dirichlet_T_All; Type Assign;
      Case {
        { Region Gamma_surface; Value T_amb; }
        { Region Gamma_left; Value T_amb; }
        { Region Gamma_right; Value T_amb; }
      }
    }
  }
EndIf

FunctionSpace {
  { Name Hgrad_T; Type Form0;
    BasisFunction {
      { Name sn; NameOfCoef Tn; Function BF_Node;
        Support Region[{Domain, Gamma_surface, Gamma_bottom}];
        Entity NodesOf[All]; }
    }
    Constraint {
      If (bottom == 0)
        { NameOfCoef Tn; EntityType NodesOf;
          NameOfConstraint Dirichlet_T; }
      EndIf
      If (outer_all_dirichlet == 1)
        { NameOfCoef Tn; EntityType NodesOf;
          NameOfConstraint Dirichlet_T_All; }
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
      Integral { [ kappa[]*Dof{d T},{d T} ];
        In Domain; Jacobian Vol; Integration I1; }
      If (outer_all_dirichlet == 0)
        Integral { [ h*Dof{T},{T} ];
          In Gamma_surface; Jacobian Sur; Integration I1; }
        Integral { [ -h*Tamb[],{T} ];
          In Gamma_surface; Jacobian Sur; Integration I1; }
      EndIf
      Integral { [ -Q[],{T} ];
        In Domain; Jacobian Vol; Integration I1; }
    }
  }
}

Resolution {
  { Name Thermal;
    System {
      { Name A; NameOfFormulation ThermalSteady; }
    }
    Operation {
      Generate[A]; Solve[A];
      SaveSolution[A];
    }
  }
}

PostProcessing {
  { Name ThermalPost; NameOfFormulation ThermalSteady;
    Quantity {
      { Name T; Value { Term { [ {T} ]; In Domain; Jacobian Vol; } } }
      { Name T_surface; Value { Term { [ {T} ];
        In Gamma_surface; Jacobian Sur; } } }
      // TODO/P_IN: mesh-exact source power for all three conductors/leads.
      // A_mesh=Integral[1] over each source region.
      { Name A_cond_mesh; Value { Integral { [ 1 ];
        In Aluminium; Jacobian Vol; Integration I1; } } }
      { Name A_lead_mesh; Value { Integral { [ 1 ];
        In Lead; Jacobian Vol; Integration I1; } } }
      { Name P_cond_in; Value { Integral { [ Q[] ];
        In Aluminium; Jacobian Vol; Integration I1; } } }
      { Name P_lead_in; Value { Integral { [ Q[] ];
        In Lead; Jacobian Vol; Integration I1; } } }
      { Name P_armour_in; Value { Integral { [ Q[] ];
        In Steel; Jacobian Vol; Integration I1; } } }
      { Name P_other_in; Value { Integral { [ Q[] ];
        In Seabed; Jacobian Vol; Integration I1; } } }
      { Name P_in; Value {
        Integral { Type Global; [ Q[] ]; In Aluminium; Jacobian Vol; Integration I1; }
        Integral { Type Global; [ Q[] ]; In Lead; Jacobian Vol; Integration I1; }
        Integral { Type Global; [ Q[] ]; In Steel; Jacobian Vol; Integration I1; }
        Integral { Type Global; [ Q[] ]; In Seabed; Jacobian Vol; Integration I1; }
      } }
      { Name P_out; Value { Integral { Type Global;
        [ h[]*({T}-Tamb[]) ]; In Gamma_surface;
        Jacobian Sur; Integration I1; } } }
    }
  }
}

PostOperation {
  { Name ThermalOutputs; NameOfPostProcessing ThermalPost;
    Operation {
      Print[ T, OnElementsOf Domain, File "res/T_domain.pos" ];
      Print[ T, OnElementsOf Cable, File "res/T_cable.pos" ];
      Print[ A_cond_mesh[Aluminium], OnGlobal, Format Table, File "res/A_cond_mesh.txt" ];
      Print[ A_lead_mesh[Lead], OnGlobal, Format Table, File "res/A_lead_mesh.txt" ];
      Print[ P_cond_in[Aluminium], OnGlobal, Format Table, File "res/P_cond_in.txt" ];
      Print[ P_lead_in[Lead], OnGlobal, Format Table, File "res/P_lead_in.txt" ];
      Print[ P_armour_in[Steel], OnGlobal, Format Table, File "res/P_armour_in.txt" ];
      Print[ P_other_in[Seabed], OnGlobal, Format Table, File "res/P_other_in.txt" ];
      Print[ P_in, OnGlobal, Format Table, File "res/P_in.txt" ];
      Print[ P_out, OnGlobal, Format Table, File "res/P_out.txt" ];
      Print[ T, OnElementsOf Aluminium, Format Table, File "res/T_cond_elements.txt" ];
      Print[ T_surface, OnElementsOf Gamma_surface, Format Table, File "res/T_surface_elements.txt" ];
    }
  }
}
