
//////////////////////////////////////////////////
// Electrodynamic FEM formulation
// Adapted from the professor's starting file
//////////////////////////////////////////////////

// 1. Unknown potential and finite-element basis
FunctionSpace {

  { Name Hgrad_v_Ele; Type Form0;
    BasisFunction {
      { Name sn; NameOfCoef vn; Function BF_Node;
        Support Domain_Ele; Entity NodesOf[All]; }
    }
    Constraint {
      { NameOfCoef vn; EntityType NodesOf;
        NameOfConstraint ElectricScalarPotential; }
    }
  }

}

// 2. Governing equation (weak formulation)
Formulation {

  { Name Electrodynamics_v; Type FemEquation;
    Quantity {
      { Name v; Type Local; NameOfSpace Hgrad_v_Ele; }
    }
    Equation {
      Galerkin {
        [ sigma[] * Dof{d v}, {d v} ];
        In Domain_Ele; Jacobian Vol; Integration I1;
      }

      Galerkin {
        DtDof[ epsilon[] * Dof{d v}, {d v} ];
        In Domain_Ele; Jacobian Vol; Integration I1;
      }
    }
  }

}

// 3. Solve the complex AC problem
Resolution {

  { Name Electrodynamics;
    System {
      { Name Sys_Ele;
        NameOfFormulation Electrodynamics_v;
        Type Complex; Frequency Freq; }
    }
    Operation {
      CreateDir["res"];
      Generate[Sys_Ele];
      Solve[Sys_Ele];
      SaveSolution[Sys_Ele];
      PostOperation[Ele_Maps];
    }
  }

}

// 4. Quantities calculated from the solution
PostProcessing {

  { Name EleDyn_v;
    NameOfFormulation Electrodynamics_v;
    Quantity {
      { Name v; Value {
        Term { [ {v} ]; In Domain_Ele; Jacobian Vol; }
      } }

      { Name em; Value {
        Term { [ Norm[-{d v}] ];
          In Domain_Ele; Jacobian Vol; }
      } }

      // Magnitude of resistive current density [A/m2]
      { Name j_res; Value {
        Term {
          [ sigma[] * Norm[-{d v}] ];
          In Domain_Ele; Jacobian Vol;
        }
      } }

      // Magnitude of displacement current density [A/m2]
      { Name j_disp; Value {
        Term {
          [ 2*Pi*Freq*epsilon[] * Norm[-{d v}] ];
          In Domain_Ele; Jacobian Vol;
        }
      } }

      { Name energy; Value { //CHANGE FROM THE PROFESSOR: NEEDED TO CALCULATE THE CAPACITANCE (from tutorial GetDP)
          Integral {
            [ epsilon[] / 2 * SquNorm[{d v}] ];
            In Domain_Ele;
            Jacobian Vol;
            Integration I1;
          }
        }
      }
    }
  }
}

// 5. Export results for visualization
PostOperation {

  { Name Ele_Maps;
    NameOfPostProcessing EleDyn_v;
    Operation {
      Print[ v, OnElementsOf Domain_Ele,
        File "res/potential.pos" ];

      Print[ em, OnElementsOf Domain_Ele,
        Name "|E| [V/m]",
        File "res/electric_field.pos" ];
      
      Print[ j_res, OnElementsOf Domain_Ele,
        Name "|J_res| [A/m2]",
        File "res/j_resistive.pos" ];

      Print[ j_disp, OnElementsOf Domain_Ele,
        Name "|J_disp| [A/m2]",
        File "res/j_displacement.pos" ];

      Print[
        energy[Domain_Ele],
        OnGlobal,
        File "res/energy.txt",
        Format Table
      ];
    }
  }

}
