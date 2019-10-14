% This class is derived from:
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

classdef Collocation < handle

  properties

    daefun
    pathcostfun
    
    coefficients
    coeff_eval
    coeff_der
    coeff_int

    vars
    num_x
    num_z
    num_u
    num_p
    num_t

    num_i
    
    tau_root
    order
  end

  methods

    function self = Collocation(states, algvars, controls, parameters, statesOrder, daefun, pathcostfun, d)

      nx = length(states);
      nz = length(algvars);
      nu = length(controls);
      np = length(parameters);
      nt = d;
      
      v = ocl.types.Structure();
      v.addRepeated({'states', 'algvars'}, {states, algvars}, d);

      tau = [0 ocl.collocation.collocationPoints(d)];
      
      coeff = ocl.collocation.coefficients(tau);
      
      self.daefun = daefun;
      self.pathcostfun = pathcostfun;
      
      self.coefficients = coeff;
      self.coeff_eval = ocl.collocation.evalCoefficients(coeff, d, 1.0);
      self.coeff_der = ocl.collocation.evalCoefficientsDerivative(coeff, tau, d);
      self.coeff_int = ocl.collocation.evalCoefficientsIntegral(coeff, d, 1.0);

      self.vars = v;
      self.num_x = nx;
      self.num_z = nz;
      self.num_u = nu;
      self.num_p = np;
      self.num_t = nt;
      
      self.num_i = length(v);
      
      self.tau_root = tau;
      self.order = d;
      
    end

  end
end
