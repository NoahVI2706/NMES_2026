// Parameterized 2-D cross-section of one or three cable cores.
// Lengths are in metres so that the GetDP results use SI units.

DefineConstant[
  NumberOfCores = {3, Name "Geometry/Number of cores", Min 1, Max 3, Step 2},
  ConductorRadius = {18.1e-3/2, Name "Geometry/Conductor radius [m]"},
  InnerScreenThickness = {0.5e-3, Name "Geometry/Inner screen thickness [m]"},
  InsulationThickness = {8.0e-3, Name "Geometry/XLPE insulation thickness [m]"},
  OuterScreenThickness = {0.5e-3, Name "Geometry/Outer screen thickness [m]"},
  LeadThickness = {1.5e-3, Name "Geometry/Lead sheath thickness [m]"},
  CableOuterDiameter = {124e-3, Name "Geometry/Overall cable diameter [m]"},
  CoreClearance = {1.0e-3, Name "Geometry/Clearance to cable envelope [m]"},
  CharacteristicMeshSize = {1.0e-3, Name "Mesh/Characteristic length [m]"}
];

rInner = ConductorRadius + InnerScreenThickness;
rXLPE = rInner + InsulationThickness;
rOuter = rXLPE + OuterScreenThickness;
rSheath = rOuter + LeadThickness;
CoreCentreRadius = CableOuterDiameter/2 - rSheath - CoreClearance;

