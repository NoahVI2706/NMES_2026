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
  lc_cable = {0.4, Name "Mesh/lc_cable [mm]"},
  lc_far = {1.500, Name "Mesh/lc_far reference [m]"}
];

lc_cable_m = lc_cable*1e-3;
lc_near = 5*lc_cable_m;
lc_far_actual = lc_far*D/30.0;

xc[] = {0.0, -0.022, 0.022};
y0[] = {0.0254, -0.0127, -0.0127};
yc[] = {-L+y0(0), -L+y0(1), -L+y0(2)};
r_fill = filler_diameter/2;
r_armour = r_fill+t_armour;
r_pe = De/2;

// Three cores: disks 1..15.
For i In {0:2}
  k = 5*i;
  Disk(1+k)  = {xc[i],yc[i],0,r_conductor};
  Disk(2+k)  = {xc[i],yc[i],0,r_innerScreen};
  Disk(3+k)  = {xc[i],yc[i],0,r_XLPE};
  Disk(4+k)  = {xc[i],yc[i],0,r_outerScreen};
  Disk(5+k)  = {xc[i],yc[i],0,r_lead};
EndFor

// Filler, armour and polyethylene disks 16..18.
Disk(16) = {0,-L,0,r_fill};
Disk(17) = {0,-L,0,r_armour};
Disk(18) = {0,-L,0,r_pe};

// Soil/seabed rectangle tag 19.
Point(101) = {-W/2,-D,0};
Point(102) = { W/2,-D,0};
Point(103) = { W/2,0,0};
Point(104) = {-W/2,0,0};
Line(101) = {101,102};
Line(102) = {102,103};
Line(103) = {103,104};
Line(104) = {104,101};
Curve Loop(101) = {101,102,103,104};
Plane Surface(19) = {101};

// One fragment operation cuts the whole cable/seabed into conformal surfaces.
BooleanFragments{ Surface{19}; Delete; }{ Surface{1:18}; Delete; }

// Select surfaces by bounding boxes after fragmenting.
e = 1e-6;
For i In {0:2}
  x0 = xc[i]; y0c = yc[i];
  b0[] = Surface In BoundingBox{x0-r_conductor-e,y0c-r_conductor-e,-e,x0+r_conductor+e,y0c+r_conductor+e,e};
  b1[] = Surface In BoundingBox{x0-r_innerScreen-e,y0c-r_innerScreen-e,-e,x0+r_innerScreen+e,y0c+r_innerScreen+e,e};
  b2[] = Surface In BoundingBox{x0-r_XLPE-e,y0c-r_XLPE-e,-e,x0+r_XLPE+e,y0c+r_XLPE+e,e};
  b3[] = Surface In BoundingBox{x0-r_outerScreen-e,y0c-r_outerScreen-e,-e,x0+r_outerScreen+e,y0c+r_outerScreen+e,e};
  b4[] = Surface In BoundingBox{x0-r_lead-e,y0c-r_lead-e,-e,x0+r_lead+e,y0c+r_lead+e,e};
  screen[] = b3[];
  screen[] -= b2[];
  cond~{i}[] = b0[];
  semiin~{i}[] = b1[]; semiin~{i}[] -= b0[];
  xlpe~{i}[] = b2[]; xlpe~{i}[] -= b1[];
  semiout~{i}[] = screen[];
  lead~{i}[] = b4[]; lead~{i}[] -= b3[];
  core~{i}[] = b4[];
EndFor

bF[] = Surface In BoundingBox{-r_fill-e,-L-r_fill-e,-e,r_fill+e,-L+r_fill+e,e};
bA[] = Surface In BoundingBox{-r_armour-e,-L-r_armour-e,-e,r_armour+e,-L+r_armour+e,e};
bO[] = Surface In BoundingBox{-r_pe-e,-L-r_pe-e,-e,r_pe+e,-L+r_pe+e,e};
bS[] = Surface In BoundingBox{-W/2-e,-D-e,-e,W/2+e,e,e};

fill[] = bF[]; fill[] -= {core_0[],core_1[],core_2[]};
armour[] = bA[]; armour[] -= bF[];
outer[] = bO[]; outer[] -= bA[];
soil[] = bS[]; soil[] -= bO[];

// Assign any remaining fragment surface to the missing outer-screen region.
unassigned[] = Surface{:};
unassigned[] -= cond_0[]; unassigned[] -= cond_1[]; unassigned[] -= cond_2[];
unassigned[] -= semiin_0[]; unassigned[] -= semiin_1[]; unassigned[] -= semiin_2[];
unassigned[] -= xlpe_0[]; unassigned[] -= xlpe_1[]; unassigned[] -= xlpe_2[];
unassigned[] -= lead_0[]; unassigned[] -= lead_1[]; unassigned[] -= lead_2[];
unassigned[] -= fill[]; unassigned[] -= armour[]; unassigned[] -= outer[]; unassigned[] -= soil[];

Physical Surface("Aluminium",1) = {cond_0[],cond_1[],cond_2[]};
Physical Surface("InnerScreen",2) = {semiin_0[],semiin_1[],semiin_2[]};
Physical Surface("XLPE",3) = {xlpe_0[],xlpe_1[],xlpe_2[]};
Physical Surface("OuterScreen",4) = {unassigned[]};
Physical Surface("Lead",5) = {lead_0[],lead_1[],lead_2[]};
Physical Surface("Filler",6) = fill[];
Physical Surface("Steel",7) = armour[];
Physical Surface("Polyethylene",8) = outer[];
Physical Surface("Seabed",9) = soil[];

// Boundary curves must be selected after BooleanFragments creates new tags.
gamma_surface[] = Curve In BoundingBox{-W/2-e,-e,-e,W/2+e,e,e};
gamma_bottom[] = Curve In BoundingBox{-W/2-e,-D-e,-e,W/2+e,-D+e,e};
gamma_left[] = Curve In BoundingBox{-W/2-e,-D-e,-e,-W/2+e,e,e};
gamma_right[] = Curve In BoundingBox{W/2-e,-D-e,-e,W/2+e,e,e};
Physical Curve("Gamma_surface",301) = gamma_surface[];
Physical Curve("Gamma_bottom",302) = gamma_bottom[];
Physical Curve("Gamma_left",303) = gamma_left[];
Physical Curve("Gamma_right",304) = gamma_right[];

Field[1] = Distance;
Field[1].EdgesList = {Boundary{ Surface{lead_0[],lead_1[],lead_2[]}; }};
Field[2] = Threshold;
Field[2].IField = 1;
Field[2].LcMin = lc_cable_m;
Field[2].LcMax = lc_far_actual;
Field[2].DistMin = lc_near;
Field[2].DistMax = D/2;
Background Field = 2;
Mesh.MeshSizeFromPoints = 0;
Mesh.MeshSizeExtendFromBoundary = 0;
Mesh.Algorithm = 6;
Mesh.ElementOrder = 1;
