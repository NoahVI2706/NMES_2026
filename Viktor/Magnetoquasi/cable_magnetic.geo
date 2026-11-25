// ============================================================
// Q3 MAGNETODYNAMICS - geometry, ONELAB inputs and physical tags
// Three-core ABB 45/52 kV 3 x 240 mm2 cable; concentric equivalent layers
// ============================================================
// Units in the geometry are millimetres.
// Mesh.ScalingFactor = 0.001 converts them to metres for GetDP.
// ============================================================

SetFactory("OpenCASCADE");
// ============================================================
// NMES High-Voltage Cable - Parameters (Per-core lead sheaths)
// Shared baseline geometry: conductor and XLPE radii consistent with Q2.
// Outer semiconducting screen and lead sheaths follow team magnetic model.
// Units: millimetres
// Source: ABB 2GM5007 Table 44 (45 kV, 240 mm²)
// ============================================================

DefineConstant[
  // --- Core layer outer radii (mm) ---
  r_cond        = {9.05,  Name "Geometry/r_cond [mm]"},
  r_semi_in     = {10.25,  Name "Geometry/r_semi_in [mm]"},
  r_xlpe        = {18.25, Name "Geometry/r_xlpe [mm]"},
  r_semi_out    = {18.85, Name "Geometry/r_semi_out [mm]"},
  r_lead        = {20.35, Name "Geometry/r_lead [mm]"},

  // --- Layout ---
  d_trefoil     = {41.2,  Name "Geometry/d_trefoil [mm]"},

  // --- Outer layers ---
  r_fill        = {45.0,  Name "Geometry/r_fill [mm]"},
  r_armour_out  = {49.0,  Name "Geometry/r_armour_out [mm]"},
  r_outer       = {62.0,  Name "Geometry/r_outer [mm]"},
  r_soil        = {620.0, Name "Geometry/r_soil [mm]"},   // 10 x cable outer radius

  // --- Mesh sizes ---
  lc_cond       = {0.5,   Name "Mesh/lc_cond"},
  lc_semi       = {0.2,   Name "Mesh/lc_semi"},
  lc_xlpe       = {0.5,   Name "Mesh/lc_xlpe"},
  lc_lead       = {0.5,   Name "Mesh/lc_lead"},
  lc_fill       = {2.0,   Name "Mesh/lc_fill"},
  lc_armour     = {1.0,   Name "Mesh/lc_armour"},
  lc_outer      = {3.0,   Name "Mesh/lc_outer"},
  lc_soil       = {15.0,  Name "Mesh/lc_soil"}
];

r_armour_in = r_fill;                 // single source of truth
R_trefoil   = d_trefoil / Sqrt(3);

DefineConstant[ s_mesh = {1.0, Name "Mesh/Global size factor"} ];
lc_cond = lc_cond*s_mesh; lc_semi = lc_semi*s_mesh; lc_xlpe = lc_xlpe*s_mesh; lc_lead = lc_lead*s_mesh;
lc_fill = lc_fill*s_mesh; lc_armour = lc_armour*s_mesh; lc_outer = lc_outer*s_mesh; lc_soil = lc_soil*s_mesh;



Mesh.ScalingFactor = 0.001;
Mesh.SaveAll = 0;
Mesh.MeshSizeExtendFromBoundary = 1;

// ------------------------------------------------------------
// Core centres
// ------------------------------------------------------------
cxA = 0.0;               cyA = R_trefoil;
cxB = -d_trefoil/2;      cyB = -R_trefoil/2;
cxC =  d_trefoil/2;      cyC = -R_trefoil/2;

// ------------------------------------------------------------
// Create all disks
// ------------------------------------------------------------
// Core A
Disk(1)  = {cxA, cyA, 0, r_cond};
Disk(2)  = {cxA, cyA, 0, r_semi_in};
Disk(3)  = {cxA, cyA, 0, r_xlpe};
Disk(4)  = {cxA, cyA, 0, r_semi_out};
Disk(5)  = {cxA, cyA, 0, r_lead};

// Core B
Disk(6)  = {cxB, cyB, 0, r_cond};
Disk(7)  = {cxB, cyB, 0, r_semi_in};
Disk(8)  = {cxB, cyB, 0, r_xlpe};
Disk(9)  = {cxB, cyB, 0, r_semi_out};
Disk(10) = {cxB, cyB, 0, r_lead};

// Core C
Disk(11) = {cxC, cyC, 0, r_cond};
Disk(12) = {cxC, cyC, 0, r_semi_in};
Disk(13) = {cxC, cyC, 0, r_xlpe};
Disk(14) = {cxC, cyC, 0, r_semi_out};
Disk(15) = {cxC, cyC, 0, r_lead};

// Outer domains (centred at origin)
Disk(16) = {0, 0, 0, r_fill};
Disk(17) = {0, 0, 0, r_armour_out};
Disk(18) = {0, 0, 0, r_outer};
Disk(19) = {0, 0, 0, r_soil};

// ------------------------------------------------------------
// Fragments: conformal interfaces (tags change after this line)
// ------------------------------------------------------------
BooleanFragments{ Surface{19}; Delete; }{ Surface{1:18}; Delete; }

