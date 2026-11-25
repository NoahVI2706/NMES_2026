// Q3.4: simplified magnetic cable geometry
// Based on cable_magnetic.geo. No metallic geometry is changed.
// Each core's semiconducting screens and XLPE are replaced by ONE
// nonconducting, nonmagnetic annulus between conductor and lead sheath.
// These layers have mu_r=1 and J=0 in our magnetic baseline.
// Dimensions in mm, exported mesh in m via Mesh.ScalingFactor.
SetFactory("OpenCASCADE");
DefineConstant[
  r_cond={9.05, Name "Geometry/r_cond [mm]"},
  r_semi_out={18.85, Name "Geometry/r_semi_out [mm]"}, // lead inner radius
  r_lead={20.35, Name "Geometry/r_lead [mm]"},
  d_trefoil={41.2, Name "Geometry/d_trefoil [mm]"},
  r_fill={45, Name "Geometry/r_fill [mm]"},
  r_armour_out={49, Name "Geometry/r_armour_out [mm]"},
  r_outer={62, Name "Geometry/r_outer [mm]"},
  r_soil={620, Name "Geometry/r_soil [mm]"},
  lc_cond={0.5, Name "Mesh/lc_cond"},
  lc_insulation={2, Name "Mesh/lc_insulation"},
  lc_lead={0.5, Name "Mesh/lc_lead"},
  lc_fill={2, Name "Mesh/lc_fill"},
  lc_armour={1, Name "Mesh/lc_armour"},
  lc_outer={3, Name "Mesh/lc_outer"},
  lc_soil={15, Name "Mesh/lc_soil"},
  s_mesh={1, Name "Mesh/Global size factor"}
];
Mesh.ScalingFactor = 0.001;
Mesh.SaveAll = 0;
Mesh.MeshSizeExtendFromBoundary = 1; // same mesh-size propagation setting as baseline
R_trefoil = d_trefoil/Sqrt(3);
cxs()={0,-d_trefoil/2,d_trefoil/2};
cys()={R_trefoil,-R_trefoil/2,-R_trefoil/2};
// Three disks per core (conductor, outer face of merged dielectric,
// outer face of lead sheath), instead of five disks per core.
For k In {0:2}
  Disk(1+3*k) = {cxs(k),cys(k),0,r_cond};
  Disk(2+3*k) = {cxs(k),cys(k),0,r_semi_out};
  Disk(3+3*k) = {cxs(k),cys(k),0,r_lead};
EndFor
Disk(10)={0,0,0,r_fill};
Disk(11)={0,0,0,r_armour_out};
Disk(12)={0,0,0,r_outer};
Disk(13)={0,0,0,r_soil};
BooleanFragments{Surface{13};Delete;}{Surface{1:12};Delete;}
// Determine physical surfaces from their bounding boxes.
e=1e-3;
For k In {0:2}
  x0=cxs(k); y0=cys(k);
  b0[]=Surface In BoundingBox{x0-r_cond-e,y0-r_cond-e,-e,x0+r_cond+e,y0+r_cond+e,e};
  b1[]=Surface In BoundingBox{x0-r_semi_out-e,y0-r_semi_out-e,-e,x0+r_semi_out+e,y0+r_semi_out+e,e};
  b2[]=Surface In BoundingBox{x0-r_lead-e,y0-r_lead-e,-e,x0+r_lead+e,y0+r_lead+e,e};
  cond~{k}[]=b0[];
  insulation~{k}[]=b1[];insulation~{k}[]-=b0[];
  lead~{k}[]=b2[];lead~{k}[]-=b1[];
  core~{k}[]=b2[];
EndFor
bF[]=Surface In BoundingBox{-r_fill-e,-r_fill-e,-e,r_fill+e,r_fill+e,e};
bA[]=Surface In BoundingBox{-r_armour_out-e,-r_armour_out-e,-e,r_armour_out+e,r_armour_out+e,e};
bO[]=Surface In BoundingBox{-r_outer-e,-r_outer-e,-e,r_outer+e,r_outer+e,e};
bS[]=Surface In BoundingBox{-r_soil-e,-r_soil-e,-e,r_soil+e,r_soil+e,e};
fill[]=bF[];fill[]-={core_0[],core_1[],core_2[]};
armour[]=bA[];armour[]-=bF[];
outer[]=bO[];outer[]-=bA[];
soil[]=bS[];soil[]-=bO[];
Physical Surface("Conductor_A",1)=cond_0[];
Physical Surface("Conductor_B",2)=cond_1[];
Physical Surface("Conductor_C",3)=cond_2[];
Physical Surface("EquivalentInsulation_A",4)=insulation_0[];
Physical Surface("EquivalentInsulation_B",5)=insulation_1[];
Physical Surface("EquivalentInsulation_C",6)=insulation_2[];
// Physical tags 7-12 deliberately absent: old screen and XLPE interfaces removed.
Physical Surface("Lead_A",13)=lead_0[];
Physical Surface("Lead_B",14)=lead_1[];
Physical Surface("Lead_C",15)=lead_2[];
Physical Surface("Filling",16)=fill[];
Physical Surface("Armour",17)=armour[];
Physical Surface("Outer",18)=outer[];
Physical Surface("Soil",19)=soil[];
bnd()=CombinedBoundary{Surface{:};};
Physical Curve("Outer_Boundary",20)={bnd()};
// Coarse-to-fine mesh settings; retain refinement at conducting surfaces.
MeshSize{PointsOf{Surface{soil[]};}}=lc_soil*s_mesh;
MeshSize{PointsOf{Surface{outer[]};}}=lc_outer*s_mesh;
MeshSize{PointsOf{Surface{armour[]};}}=lc_armour*s_mesh;
MeshSize{PointsOf{Surface{fill[]};}}=lc_fill*s_mesh;
For k In {0:2}
  MeshSize{PointsOf{Surface{insulation~{k}[]};}}=lc_insulation*s_mesh;
  MeshSize{PointsOf{Surface{lead~{k}[]};}}=lc_lead*s_mesh;
  MeshSize{PointsOf{Surface{cond~{k}[]};}}=lc_cond*s_mesh;
EndFor
// Expected physical region counts: 3 conductors + 3 equivalent insulation
// + 3 lead sheaths + filling + armour + outer jacket + soil = 13.
