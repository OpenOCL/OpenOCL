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

classdef CollocationIntegrator < handle
  
  properties
    system
    integratorFun
    integratorVarsStruct
  end
  
  properties(Access = private)
    d
    tau_root
    B
    C
    D
    pathCostsFun    
  end
  
  
  methods
    
    function self = CollocationIntegrator(system,pathCostsFun,d)
      
      self.system = system;
      self.pathCostsFun = pathCostsFun;
      self.d            = d;
      

      self.tau_root = collocationPoints(d);
      [self.C,self.D,self.B] = self.getCoefficients(self.tau_root);
      
      self.integratorVarsStruct = OclTree();
      self.integratorVarsStruct.addRepeated({'states','algVars'},{self.system.statesStruct,self.system.algVarsStruct},self.d);
      
      time0 = OclMatrix([1,1]);
      timeF = OclMatrix([1,1]);
      endTime = OclMatrix([1,1]);
      

      fh = @(self,varargin)self.getIntegrator(varargin{:});
      self.integratorFun = Function(self, fh, {size(system.statesStruct),...
                                               size(self.integratorVarsStruct),...
                                               size(system.controlsStruct),...
                                               [1,1],[1,1],[1,1],...
                                               size(system.parametersStruct)},...
                                               4);
                                                  
    end

    function [statesEnd, AlgVarsEnd, costs, equations] = getIntegrator(self,statesBegin,integratorStates,integratorAlgVars,...
                                                                         controls,startTime,finalTime,endTime,parameters)
                                                                         
      h = finalTime-startTime;

      equations = [];
      J = 0;
      
      nx = size(self.system.statesStruct);
      nz = size(self.system.algVarsStruct)
      
      % alVars,states,algVars,states
      integratorVars()
      
      % Loop over collocation points
      statesEnd = self.D(1)*statesBegin;
      for j=1:self.d

         xp = self.C(1,j+1)*states;
         for r=1:self.d
             xp = xp + self.C(r+1,j+1)*integratorStates{r};
         end

         time = startTime + self.tau_root(j+1) * h;

         % Append collocation equations
         [ode,alg] = self.system.evaluate(integratorStates{j}, ...
                                          integratorAlgVars{j}, ...
                                          controls,parameters);
         equations = [equations; h*ode-xp; alg];

         % Add contribution to the end state
         statesEnd = statesEnd + self.D(j+1)*integratorStates{j};

         % Add contribution to quadrature function
         qj = self.pathCostsFun.evaluate(integratorStates{j},integratorAlgVars{j},controls,time,endTime,parameters);
         J = J + self.B(j+1)*qj*h;
      end

      AlgVarsEnd = integratorAlgVars{self.d};
      costs = J;
    end
  end

  methods (Access = private)

    function [C,D,B] = getCoefficients(self,tau_root)
      
      d = self.d;
      
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
            coeff = conv(coeff, [1, -tau_root(r)]);
            coeff = coeff / (tau_root(j)-tau_root(r));
          end
        end
        % Evaluate the polynomial at the final time to get the coefficients of the continuity equation
        D(j) = polyval(coeff, 1.0);

        % Evaluate the time derivative of the polynomial at all collocation points to get the coefficients of the continuity equation
        pder = polyder(coeff);
        for r=1:d+1
          C(j,r) = polyval(pder, tau_root(r));
        end

        % Evaluate the integral of the polynomial to get the coefficients of the quadrature function
        pint = polyint(coeff);
        B(j) = polyval(pint, 1.0);
      end
    end
    
  end
  
end

