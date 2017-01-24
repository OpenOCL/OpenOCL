classdef CollocationIntegrator < ImplicitIntegrationScheme
  
  properties
    integratorFun
  end
  
  properties(Access = private)
    ni
    nx
    nz
    d

    tau_root
    B
    C
    D
    pathCostsFun
    
    integratorVars
    
  end
  
  
  methods
    
    function self = CollocationIntegrator(model,d,parameters)
      self = self@ImplicitIntegrationScheme(model);
      
      
      self.nx     = prod(self.model.state.size);
      self.nz     = prod(self.model.algState.size);
      self.d      = d;
      self.ni     = d*self.nx+d*self.nz;
      np          = prod(parameters.size);
      nu          = prod(model.controls.size);

      self.tau_root = collocationPoints(d);
      [self.C,self.D,self.B] = self.getCoefficients(self.tau_root);
      
      
      self.integratorVars = Var('integratorVars');
      self.integratorVars.addRepeated(self.model.state,self.d);
      self.integratorVars.addRepeated(self.model.algState,self.d);
      self.integratorVars.compile;
      
      self.integratorFun = Function(@self.evaluate,{[self.nx 1],[self.ni 1],[nu 1],[1 1],[1 1],[np 1]},4);
      
      
    end
    
    function setPathCostsFun(self,pathCostsFun)
      self.pathCostsFun = pathCostsFun;
    end

    function ni = getIntegratorVarsSize(self)
      ni          = self.ni;
    end
    
    function var = getIntegratorVars(self)
      var = self.integratorVars;
    end

    function [finalState, finalAlgVars, costs, equations] = evaluate(self,state,integratorVars,controls,startTime,finalTime,parameters)
      
      
      h = finalTime-startTime;
      
      self.integratorVars.set(integratorVars);

      % split integrator vars
%       colStateVars  = reshape(integratorVars(1:d*nx),nx,d);
%       algVars       = reshape(integratorVars(d*nx+1:end),nz,d);


      equations = [];
      J = 0;
      
      % Loop over collocation points
      finalState = self.D(1)*state;
      for j=1:self.d
         % Expression for the state derivative at the collocation point
         xp = self.C(1,j+1)*state;
         for r=1:self.d
             xp = xp + self.C(r+1,j+1)*self.integratorVars.get('state',r).flat;
         end

         time = startTime + self.tau_root(j+1);

         % Append collocation equations
         [ode,alg] = self.model.modelFun.evaluate(self.integratorVars.get('state',j).flat, ...
                                         self.integratorVars.get('algState',j).flat, ...
                                         controls,parameters);
         equations = [equations; h*ode-xp; alg];

         % Add contribution to the end state
         finalState = finalState + self.D(j+1)*self.integratorVars.get('state',j).flat;

         % Add contribution to quadrature function
         qj = self.pathCostsFun.evaluate(self.integratorVars.get('state',j).flat,self.integratorVars.get('algState',j).flat,controls,time,parameters);
         J = J + self.B(j+1)*qj*h;
      end

      finalAlgVars = self.integratorVars.get('algState',1).flat;
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

