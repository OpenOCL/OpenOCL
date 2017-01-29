function TestCasadiVar
state = Var('x');
state.add('p',[3,1]);
state.add('R',[3,3]);
state.add('v',[3,1]);
state.add('w',[3,1]);
state.compile;

CasadiLib.setSX(state);
assert( isa(state.value,'casadi.SX') )

CasadiLib.setMX(state);
assert( isa(state.value,'casadi.MX') )