SetFactory("OpenCASCADE");

DefineConstant[
  L = {1.0, Name "Geometry/Translation depth L [m]"},
  D = {30.0, Name "Geometry/Seabed depth D [m]"},
  W = {60.0, Name "Geometry/Seabed width W [m]"},
  De = {0.124, Name "Geometry/Outer polyethylene diameter De [m]"},
  filler_diameter = {0.100, Name "Geometry/Filler diameter [m]"},
  t_armour = {0.006, Name "Geometry/Steel armour thickness [m]"},
  r_conductor = {0.00905, Name "Geometry/Conductor radius [m]"},
  r_innerScreen = {0.01025, Name "Geometry/Inner screen radius [m]"},
  r_XLPE = {0.01825, Name "Geometry/XLPE radius [m]"},
  r_outerScreen = {0.01875, Name "Geometry/Outer screen radius [m]"},
  r_lead = {0.02025, Name "Geometry/Lead radius [m]"},
  x_A = {0.0, Name "Geometry/Core A x [m]"},
  x_B = {-0.022, Name "Geometry/Core B x [m]"},
  x_C = {0.022, Name "Geometry/Core C x [m]"},
  y_A0 = {0.0254, Name "Geometry/Core A original y [m]"},
  y_B0 = {-0.0127, Name "Geometry/Core B original y [m]"},
  y_C0 = {-0.0127, Name "Geometry/Core C original y [m]"},
  lc_cable = {0.0004, Name "Mesh/lc_cable [m]"},
  lc_near = {0.002, Name "Mesh/lc_near [m]"},
  lc_far = {1.500, Name "Mesh/lc_far [m]"}
];

xc[] = {x_A, x_B, x_C};
yc[] = {-L+y_A0, -L+y_B0, -L+y_C0};
r_fill = filler_diameter/2;
r_armour = r_fill+t_armour;
r_pe = De/2;

For i In {0:2}
  Disk(1+i) = {xc[i], yc[i], 0, r_conductor};
  Disk(11+i) = {xc[i], yc[i], 0, r_innerScreen};
  Disk(21+i) = {xc[i], yc[i], 0, r_XLPE};
  Disk(31+i) = {xc[i], yc[i], 0, r_outerScreen};
  Disk(41+i) = {xc[i], yc[i], 0, r_lead};

  BooleanDifference(401+i) = {Surface{41+i}; Delete;}{Surface{31+i};};
  BooleanDifference(301+i) = {Surface{31+i}; Delete;}{Surface{21+i};};
  BooleanDifference(201+i) = {Surface{21+i}; Delete;}{Surface{11+i};};
  BooleanDifference(101+i) = {Surface{11+i}; Delete;}{Surface{1+i};};
EndFor

// Filler, steel armour and polyethylene
Disk(500) = {0, -L, 0, r_fill};
lead_disks[] = {};
For i In {0:2}
  Disk(510+i) = {xc[i], yc[i], 0, r_lead};
  lead_disks[] += 510+i;
EndFor
BooleanDifference(600) = {Surface{500}; Delete;}{Surface{lead_disks[]}; Delete;};

Disk(612) = {0, -L, 0, r_fill};
Disk(611) = {0, -L, 0, r_armour};
BooleanDifference(610) = {Surface{611}; Delete;}{Surface{612}; Delete;};

Disk(613) = {0, -L, 0, r_armour};
Disk(621) = {0, -L, 0, r_pe};
BooleanDifference(620) = {Surface{621}; Delete;}{Surface{613}; Delete;};

// Seabed rectangle with bottom y=-D and surface y=0
p1 = newp; Point(p1) = {-W/2, -D, 0};
p2 = newp; Point(p2) = { W/2, -D, 0};
p3 = newp; Point(p3) = { W/2,  0, 0};
p4 = newp; Point(p4) = {-W/2,  0, 0};
l_bottom = newreg; Line(l_bottom) = {p1,p2};
l_right  = newreg; Line(l_right)  = {p2,p3};
l_top    = newreg; Line(l_top)    = {p3,p4};
l_left   = newreg; Line(l_left)   = {p4,p1};
wire_seabed = newreg; Curve Loop(wire_seabed) = {l_bottom,l_right,l_top,l_left};
seabed = newreg; Plane Surface(seabed) = {wire_seabed};

// The full cable envelope creates a conforming circular hole in the seabed.
Disk(800) = {0, -L, 0, r_pe};
BooleanDifference(900) = {Surface{seabed}; Delete;}{Surface{800}; Delete;};

// Generated line tags after the circular seabed cut.
Physical Curve("Gamma_surface", 101) = {26};
Physical Curve("Gamma_bottom", 102) = {24};
Physical Curve("Gamma_left", 103) = {27};
Physical Curve("Gamma_right", 104) = {25};

Physical Surface("Aluminium", 1) = {1,2,3};
Physical Surface("InnerScreen", 2) = {101,102,103};
Physical Surface("XLPE", 3) = {201,202,203};
Physical Surface("OuterScreen", 4) = {301,302,303};
Physical Surface("Lead", 5) = {401,402,403};
Physical Surface("Filler", 6) = {600};
Physical Surface("Steel", 7) = {610};
Physical Surface("Polyethylene", 8) = {620};
Physical Surface("Seabed", 9) = {900};

// Distance/Threshold field: cable-aware grading to the far-field size.
cable_edges[] = {};
For i In {0:2}
  cable_edges[] += Boundary{Surface{401+i};};
EndFor
Field[1] = Distance;
Field[1].EdgesList = {cable_edges[]};

Field[2] = Threshold;
Field[2].IField = 1;
Field[2].LcMin = lc_cable;
Field[2].LcMax = lc_far;
Field[2].DistMin = lc_near;
Field[2].DistMax = D/2;

Background Field = 2;
Mesh.MeshSizeFromPoints = 0;
Mesh.MeshSizeExtendFromBoundary = 0;
Mesh.Algorithm = 6;
Mesh.ElementOrder = 1;
