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
function r = evalCoefficientsDerivative(coeff, tau_root, d)
r = zeros(d+1, d+1);
for k=1:d+1
  pder = polyder(coeff(k,:));
  for j=1:d+1
    r(k,j) = polyval(pder, tau_root(j));
  end
end