For k In {0:NumberOfCores-1}
  If (NumberOfCores == 1)
    cx = 0;
    cy = 0;
  Else
    theta = Pi/2 + 2*Pi*k/3;
    cx = CoreCentreRadius*Cos(theta);
    cy = CoreCentreRadius*Sin(theta);
  EndIf

  pc0 = newp; Point(pc0) = {cx, cy, 0, CharacteristicMeshSize};
  pc1 = newp; Point(pc1) = {cx + ConductorRadius, cy, 0, CharacteristicMeshSize};
  pc2 = newp; Point(pc2) = {cx, cy + ConductorRadius, 0, CharacteristicMeshSize};
  pc3 = newp; Point(pc3) = {cx - ConductorRadius, cy, 0, CharacteristicMeshSize};
  pc4 = newp; Point(pc4) = {cx, cy - ConductorRadius, 0, CharacteristicMeshSize};

  pi1 = newp; Point(pi1) = {cx + rInner, cy, 0, CharacteristicMeshSize};
  pi2 = newp; Point(pi2) = {cx, cy + rInner, 0, CharacteristicMeshSize};
  pi3 = newp; Point(pi3) = {cx - rInner, cy, 0, CharacteristicMeshSize};
  pi4 = newp; Point(pi4) = {cx, cy - rInner, 0, CharacteristicMeshSize};

  px1 = newp; Point(px1) = {cx + rXLPE, cy, 0, CharacteristicMeshSize};
  px2 = newp; Point(px2) = {cx, cy + rXLPE, 0, CharacteristicMeshSize};
  px3 = newp; Point(px3) = {cx - rXLPE, cy, 0, CharacteristicMeshSize};
  px4 = newp; Point(px4) = {cx, cy - rXLPE, 0, CharacteristicMeshSize};

  po1 = newp; Point(po1) = {cx + rOuter, cy, 0, CharacteristicMeshSize};
  po2 = newp; Point(po2) = {cx, cy + rOuter, 0, CharacteristicMeshSize};
  po3 = newp; Point(po3) = {cx - rOuter, cy, 0, CharacteristicMeshSize};
  po4 = newp; Point(po4) = {cx, cy - rOuter, 0, CharacteristicMeshSize};

  ps1 = newp; Point(ps1) = {cx + rSheath, cy, 0, CharacteristicMeshSize};
  ps2 = newp; Point(ps2) = {cx, cy + rSheath, 0, CharacteristicMeshSize};
  ps3 = newp; Point(ps3) = {cx - rSheath, cy, 0, CharacteristicMeshSize};
  ps4 = newp; Point(ps4) = {cx, cy - rSheath, 0, CharacteristicMeshSize};

  lc1 = newl; Circle(lc1) = {pc1, pc0, pc2};
  lc2 = newl; Circle(lc2) = {pc2, pc0, pc3};
  lc3 = newl; Circle(lc3) = {pc3, pc0, pc4};
  lc4 = newl; Circle(lc4) = {pc4, pc0, pc1};
  li1 = newl; Circle(li1) = {pi1, pc0, pi2};
  li2 = newl; Circle(li2) = {pi2, pc0, pi3};
  li3 = newl; Circle(li3) = {pi3, pc0, pi4};
  li4 = newl; Circle(li4) = {pi4, pc0, pi1};
  lx1 = newl; Circle(lx1) = {px1, pc0, px2};
  lx2 = newl; Circle(lx2) = {px2, pc0, px3};
  lx3 = newl; Circle(lx3) = {px3, pc0, px4};
  lx4 = newl; Circle(lx4) = {px4, pc0, px1};
  lo1 = newl; Circle(lo1) = {po1, pc0, po2};
  lo2 = newl; Circle(lo2) = {po2, pc0, po3};
  lo3 = newl; Circle(lo3) = {po3, pc0, po4};
  lo4 = newl; Circle(lo4) = {po4, pc0, po1};
  ls1 = newl; Circle(ls1) = {ps1, pc0, ps2};
  ls2 = newl; Circle(ls2) = {ps2, pc0, ps3};
  ls3 = newl; Circle(ls3) = {ps3, pc0, ps4};
  ls4 = newl; Circle(ls4) = {ps4, pc0, ps1};

  llc = newll; Line Loop(llc) = {lc1, lc2, lc3, lc4};
  lli = newll; Line Loop(lli) = {li1, li2, li3, li4};
  llx = newll; Line Loop(llx) = {lx1, lx2, lx3, lx4};
  llo = newll; Line Loop(llo) = {lo1, lo2, lo3, lo4};
  lls = newll; Line Loop(lls) = {ls1, ls2, ls3, ls4};

  sc = news; Plane Surface(sc) = {llc};
  si = news; Plane Surface(si) = {lli, -llc};
  sx = news; Plane Surface(sx) = {llx, -lli};
  so = news; Plane Surface(so) = {llo, -llx};
  ss = news; Plane Surface(ss) = {lls, -llo};

  conductor[k] = sc;
  innerScreen[k] = si;
  xlpe[k] = sx;
  outerScreen[k] = so;
  leadSheath[k] = ss;
  conductorBoundary[k] = lc1;
  sheathBoundary[k] = ls1;
  conductorBoundary1[k] = lc1;
  conductorBoundary2[k] = lc2;
  conductorBoundary3[k] = lc3;
  conductorBoundary4[k] = lc4;
  sheathBoundary1[k] = ls1;
  sheathBoundary2[k] = ls2;
  sheathBoundary3[k] = ls3;
  sheathBoundary4[k] = ls4;
  conductorCentreX[k] = cx;
  conductorCentreY[k] = cy;
EndFor

Physical Surface(1001) = {conductor[]};
Physical Surface(1002) = {innerScreen[]};
Physical Surface(1003) = {xlpe[]};
Physical Surface(1004) = {outerScreen[]};
Physical Surface(1005) = {leadSheath[]};
Physical Line(1100) = {conductorBoundary[]};
Physical Line(1105) = {
  sheathBoundary1[], sheathBoundary2[],
  sheathBoundary3[], sheathBoundary4[]
};
Physical Line(1101) = {
  conductorBoundary1[0], conductorBoundary2[0],
  conductorBoundary3[0], conductorBoundary4[0]
};
If (NumberOfCores > 1)
  Physical Line(1102) = {
    conductorBoundary1[1], conductorBoundary2[1],
    conductorBoundary3[1], conductorBoundary4[1]
  };
  Physical Line(1103) = {
    conductorBoundary1[2], conductorBoundary2[2],
    conductorBoundary3[2], conductorBoundary4[2]
  };
EndIf

