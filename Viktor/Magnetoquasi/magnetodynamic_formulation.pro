Group{
  DefineGroup[
    DomainS0_Mag // Stranded model if imposing source with js0[]
  ];
}

FunctionSpace {

  { Name Hcurl_a_Mag_2D; Type Form1P;
    BasisFunction {
      { Name se; NameOfCoef ae; Function BF_PerpendicularEdge;
        Support Region[{Domain_Mag, OuterBC}]; Entity NodesOf[ All ]; }   // Boundary nodes included to support optional asymptotic boundary integration
      If (Flag_Degree_a == 2)
        { Name se2; NameOfCoef ae2; Function BF_PerpendicularEdge_2E;
          Support Domain_Mag; Entity EdgesOf[ All ]; }
      EndIf
    }
    Constraint {
      { NameOfCoef ae;
        EntityType NodesOf; NameOfConstraint MagneticVectorPotential_2D; }
      If (Flag_Degree_a == 2)
	    { NameOfCoef ae2; // Only OK if homogeneous BC, otherwise specify zero-BC
          EntityType EdgesOf; NameOfConstraint MagneticVectorPotential_2D; }
      EndIf
    }
  }

  { Name Hregion_i_2D ; Type Vector ;
    BasisFunction {
      { Name sr ; NameOfCoef ir ; Function BF_RegionZ ;
        Support DomainS_Mag ; Entity DomainS_Mag ; }
    }
    GlobalQuantity {
      { Name Is ; Type AliasOf        ; NameOfCoef ir ; }
      { Name Us ; Type AssociatedWith ; NameOfCoef ir ; }
    }
    Constraint {
      { NameOfCoef Us ; EntityType Region ; NameOfConstraint Voltage_2D ; }
      { NameOfCoef Is ; EntityType Region ; NameOfConstraint Current_2D ; }
    }
  }

  // Gradient of Electric scalar potential (2D)
  { Name Hregion_u_Mag_2D ; Type Form1P ;
    BasisFunction {
      { Name sr ; NameOfCoef ur ; Function BF_RegionZ ;
        Support DomainC_Mag ; Entity DomainC_Mag ; }
    }
    GlobalQuantity {
      { Name U ; Type AliasOf        ; NameOfCoef ur ; }
      { Name I ; Type AssociatedWith ; NameOfCoef ur ; }
    }
    Constraint {
      { NameOfCoef U ;
        EntityType Region ; NameOfConstraint Voltage_2D ; }
      { NameOfCoef I ;
        EntityType Region ; NameOfConstraint Current_2D ; }
    }
  }


}

Formulation {

  { Name Magnetodynamic_a_2D; Type FemEquation; // Magnetodynamics
    Quantity {
      { Name a;  Type Local; NameOfSpace Hcurl_a_Mag_2D; }

      // massive conductors (source or not)
      { Name ur ; Type Local  ; NameOfSpace Hregion_u_Mag_2D ; }
      { Name I  ; Type Global ; NameOfSpace Hregion_u_Mag_2D [I] ; }
      { Name U  ; Type Global ; NameOfSpace Hregion_u_Mag_2D [U] ; }

       // stranded conductors (source)
      { Name ir ; Type Local  ; NameOfSpace Hregion_i_2D ; }
      { Name Us ; Type Global ; NameOfSpace Hregion_i_2D[Us] ; }
      { Name Is ; Type Global ; NameOfSpace Hregion_i_2D[Is] ; }
    }

    Equation {
      Galerkin { [ nu[] * Dof{d a} , {d a} ];
        In Domain_Mag; Jacobian Vol; Integration I1; }
      Galerkin { DtDof [ sigma[] * Dof{a} , {a} ];
        In DomainC_Mag; Jacobian Vol; Integration I1; }

      Galerkin { [ sigma[] * Dof{ur}, {a} ] ;
        In DomainC_Mag ; Jacobian Vol ; Integration I1 ; }
      Galerkin { DtDof [ sigma[] * Dof{a} , {ur} ] ;
        In DomainC_Mag ; Jacobian Vol ; Integration I1 ; }
      Galerkin { [ sigma[] * Dof{ur}, {ur} ] ;
        In DomainC_Mag ; Jacobian Vol ; Integration I1 ; }

      // ADDED (team): asymptotic (mixed) BC on the circular truncation boundary, leading harmonic m: d a/d r + (m/r) a = 0
      // (course ch. 4, 'Asymptotic boundary conditions'); enters as nu*(m/R)*int(a a') on the boundary
      If(Flag_BC == 1)
        Galerkin { [ (1.0/mu0) * m_asym / R_trunc * Dof{a} , {a} ];
          In OuterBC; Jacobian Sur; Integration I1; }
      EndIf

      GlobalTerm { [ Dof{I} , {U} ] ; In DomainCWithI_Mag ; }

      // Either you impose directly the function js0[]
      Galerkin { [ -js0[] , {a} ];
        In DomainS0_Mag; Jacobian Vol; Integration I1; }

      // or you use the constraints => allows accounting for sigma[]
      Galerkin { [ -Ns[]/Sc[] * Dof{ir}, {a} ] ;
        In DomainS_Mag ; Jacobian Vol ; Integration I1 ; }
      Galerkin { DtDof [ Ns[]/Sc[] * Dof{a}, {ir} ] ;
        In DomainS_Mag ; Jacobian Vol ; Integration I1 ; }

      Galerkin { [ Ns[]/Sc[] / sigma[] * Ns[]/Sc[]* Dof{ir} , {ir} ] ; // resistance term
        In DomainS_Mag ; Jacobian Vol ; Integration I1 ; }
      //GlobalTerm { [ Rdc * Dof{Is} , {Is} ] ; In DomainS ; } // OR this resitance term
      GlobalTerm { [ Dof{Us}, {Is} ] ; In DomainS_Mag ; }

    }
  }

}


