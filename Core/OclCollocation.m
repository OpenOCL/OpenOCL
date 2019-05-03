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
    lagrangecostsfh
    
    integratorBounds
    
    vars
    nx
    nz
    nu
    np
    nt
    
    ni
  end
  
  properties(Access = private)
    B
    C
    D  
    tau_root
    order
  end
  
  methods
    
    function self = OclCollocation(states, algvars, controls, parameters, daefun, lagrangecostsfh, order)
      
      self.states = states;
      self.algvars = algvars;
      self.controls = controls;
      self.parameters = parameters;
      
      self.nx = prod(states.size());
      self.nz = prod(algvars.size());
      self.nu = prod(controls.size());
      self.np = prod(parameters.size());
      self.nt = order;
      
      self.daefun = daefun;
      self.lagrangecostsfh = lagrangecostsfh;
      
      self.order = order;
      self.tau_root = OclCollocation.colpoints(order);
      [self.C,self.D,self.B] = self.getCoefficients(order);
      
      self.vars = OclStructure();
      self.vars.addRepeated({'states', 'algvars'},...
                            {states, algvars}, order);
      
      si = self.vars.size();
      self.ni = prod(si);
      
      self.integratorBounds = OclBounds(-inf * ones(self.ni, 1), inf * ones(self.ni, 1));
                                      
    end
    
    function setStateBounds(self,id,varargin)
      x_lb = Variable.create(self.vars, self.integratorBounds.lower);
      x_ub = Variable.create(self.vars, self.integratorBounds.upper);
      
      bounds = OclBounds(varargin{:});
      
      x_lb.get('states').get(id).set(bounds.lower);
      x_ub.get('states').get(id).set(bounds.upper);
      
      self.integratorBounds.lower = x_lb.value;
      self.integratorBounds.upper = x_ub.value;
    end
    
    function setAlgvarBounds(self,id,varargin)
      lb = Variable.create(self.vars, self.integratorBounds.lower);
      ub = Variable.create(self.vars, self.integratorBounds.upper);
      
      bounds = OclBounds(varargin{:});
      
      lb.get('algvars').get(id).set(bounds.lower);
      ub.get('algvars').get(id).set(bounds.upper);
      
      self.integratorBounds.lower = lb.value;
      self.integratorBounds.upper = ub.value;
    end
    
    function r = lagrangecostfun(self,x,z,u,p)
      pcHandler = OclCost();
      
      x = Variable.create(self.states,x);
      z = Variable.create(self.algvars,z);
      u = Variable.create(self.controls,u);
      p = Variable.create(self.parameters,p);
      
      self.lagrangecostsfh(pcHandler,x,z,u,p);
      
      r = pcHandler.value;
    end

    function [statesEnd, costs, equations, rel_times] = ...
          integratorfun(self, statesBegin, integratorVars, ...
          controls, h, parameters)              
      
      equations = cell(self.order,1);
      J = 0;
      
      % Loop over collocation points
      statesEnd = self.D(1)*statesBegin;
      rel_times = cell(self.order,1);
      for j=1:self.order
        
        rel_times{j} = self.tau_root(j+1) * h;
        
        j_vars = (j-1)*(self.nx+self.nz);
        j_states = j_vars+1:j_vars+self.nx;
        j_algVars = j_vars+self.nx+1:j_vars+self.nx+self.nz;

        xp = self.C(1,j+1)*statesBegin;
        for r=1:self.order
          r_vars = (r-1)*(self.nx+self.nz);
          r_states = r_vars+1:r_vars+self.nx;
          xp = xp + self.C(r+1,j+1)*integratorVars(r_states);
        end

        % Append collocation equations
        [ode,alg] = self.daefun(integratorVars(j_states), ...
                           integratorVars(j_algVars), ...
                           controls,parameters);
                                                 
        equations{j} = [h*ode-xp; alg];

        % Add contribution to the end state
        statesEnd = statesEnd + self.D(j+1)*integratorVars(j_states);

        % Add contribution to quadrature function
        qj = self.lagrangecostfun(integratorVars(j_states),integratorVars(j_algVars),controls,parameters);
        J = J + self.B(j+1)*qj*h;
      end

      costs = J;
      equations = vertcat(equations{:});
      rel_times = vertcat(rel_times{:});
    end
  end

  methods (Access = private)

    function [C,D,B] = getCoefficients(self, d)
      
      % Coefficients of the collocation equation
      C = zeros(d+1,d+1);

      % Coefficients of the continuity equation
      D = zeros(d+1, 1);

      % Coefficients of the quadrature function
      B = zeros(d+1, 1);

      % Construct polynomial basis
      for j=1:d+1
        % Construct Lagrange polynomials to get the polynomial basis at the collocation point
        coeff = 1;
        for r=1:d+1
          if r ~= j
            coeff = conv(coeff, [1, -self.tau_root(r)]);
            coeff = coeff / (self.tau_root(j)-self.tau_root(r));
          end
        end
        % Evaluate the polynomial at the final time to get the coefficients of the continuity equation
        D(j) = polyval(coeff, 1.0);

        % Evaluate the time derivative of the polynomial at all collocation points to get the coefficients of the continuity equation
        pder = polyder(coeff);
        for r=1:d+1
          C(j,r) = polyval(pder, self.tau_root(r));
        end

        % Evaluate the integral of the polynomial to get the coefficients of the quadrature function
        pint = polyint(coeff);
        B(j) = polyval(pint, 1.0);
      end
    end
    
  end
  
  methods (Static)
    function [ times ] = colpoints( d )
      if d == 2
        times = [0 0.33333333333333333333333333333333, 1.0];
      elseif d == 3
        times = [0 0.15505102572168222296866701981344, 0.64494897427831787695140519645065, 1.0];
      elseif d == 4
        times = [0 0.088587959512704206321842548277345, 0.4094668644407346569380479195388, 0.7876594617608470016989485884551, 1.0];
      elseif d == 5
        times = [0 0.057104196114518224192124762339517, 0.27684301363812369167760607524542, 0.5835904323689168338162858162832, 0.86024013565621926247217743366491, 1.0];
      else
        error('Only collocation order between 2 and 5 is supported.');
      end
    end
  end
  
end

