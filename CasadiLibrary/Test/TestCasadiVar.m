TestVar

CasadiLib.setSX(ocpVar);
assert( isa(ocpVar.value,'casadi.SX') )

CasadiLib.setMX(ocpVar);
assert( isa(ocpVar.value,'casadi.MX') )