SetFactory("OpenCASCADE");

// 1. Dimensions (metres)
r_conductor   = 0.00905;
r_innerScreen = 0.01025;
r_XLPE        = 0.01825;
r_outerScreen = 0.01875;
r_lead        = 0.02025;

// 2. Centres of the three phases
x[] = {0, -0.022, 0.022};
y[] = {0.0254, -0.0127, -0.0127};

// 3. Create five disks per phase
For i In {0:2}
  Disk(1+i)  = {x[i], y[i], 0, r_conductor};
  Disk(11+i) = {x[i], y[i], 0, r_innerScreen};
  Disk(21+i) = {x[i], y[i], 0, r_XLPE};
  Disk(31+i) = {x[i], y[i], 0, r_outerScreen};
  Disk(41+i) = {x[i], y[i], 0, r_lead};
EndFor

// 4. Subtract disks to create layers
For i In {0:2}
  // Lead sheath
  BooleanDifference(401+i) = {
    Surface{41+i}; Delete;
  }{
    Surface{31+i};
  };

  // Outer semiconducting screen
  BooleanDifference(301+i) = {
    Surface{31+i}; Delete;
  }{
    Surface{21+i};
  };

  // XLPE insulation
  BooleanDifference(201+i) = {
    Surface{21+i}; Delete;
  }{
    Surface{11+i};
  };

  // Inner semiconducting screen
  BooleanDifference(101+i) = {
    Surface{11+i}; Delete;
  }{
    Surface{1+i};
  };

EndFor

// 5. Make material interfaces conforming
Coherence; // I dont understand the importance of this command ---> find out later

// 6. Physical material groups
Physical Surface("Aluminium", 1) = {1, 2, 3};
Physical Surface("InnerScreen", 2) = {101, 102, 103};
Physical Surface("XLPE", 3) = {201, 202, 203};
Physical Surface("OuterScreen", 4) = {301, 302, 303};
Physical Surface("Lead", 5) = {401, 402, 403};

// 7. High-voltage boundaries
boundaryA[] = Boundary{ Surface{1}; };
boundaryB[] = Boundary{ Surface{2}; };
boundaryC[] = Boundary{ Surface{3}; };

Physical Curve("HV_A", 101) = {boundaryA[]};
Physical Curve("HV_B", 102) = {boundaryB[]};
Physical Curve("HV_C", 103) = {boundaryC[]};

// 8. Grounded boundaries
// Find curves shared by the outer screen and the lead sheath.
groundCurves[] = {};

For i In {0:2}
  screenEdges[] = Boundary{ Surface{301+i}; };
  leadEdges[]   = Boundary{ Surface{401+i}; };

  For j In {0:#screenEdges[]-1}
    For k In {0:#leadEdges[]-1}

      If (Abs(screenEdges[j]) == Abs(leadEdges[k]))
        groundCurves[] += {Abs(screenEdges[j])};
      EndIf

    EndFor
  EndFor

EndFor

// All three grounded boundaries
Physical Curve("Ground", 201) = {groundCurves[]};

Printf("Number of grounded curves: %g", #groundCurves[]);

// 9. Mesh settings
Mesh.MeshSizeMax = 0.001; // Maximum target element size: 1 mm