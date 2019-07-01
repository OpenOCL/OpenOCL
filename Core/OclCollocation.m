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

classdef OclCollocation < handle

  properties

    states
    algvars
    controls
    parameters

    daefun
    pathcostsfh

    integratorBounds
    stateBounds
    algvarBounds

    vars
    num_x
    num_z
    num_u
    num_p
    num_t

    num_i
    
    coefficients
    coeff_eval
    coeff_der
    coeff_int
    tau_root
    order
  end

  methods

    function self = OclCollocation(states, algvars, controls, parameters, daefun, pathcostsfh, order, ...
                                   stateBounds, algvarBounds)

      self.states = states;
      self.algvars = algvars;
      self.controls = controls;
      self.parameters = parameters;

      nx = prod(states.size());
      nz = prod(algvars.size());
      nu = prod(controls.size());
      np = prod(parameters.size());
      nt = order;

      self.daefun = daefun;
      self.pathcostsfh = pathcostsfh;
      
      tau = [0 ocl.collocation.collocationPoints(order)];
      
      coeff = ocl.collocation.coefficients(tau);
      self.coeff_eval = ocl.collocation.evalCoefficients(coeff, order, 1.0);
      self.coeff_der = ocl.collocation.evalCoefficientsDerivative(coeff, tau, order);
      self.coeff_int = ocl.collocation.evalCoefficientsIntegral(coeff, order, 1.0);
      
      self.vars = OclStructure();
      self.vars.addRepeated({'states', 'algvars'},...
                            {states, algvars}, order);

      si = self.vars.size();
      ni = prod(si);

      self.integratorBounds = OclBounds(-inf * ones(ni, 1), inf * ones(ni, 1));
      self.stateBounds = OclBounds(-inf * ones(nx, 1), inf * ones(nx, 1));
      self.algvarBounds = OclBounds(-inf * ones(nz, 1), inf * ones(nz, 1));

      names = fieldnames(stateBounds);
      for k=1:length(names)
        id = names{k};
        self.setStateBounds(id, stateBounds.(id).lower, stateBounds.(id).upper);
      end

      names = fieldnames(algvarBounds);
      for k=1:length(names)
        id = names{k};
        self.setAlgvarBounds(id, algvarBounds.(id).lower, algvarBounds.(id).upper);
      end
      
      self.num_x = nx;
      self.num_z = nz;
      self.num_u = nu;
      self.num_p = np;
      self.num_t = nt;
      self.num_i = ni;
      self.coefficients = coeff;
      self.tau_root = tau;
      self.order = order;
    end

    function [xF, costs, equations, rel_times] = ...
          integratorfun(self, x0, vars, u, h, params)

      C = self.coeff_der;
      B = self.coeff_int;
      
      tau = self.tau_root;
      d = self.order;
      
      nx = self.num_x;
      nz = self.num_z;
        
      equations = cell(d,1);
      J = 0;
      
      [x_indizes, z_indizes] = ocl.collocation.indizes(nx,nz,d);

      % Loop over collocation points
      rel_times = cell(d,1);
      for j=1:d
        
        x_der = C(1,j+1)*x0;
        for r=1:d
          x_r = vars(x_indizes(:,r));
          x_der = x_der + C(r+1,j+1)*x_r;
        end
        
        x_j = vars(x_indizes(:,j));
        z_j = vars(z_indizes(:,j));

        [ode,alg] = self.daefun(x_j, z_j, u, params);

        qj = self.pathcostfun(x_j, z_j,u,params);
        
        equations{j} = [h*ode-x_der; alg];
        J = J + B(j+1)*qj*h;
        
        rel_times{j} = tau(j+1) * h;
      end

      costs = J;
      equations = vertcat(equations{:});
      rel_times = vertcat(rel_times{:});
      
      xF = ocl.collocation.getStateAtPoint(self, x0, vars, 1.0);
      
    end

    function r = getInitialGuess(self, stateGuess, algvarGuess)
      ig = Variable.create(self.vars, 0);
      ig.states.set(stateGuess);
      ig.algvars.set(algvarGuess);
      r = ig.value;
    end

    function setStateBounds(self,id,varargin)
      % integrator
      lb = Variable.create(self.vars, self.integratorBounds.lower);
      ub = Variable.create(self.vars, self.integratorBounds.upper);

      bounds = OclBounds(varargin{:});

      lb.get('states').get(id).set(bounds.lower);
      ub.get('states').get(id).set(bounds.upper);

      self.integratorBounds.lower = lb.value;
      self.integratorBounds.upper = ub.value;
      
      % states
      x_lb = Variable.create(self.states, self.stateBounds.lower);
      x_ub = Variable.create(self.states, self.stateBounds.upper);

      bounds = OclBounds(varargin{:});

      x_lb.get(id).set(bounds.lower);
      x_ub.get(id).set(bounds.upper);

      self.stateBounds.lower = x_lb.value;
      self.stateBounds.upper = x_ub.value;
    end

    function setAlgvarBounds(self,id,varargin)
      % integrator vars 
      lb = Variable.create(self.vars, self.integratorBounds.lower);
      ub = Variable.create(self.vars, self.integratorBounds.upper);

      bounds = OclBounds(varargin{:});

      lb.get('algvars').get(id).set(bounds.lower);
      ub.get('algvars').get(id).set(bounds.upper);

      self.integratorBounds.lower = lb.value;
      self.integratorBounds.upper = ub.value;
      
      % algvars
      z_lb = Variable.create(self.algvars, self.algvarBounds.lower);
      z_ub = Variable.create(self.algvars, self.algvarBounds.upper);

      bounds = OclBounds(varargin{:});

      z_lb.get(id).set(bounds.lower);
      z_ub.get(id).set(bounds.upper);

      self.algvarBounds.lower = z_lb.value;
      self.algvarBounds.upper = z_ub.value;
    end

    function r = pathcostfun(self,x,z,u,p)
      pcHandler = OclCost();

      x = Variable.create(self.states,x);
      z = Variable.create(self.algvars,z);
      u = Variable.create(self.controls,u);
      p = Variable.create(self.parameters,p);

      self.pathcostsfh(pcHandler,x,z,u,p);

      r = pcHandler.value;
    end
  end

end