Resolution {

  { Name Magnetodynamics;
    System {
      { Name Sys_Mag; NameOfFormulation Magnetodynamic_a_2D;
        Type Complex; Frequency Freq; }
    }
    Operation {
      CreateDir["res"];

      InitSolution[Sys_Mag];
      Generate[Sys_Mag]; Solve[Sys_Mag]; SaveSolution[Sys_Mag];
      PostOperation[Mag_Maps];
      PostOperation[Mag_Global];
    }
  }

}


PostProcessing {

  { Name Magnetodynamic_a_2D; NameOfFormulation Magnetodynamic_a_2D;
    PostQuantity {
      { Name a; Value { Term { [ {a} ]; In Domain_Mag; Jacobian Vol; } } }
      { Name az; Value { Term { [ CompZ[{a}] ]; In Domain_Mag; Jacobian Vol; } } }
      { Name b; Value { Term { [ {d a} ]; In Domain_Mag; Jacobian Vol; } } }
      { Name bm; Value { Term { [ Norm[{d a}] ]; In Domain_Mag; Jacobian Vol; } } }

      { Name j; Value {
          Term { [ -sigma[]*(Dt[{a}]+{ur})]; In DomainC_Mag; Jacobian Vol; }
          Term { [ js0[] ]; In DomainS0_Mag; Jacobian Vol; }
          Term { [ Ns[]/Sc[]*{ir} ]; In DomainS_Mag; Jacobian Vol; }
        } }
      { Name jz; Value {
          Term { [ CompZ[-sigma[]*(Dt[{a}]+{ur})] ]; In DomainC_Mag; Jacobian Vol; }
          Term { [ CompZ[ js0[] ] ]; In DomainS0_Mag; Jacobian Vol; }
          Term { [ CompZ[ Ns[]/Sc[]*{ir} ]]; In DomainS_Mag; Jacobian Vol; }
        } }
      { Name jm; Value {
          Term { [ Norm[-sigma[]*(Dt[{a}]+{ur})] ]; In DomainC_Mag; Jacobian Vol; }
          Term { [ Norm[ js0[] ] ]; In DomainS0_Mag; Jacobian Vol; }
          Term { [ Norm[ Ns[]/Sc[]*{ir} ]]; In DomainS_Mag; Jacobian Vol; }
        } }

      { Name rhoj2; Value {
          Term { [ 0.5*sigma[]*SquNorm[Dt[{a}]+{ur}] ]; In DomainC_Mag; Jacobian Vol; }
          Term { [ 0.5/sigma[]*SquNorm[js0[]] ]; In DomainS0_Mag ; Jacobian Vol; }
          Term { [ 0.5/sigma[]*SquNorm[Ns[]/Sc[]*{ir}] ]; In DomainS_Mag; Jacobian Vol; }
        }
      }


      { Name JouleLosses; Value {
          // CHANGED (team): total current density, -sigma*(Dt[a]+ur); the template used Dt[{a}] only (Appendix A note)
          Integral { [ 0.5*sigma[]*SquNorm[Dt[{a}]+{ur}] ]   ; In DomainC_Mag  ; Jacobian Vol ; Integration I1 ; }
          Integral { [ 0.5/sigma[]*SquNorm[js0[]] ]          ; In DomainS0_Mag ; Jacobian Vol ; Integration I1 ; }
          Integral { [ 0.5/sigma[]*SquNorm[Ns[]/Sc[]*{ir}] ] ; In DomainS_Mag  ; Jacobian Vol ; Integration I1 ; }
        }
      }

      // ADDED (team): net current per region from the integral of j_z (cross-check of the global quantity I)
      { Name Inet; Value {
          Integral { [ CompZ[ -sigma[]*(Dt[{a}]+{ur}) ] ]; In DomainC_Mag; Jacobian Vol; Integration I1; }
          Integral { [ CompZ[ Ns[]/Sc[]*{ir} ] ]; In DomainS_Mag; Jacobian Vol; Integration I1; }
        } }

      { Name U ; Value {
          Term { [ {U} ]  ; In DomainC_Mag ; }
          Term { [ {Us} ] ; In DomainS_Mag ; }
        }
      }

      { Name I ; Value {
          Term { [ {I} ]  ; In DomainC_Mag ; }
          Term { [ {Is} ] ; In DomainS_Mag ; }
        }
      }

      { Name S ; Value {
          Term { [ {U}*Conj[{I}] ] ; In DomainC_Mag ; }
          Term { [ {Us}*Conj[{Is}] ] ; In DomainS_Mag ; }
        }
      }

      { Name R ; Value {
          Term { [ -Re[{U}/{I}] ] ; In DomainC_Mag ; }
          Term { [ -Re[{Us}/{Is}] ] ; In DomainS_Mag ; }
        }
      }

      { Name L ; Value {
          Term { [ -Im[{U}/{I}]/(2*Pi*Freq) ] ; In DomainC_Mag ; }
          Term { [ -Im[{Us}/{Is}]/(2*Pi*Freq) ] ; In DomainS_Mag ; }
        }
      }

      // For convenience... possible scaling
      { Name R_per_km ; Value {
          Term { [ -Re[{U}/{I}]*1e3 ] ; In DomainC_Mag ; }
          Term { [ -Re[{Us}/{Is}]*1e3 ] ; In DomainS_Mag ; }
        }
      }

      { Name mL_per_km ; Value {
          Term { [ -1e6*Im[{U}/{I}]/(2*Pi*Freq) ] ; In DomainC_Mag ; }
          Term { [ -1e6*Im[{Us}/{Is}]/(2*Pi*Freq) ] ; In DomainS_Mag ; }
        }
      }

    }
  }

}


