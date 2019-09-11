% This function is derived from:
%
% An implementation of direct collocation
% Joel Andersson, 2016
% https://github.com/casadi/casadi/blob/master/docs/examples/matlab/direct_collocation.m
%
% CasADi -- A symbolic framework for dynamic optimization.
% Copyright (C) 2010-2014 Joel Andersson, Joris Gillis, Moritz Diehl,
%                         K.U. Leuven. All rights reserved.
% Copyright (C) 2011-2014 Greg Horn
% Under GNU Lesser General Public License
%
function [xF, costs, equations] = ...
  equations(colloc, x0, vars, u, h, params)

C = colloc.coeff_der;
B = colloc.coeff_int;

d = colloc.order;

nx = colloc.num_x;
nz = colloc.num_z;

equations = cell(d,1);
J = 0;

[x,z] = ocl.collocation.variablesUnpack(vars, nx, nz, d);

% Loop over collocation points
for j=1:d
  
  x_der = C(1,j+1)*x0;
  for r=1:d
    x_r = x(:,r);
    x_der = x_der + C(r+1,j+1)*x_r;
  end
  
  x_j = x(:,j);
  z_j = z(:,j);
  
  [ode,alg] = colloc.daefun(x_j, z_j, u, params);
  
  qj = colloc.pathcostfun(x_j, z_j, u, params);
  
  equations{j} = [h*ode-x_der; alg];
  J = J + B(j+1)*qj*h;
end

costs = J;
equations = vertcat(equations{:});

xF = ocl.collocation.getStateAtPoint(colloc, x0, vars, 1.0);