// ------------------------------------------------------------
// Select surfaces by POSITION (bounding boxes), not with Closest.
// (BooleanFragments renumbers surfaces; a box test is robust.)
// ------------------------------------------------------------
e = 1e-3;
cxs() = {cxA, cxB, cxC};
cys() = {cyA, cyB, cyC};
For k In {0:2}
  x0 = cxs(k); y0 = cys(k);
  b0[] = Surface In BoundingBox{x0-r_cond    -e, y0-r_cond    -e, -e, x0+r_cond    +e, y0+r_cond    +e, e};
  b1[] = Surface In BoundingBox{x0-r_semi_in -e, y0-r_semi_in -e, -e, x0+r_semi_in +e, y0+r_semi_in +e, e};
  b2[] = Surface In BoundingBox{x0-r_xlpe    -e, y0-r_xlpe    -e, -e, x0+r_xlpe    +e, y0+r_xlpe    +e, e};
  b3[] = Surface In BoundingBox{x0-r_semi_out-e, y0-r_semi_out-e, -e, x0+r_semi_out+e, y0+r_semi_out+e, e};
  b4[] = Surface In BoundingBox{x0-r_lead    -e, y0-r_lead    -e, -e, x0+r_lead    +e, y0+r_lead    +e, e};
  cond~{k}[]    = b0[];
  semiin~{k}[]  = b1[]; semiin~{k}[]  -= b0[];
  xlpe~{k}[]    = b2[]; xlpe~{k}[]    -= b1[];
  semiout~{k}[] = b3[]; semiout~{k}[] -= b2[];
  lead~{k}[]    = b4[]; lead~{k}[]    -= b3[];
  core~{k}[]    = b4[];
EndFor
bF[] = Surface In BoundingBox{-r_fill      -e, -r_fill      -e, -e, r_fill      +e, r_fill      +e, e};
bA[] = Surface In BoundingBox{-r_armour_out-e, -r_armour_out-e, -e, r_armour_out+e, r_armour_out+e, e};
bO[] = Surface In BoundingBox{-r_outer     -e, -r_outer     -e, -e, r_outer     +e, r_outer     +e, e};
bS[] = Surface In BoundingBox{-r_soil      -e, -r_soil      -e, -e, r_soil      +e, r_soil      +e, e};
fill[]   = bF[]; fill[]   -= {core_0[], core_1[], core_2[]};
armour[] = bA[]; armour[] -= bF[];
outer[]  = bO[]; outer[]  -= bA[];
soil[]   = bS[]; soil[]   -= bO[];

Physical Surface("Conductor_A", 1)  = cond_0[];
Physical Surface("Conductor_B", 2)  = cond_1[];
Physical Surface("Conductor_C", 3)  = cond_2[];
Physical Surface("XLPE_A", 4)       = xlpe_0[];
Physical Surface("XLPE_B", 5)       = xlpe_1[];
Physical Surface("XLPE_C", 6)       = xlpe_2[];
Physical Surface("SemiIn_A", 7)     = semiin_0[];
Physical Surface("SemiIn_B", 8)     = semiin_1[];
Physical Surface("SemiIn_C", 9)     = semiin_2[];
Physical Surface("SemiOut_A", 10)   = semiout_0[];
Physical Surface("SemiOut_B", 11)   = semiout_1[];
Physical Surface("SemiOut_C", 12)   = semiout_2[];
Physical Surface("Lead_A", 13)      = lead_0[];
Physical Surface("Lead_B", 14)      = lead_1[];
Physical Surface("Lead_C", 15)      = lead_2[];
Physical Surface("Filling", 16)     = fill[];
Physical Surface("Armour", 17)      = armour[];
Physical Surface("Outer", 18)       = outer[];
Physical Surface("Soil", 19)        = soil[];

bnd() = CombinedBoundary{ Surface{:}; };
Physical Curve("Outer_Boundary", 20) = {bnd()};

// ------------------------------------------------------------
// Mesh sizes, coarse -> fine (shared points keep the last value)
// ------------------------------------------------------------
MeshSize{ PointsOf{ Surface{soil[]};   } } = lc_soil;
MeshSize{ PointsOf{ Surface{outer[]};  } } = lc_outer;
MeshSize{ PointsOf{ Surface{armour[]}; } } = lc_armour;
MeshSize{ PointsOf{ Surface{fill[]};   } } = lc_fill;
For k In {0:2}
  MeshSize{ PointsOf{ Surface{lead~{k}[]};    } } = lc_lead;
  MeshSize{ PointsOf{ Surface{cond~{k}[]};    } } = lc_cond;
  MeshSize{ PointsOf{ Surface{semiout~{k}[]}; } } = lc_semi;
  MeshSize{ PointsOf{ Surface{semiin~{k}[]};  } } = lc_semi;
  MeshSize{ PointsOf{ Surface{xlpe~{k}[]};    } } = lc_xlpe;
EndFor

DefineConstant[ lc_xlpe_in = {-1, Name "Mesh/lc_xlpe_in (<0 = off)"} ];
If(lc_xlpe_in > 0)
  For k In {0:2}
    x0 = cxs(k); y0 = cys(k);
    ci[] = Curve In BoundingBox{x0-r_semi_in-e, y0-r_semi_in-e, -e, x0+r_semi_in+e, y0+r_semi_in+e, e};
    ci[] -= Curve In BoundingBox{x0-r_cond-e, y0-r_cond-e, -e, x0+r_cond+e, y0+r_cond+e, e};
    MeshSize{ PointsOf{ Curve{ci[]}; } } = lc_xlpe_in;
  EndFor
EndIf

// --- Truncation-boundary mesh size (Q3.1 radius study); <0 keeps lc_soil ---
DefineConstant[ lc_far = {-1, Name "Mesh/lc_far [mm] (<0 = lc_soil)"} ];
If(lc_far > 0)
  MeshSize{ PointsOf{ Curve{bnd()}; } } = lc_far*s_mesh;
EndIf

// Geometry IDs 1-20 are matched explicitly by cable_magnetic.pro.
