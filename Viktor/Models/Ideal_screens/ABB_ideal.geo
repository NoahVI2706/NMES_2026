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
For i In {0:0}
  Disk(1+i)  = {x[i], y[i], 0, r_conductor};
  Disk(11+i) = {x[i], y[i], 0, r_innerScreen};
  Disk(21+i) = {x[i], y[i], 0, r_XLPE};
  Disk(31+i) = {x[i], y[i], 0, r_outerScreen};
  Disk(41+i) = {x[i], y[i], 0, r_lead};
EndFor

// 4. Subtract disks to create layers
For i In {0:0}
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
Physical Surface("Aluminium", 1) = {1};
Physical Surface("InnerScreen", 2) = {101};
Physical Surface("XLPE", 3) = {201};
Physical Surface("OuterScreen", 4) = {301};
Physical Surface("Lead", 5) = {401};


//////////////////////////////////////////////////
// 7. High-voltage boundary: inner XLPE surface
//////////////////////////////////////////////////

// Find the shared boundary between the
// inner semiconducting screen and XLPE.

innerEdges[] = Boundary{ Surface{101}; };
xlpeEdges[]  = Boundary{ Surface{201}; };

hvCurves[] = {};

For j In {0:#innerEdges[]-1}
  For k In {0:#xlpeEdges[]-1}

    If (Abs(innerEdges[j]) == Abs(xlpeEdges[k]))
      hvCurves[] += {Abs(innerEdges[j])};
    EndIf

  EndFor
EndFor

Physical Curve("HV_A", 101) = {hvCurves[]};


//////////////////////////////////////////////////
// 8. Ground boundary: outer XLPE surface
//////////////////////////////////////////////////

// Find the shared boundary between the
// XLPE and outer semiconducting screen.

outerEdges[] = Boundary{ Surface{301}; };

groundCurves[] = {};

For j In {0:#xlpeEdges[]-1}
  For k In {0:#outerEdges[]-1}

    If (Abs(xlpeEdges[j]) == Abs(outerEdges[k]))
      groundCurves[] += {Abs(xlpeEdges[j])};
    EndIf

  EndFor
EndFor

Physical Curve("Ground", 201) = {groundCurves[]};


//////////////////////////////////////////////////
// 9. Check boundaries
//////////////////////////////////////////////////

Printf("HV curves: %g", #hvCurves[]);
Printf("Ground curves: %g", #groundCurves[]);


//////////////////////////////////////////////////
// 10. Mesh settings
//////////////////////////////////////////////////

Mesh.MeshSizeMax = 0.001;