// ================================================================
// OUTPUTS. Re-running the model overwrites files in res/.
// For comparison, copy the full res/ folder after each run.
// ================================================================
PostOperation {
  { Name Mag_Maps; NameOfPostProcessing Magnetodynamic_a_2D;
    Operation {
      Print[az, OnElementsOf Domain_Mag, Name "A_z [T m]", File "res/az.pos"];
      Print[bm, OnElementsOf Domain_Mag, Name "|B| [T]", File "res/B_norm.pos"];
      Print[jz, OnElementsOf Region[{DomainC_Mag,DomainS_Mag}],
            Name "J_z [A/m2] (complex)", File "res/Jz_complex.pos"];
      Print[jm, OnElementsOf Region[{DomainC_Mag,DomainS_Mag}],
            Name "|J| [A/m2]", File "res/J_norm.pos"];
      Print[rhoj2, OnElementsOf Region[{DomainC_Mag,DomainS_Mag}],
            Name "Mean Joule density [W/m3]", File "res/loss_density.pos"];
    }
  }
  { Name Mag_Global; NameOfPostProcessing Magnetodynamic_a_2D;
    Operation {
      // W/m is numerically equal to kW/km.
      Print[JouleLosses[Aluminium], OnGlobal, Format Table,
            File "res/loss_Al_Wpm.dat"];
      Print[JouleLosses[Lead], OnGlobal, Format Table,
            File "res/loss_Lead_Wpm.dat"];
      Print[JouleLosses[Steel], OnGlobal, Format Table,
            File "res/loss_Armour_Wpm.dat"];
      Print[JouleLosses[Soil], OnGlobal, Format Table,
            File "res/loss_Soil_Wpm.dat"];
      Print[JouleLosses[Domain_Mag], OnGlobal, Format Table,
            File "res/loss_Total_Wpm.dat"];
      Print[Inet[Lead_A], OnGlobal, Format Table, File "res/I_Lead_A.dat"];
      Print[Inet[Lead_B], OnGlobal, Format Table, File "res/I_Lead_B.dat"];
      Print[Inet[Lead_C], OnGlobal, Format Table, File "res/I_Lead_C.dat"];
      Print[Inet[Steel], OnGlobal, Format Table, File "res/I_Armour.dat"];
      Print[R_per_km, OnRegion Al_A, Format Table, File "res/R_phaseA_ohm_per_km.dat"];
      Print[mL_per_km, OnRegion Al_A, Format Table, File "res/L_phaseA_mH_per_km.dat"];
    }
  }
}
