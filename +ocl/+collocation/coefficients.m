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
function coeff = coefficients(tau_root)
d = length(tau_root)-1; % order
coeff = zeros(d, d+1);
for j=1:d+1
  % Construct Lagrange polynomials to get the polynomial 
  % basis at the collocation point
  basis = 1;
  for r=1:d+1
    if r ~= j
      basis = conv(basis, [1, -tau_root(r)]);
      basis = basis / (tau_root(j)-tau_root(r));
    end
  end
  coeff(j,:) = basis;
end