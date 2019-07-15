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
    pathcostsfun
    
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

    function self = Collocation(states, algvars, controls, parameters, daefh, pathcostsfh, order)

      nx = length(states);
      nz = length(algvars);
      nu = length(controls);
      np = length(parameters);
      nt = order;
      
      v = OclStructure();
      v.addRepeated({'states', 'algvars'}, {states, algvars}, order);

      tau = [0 ocl.collocation.collocationPoints(order)];
      
      coeff = ocl.collocation.coefficients(tau);
      
      self.daefun = @(x,z,u,p) ocl.model.dae(daefh, states, algvars, controls, parameters, x, z, u, p);
      self.pathcostsfun = @(x,z,u,p) ocl.model.pathcosts(pathcostsfh, states, algvars, controls, parameters, x, z, u, p);
      
      self.coefficients = coeff;
      self.coeff_eval = ocl.collocation.evalCoefficients(coeff, order, 1.0);
      self.coeff_der = ocl.collocation.evalCoefficientsDerivative(coeff, tau, order);
      self.coeff_int = ocl.collocation.evalCoefficientsIntegral(coeff, order, 1.0);

      self.vars = v;
      self.num_x = nx;
      self.num_z = nz;
      self.num_u = nu;
      self.num_p = np;
      self.num_t = nt;
      
      self.num_i = length(v);
      
      self.tau_root = tau;
      self.order = order;
      
    end

  end
end
