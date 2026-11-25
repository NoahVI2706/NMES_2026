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
  Armour = Region[7];
  Soil = Region[9];
  Domain_Mag = Region[{Aluminium,InnerScreen,XLPE,OuterScreen,Lead,Filler,Steel,Polyethylene,Seabed}];
  DomainC_Mag = Region[{Lead,Steel,Seabed}];
  DomainCWithI_Mag = Region[Seabed];
  DomainS0_Mag = Region[Aluminium];
  OuterBC_Mag = Region[{Gamma_surface,Gamma_bottom,Gamma_left,Gamma_right}];
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

  mu0 = 4e-7*Pi;
  nu[Region[{Aluminium,InnerScreen,XLPE,OuterScreen,Lead,Filler,Polyethylene,Seabed}]] = 1/mu0;
  nu[Steel] = 1/(mu0*mu_r_Armour);
  sigma[Aluminium] = sigma_Al_mqs*A_cond_Al/(Pi*(r_conductor*1e3)^2);
  sigma[Lead] = sigma_Lead_mqs;
  sigma[Steel] = sigma_Armour_mqs;
  sigma[Seabed] = sigma_Soil_mqs;
  sigma[InnerScreen] = sigma_Semi_mqs;
  sigma[OuterScreen] = sigma_Semi_mqs;
  sigma[XLPE] = 0;
  sigma[Filler] = 0;
  sigma[Polyethylene] = 0;

  CoefGeo[] = 1;
  omega = 2*Pi*Freq;
  Ipk = Sqrt[2]*I_rms;
  Jpk = Ipk/(Pi*r_conductor^2);
  y_A = -L+y_A0; y_B = -L+y_B0; y_C = -L+y_C0;
  dA[] = (X[]-x_A)^2+(Y[]-y_A)^2;
  dB[] = (X[]-x_B)^2+(Y[]-y_B)^2;
  dC[] = (X[]-x_C)^2+(Y[]-y_C)^2;
  js0[] = Vector[0,0,Jpk*(dA[]<dB[] && dA[]<dC[] ?
    Complex[1,0] : (dB[]<dC[] ? Complex[-0.5,-Sqrt[3]/2] :
    Complex[-0.5,Sqrt[3]/2]))];
  h[] = h;
  Tamb[] = T_amb;
}

