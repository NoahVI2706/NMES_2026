DefineConstant[
  bottom_bc = {1, Choices {0="Dirichlet T=T_amb",1="Zero flux"}, Name "Boundary/Bottom condition"},
  kappa_uniform = {0, Choices {0="Real kappa",1="Uniform kappa=1"}, Name "Test/Uniform kappa"},
  outer_all_dirichlet = {0, Choices {0="Normal boundaries",1="All outer boundaries Dirichlet"}, Name "Test/All outer boundaries Dirichlet"},
  Freq = {50.0, Name "MQS/Frequency [Hz]"},
  I_rms = {385.0, Name "MQS/Phase current RMS [A]"},
  sigma_Al_mqs = {3.77e7, Name "MQS/Aluminium conductivity [S/m]"},
  sigma_Lead_mqs = {4.55e6, Name "MQS/Lead conductivity [S/m]"},
  sigma_Armour_mqs = {4.7e6, Name "MQS/Steel armour conductivity [S/m]"},
  mu_r_Armour = {4.0, Name "MQS/Steel armour relative permeability"},
  sigma_Semi_mqs = {2.0, Name "MQS/Semiconductor conductivity [S/m]"},
  sigma_Soil_mqs = {0.5, Name "MQS/Seabed conductivity [S/m]"},
  T_amb = {20.0, Name "Thermal/Ambient temperature [C]"},
  h = {500.0, Name "Thermal/Convection coefficient [W/m2/K]"},
  P_cond_per_core = {20.0, Name "Thermal/Conductor source [W/m]"},
  P_sheath_per_core = {2.0, Name "Thermal/Lead sheath source [W/m]"},
  kappa_seabed = {1.0, Name "Thermal/kappa seabed [W/m/K]"}, // Assumed
  kappa_xlpe = {0.46, Name "Thermal/kappa XLPE [W/m/K]"},
  kappa_lead = {35.0, Name "Thermal/kappa lead [W/m/K]"},
  kappa_aluminium = {237.0, Name "Thermal/kappa aluminium [W/m/K]"},
  kappa_steel = {50.2, Name "Thermal/kappa steel [W/m/K]"}, // Assumed
  kappa_polyethylene = {0.46, Name "Thermal/kappa polyethylene [W/m/K]"}, // Assumed
  kappa_filler = {0.4, Name "Thermal/kappa filler [W/m/K]"}, // Assumed
  kappa_semiconductor = {10.0, Name "Thermal/kappa semiconductor [W/m/K]"}, // Assumed
  r_conductor = {0.00905, Name "Geometry/Conductor radius [m]"},
  r_outerScreen = {0.01875, Name "Geometry/Outer screen radius [m]"},
  r_lead = {0.02035, Name "Geometry/Lead radius [m]"}, // 40.5 mm existing diameter
  // TODO: Replace with the datasheet lead outer radius if it differs from 40.5 mm.
  L = {1.0, Name "Geometry/Translation depth L [m]"},
  x_A = {0.0, Name "Geometry/Core A x [m]"},
  x_B = {-0.022, Name "Geometry/Core B x [m]"},
  x_C = {0.022, Name "Geometry/Core C x [m]"},
  y_A0 = {0.0254, Name "Geometry/Core A original y [m]"},
  y_B0 = {-0.0127, Name "Geometry/Core B original y [m]"},
  y_C0 = {-0.0127, Name "Geometry/Core C original y [m]"}
];

Include "thermal_formulation.pro";
