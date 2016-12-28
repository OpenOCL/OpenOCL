clear classes
clear all
f = CasadiExternalFunction();
f(2)
f.has_jacobian
f.jacobian(0,0)

casadi.Function('jacsd',{casadi.SX(1)},{casadi.SX(1)})