Constraint {
  { Name MagneticVectorPotential_2D;
    Case { { Region OuterBC_Mag; Value 0; } }
  }
  { Name Current_2D;
    Case { { Region Seabed; Value 0; } }
  }
  { Name Voltage_2D;
    Case {
      { Region Lead; Value 0; }
      { Region Steel; Value 0; }
    }
  }
  { Name TemperatureNatural; Type Assign;
    Case {}
  }
}
If (bottom_bc == 0)
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
  { Name Hcurl_a_Mag_2D; Type Form1P;
    BasisFunction {
      { Name se; NameOfCoef ae; Function BF_PerpendicularEdge;
        Support Domain_Mag; Entity NodesOf[All]; }
    }
    Constraint {
      { NameOfCoef ae; EntityType NodesOf;
        NameOfConstraint MagneticVectorPotential_2D; }
    }
  }
  { Name Hregion_u_Mag_2D; Type Form1P;
    BasisFunction {
      { Name sr; NameOfCoef ur; Function BF_RegionZ;
        Support DomainC_Mag; Entity DomainC_Mag; }
    }
    GlobalQuantity {
      { Name U; Type AliasOf; NameOfCoef ur; }
      { Name I; Type AssociatedWith; NameOfCoef ur; }
    }
    Constraint {
      { NameOfCoef U; EntityType Region; NameOfConstraint Voltage_2D; }
      { NameOfCoef I; EntityType Region; NameOfConstraint Current_2D; }
    }
  }
  { Name Hgrad_T; Type Form0;
    BasisFunction {
      { Name sn; NameOfCoef Tn; Function BF_Node;
        Support Region[{Domain, Gamma_surface, Gamma_bottom}];
        Entity NodesOf[All]; }
    }
    Constraint {
      If (bottom_bc == 0)
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
  { Name Magnetodynamic_a_2D; Type FemEquation;
    Quantity {
      { Name a; Type Local; NameOfSpace Hcurl_a_Mag_2D; }
      { Name ur; Type Local; NameOfSpace Hregion_u_Mag_2D; }
      { Name I; Type Global; NameOfSpace Hregion_u_Mag_2D[I]; }
      { Name U; Type Global; NameOfSpace Hregion_u_Mag_2D[U]; }
    }
    Equation {
      Integral { [ nu[]*Dof{d a},{d a} ];
        In Domain_Mag; Jacobian Vol; Integration I1; }
      Integral { DtDof [ sigma[]*Dof{a},{a} ];
        In DomainC_Mag; Jacobian Vol; Integration I1; }
      Integral { [ sigma[]*Dof{ur},{a} ];
        In DomainC_Mag; Jacobian Vol; Integration I1; }
      Integral { DtDof [ sigma[]*Dof{a},{ur} ];
        In DomainC_Mag; Jacobian Vol; Integration I1; }
      Integral { [ sigma[]*Dof{ur},{ur} ];
        In DomainC_Mag; Jacobian Vol; Integration I1; }
      GlobalTerm { [ Dof{I}*Sign[CoefGeo[]],{U} ];
        In DomainCWithI_Mag; }
      Integral { [ -js0[],{a} ];
        In DomainS0_Mag; Jacobian Vol; Integration I1; }
    }
  }
  { Name ThermalSteady; Type FemEquation;
    Quantity {
      { Name T; Type Local; NameOfSpace Hgrad_T; }
      { Name a; Type Local; NameOfSpace Hcurl_a_Mag_2D; }
      { Name ur; Type Local; NameOfSpace Hregion_u_Mag_2D; }
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
      Integral { [ -0.5/sigma[]*<a>[SquNorm[js0[]]],{T} ];
        In DomainS0_Mag; Jacobian Vol; Integration I1; }
      Integral { [ -0.5*sigma[]*<a>[SquNorm[Dt[{a}]+{ur}/CoefGeo[]]],{T} ];
        In DomainC_Mag; Jacobian Vol; Integration I1; }
    }
  }
}

Resolution {
  { Name Coupled;
    System {
      { Name Sys_Mag; NameOfFormulation Magnetodynamic_a_2D;
        Type Complex; Frequency Freq; }
      { Name Sys_The; NameOfFormulation ThermalSteady; }
    }
    Operation {
      CreateDir["res"];
      Generate[Sys_Mag]; Solve[Sys_Mag]; SaveSolution[Sys_Mag];
      Generate[Sys_The]; Solve[Sys_The]; SaveSolution[Sys_The];
    }
  }
}

PostProcessing {
  { Name ThermalPost; NameOfFormulation ThermalSteady;
    Quantity {
      { Name T; Value { Term { [ {T} ]; In Domain; Jacobian Vol; } } }
      { Name T_surface; Value { Term { [ {T} ];
        In Gamma_surface; Jacobian Sur; } } }
      { Name Loss_Conductors; Value { Integral { Type Global;
        [ 0.5/sigma[]*<a>[SquNorm[js0[]]] ];
        In Aluminium; Jacobian Vol; Integration I1; } } }
      { Name Loss_Sheaths; Value { Integral { Type Global;
        [ 0.5*sigma[]*<a>[SquNorm[Dt[{a}]+{ur}/CoefGeo[]]] ];
        In Lead; Jacobian Vol; Integration I1; } } }
      { Name Loss_Armour; Value { Integral { Type Global;
        [ 0.5*sigma[]*<a>[SquNorm[Dt[{a}]+{ur}/CoefGeo[]]] ];
        In Steel; Jacobian Vol; Integration I1; } } }
      { Name Loss_Other; Value { Integral { Type Global;
        [ 0.5*sigma[]*<a>[SquNorm[Dt[{a}]+{ur}/CoefGeo[]]] ];
        In Seabed; Jacobian Vol; Integration I1; } } }
      { Name P_in; Value {
        Integral { Type Global; [ 0.5/sigma[]*<a>[SquNorm[js0[]]] ];
          In Aluminium; Jacobian Vol; Integration I1; }
        Integral { Type Global;
          [ 0.5*sigma[]*<a>[SquNorm[Dt[{a}]+{ur}/CoefGeo[]]] ];
          In DomainC_Mag; Jacobian Vol; Integration I1; }
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
      Print[ Loss_Conductors, OnGlobal, Format Table, File "res/loss_conductors.txt" ];
      Print[ Loss_Sheaths, OnGlobal, Format Table, File "res/loss_sheaths.txt" ];
      Print[ Loss_Armour, OnGlobal, Format Table, File "res/loss_armour.txt" ];
      Print[ Loss_Other, OnGlobal, Format Table, File "res/loss_other.txt" ];
      Print[ P_in, OnGlobal, Format Table, File "res/P_in.txt" ];
      Print[ P_out, OnGlobal, Format Table, File "res/P_out.txt" ];
      Print[ T, OnElementsOf Aluminium, Format Table, File "res/T_cond_elements.txt" ];
      Print[ T_surface, OnElementsOf Gamma_surface, Format Table, File "res/T_surface_elements.txt" ];
    }
  }
}
