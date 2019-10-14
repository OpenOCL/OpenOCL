function [ode,alg] = daefun(casadi_fun,x,z,u,p)
[ode,alg] = casadi_fun(x,z,u,p);