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
%s
function r = evalCoefficientsIntegral(coeff, d, point)

ocl.utils.assert(point<=1 && point >=0);

r = zeros(d+1, 1);
for k=1:d+1
  % Evaluate the integral of the polynomial to get 
  % the coefficients of the quadrature function
  p_int = polyint(coeff(k,:));
  r(k) = polyval(p_int, point);
end