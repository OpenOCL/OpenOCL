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
    
    function self = CollocationIntegrator(system,d,parameters)
      self = self@ImplicitIntegrationScheme(system);
      
      
      self.nx     = prod(self.system.states.size);
      self.nz     = prod(self.system.algVars.size);
      self.d      = d;
      self.ni     = d*self.nx+d*self.nz;
      np          = prod(parameters.size);
      nu          = prod(system.controls.size);

      self.tau_root = collocationPoints(d);
      [self.C,self.D,self.B] = self.getCoefficients(self.tau_root);
      
      
      self.integratorVars = Var('integratorVars');
      self.integratorVars.addRepeated({self.system.states,self.system.algVars},self.d);
      self.integratorVars.compile;
      
      time0 = Var('time0',[1 1]);
      timeF = Var('timeF', [1 1]);
      
      self.integratorFun = Function(@self.evaluate,{self.system.states,...
                                                    self.integratorVars,...
                                                    self.system.controls,...
                                                    time0,timeF,parameters},4);
      
      
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

    function [finalStates, finalAlgVars, costs, equations] = evaluate(self,states,integratorVars,controls,startTime,finalTime,parameters)
      
      
      h = finalTime-startTime;
      
      self.integratorVars.set(integratorVars);

      % split integrator vars
%       colStateVars  = reshape(integratorVars(1:d*nx),nx,d);
%       algVars       = reshape(integratorVars(d*nx+1:end),nz,d);


      equations = [];
      J = 0;
      
      % Loop over collocation points
      finalStates = self.D(1)*states;
      for j=1:self.d
         % Expression for the state derivative at the collocation point
         xp = self.C(1,j+1)*states;
         for r=1:self.d
             xp = xp + self.C(r+1,j+1)*self.integratorVars.get('states',r).flat;
         end

         time = startTime + self.tau_root(j+1);

         % Append collocation equations
         [ode,alg] = self.system.systemFun.evaluate(self.integratorVars.get('states',j).flat, ...
                                         self.integratorVars.get('algVars',j).flat, ...
                                         controls,parameters);
         equations = [equations; h*ode-xp; alg];

         % Add contribution to the end state
         finalStates = finalStates + self.D(j+1)*self.integratorVars.get('states',j).flat;

         % Add contribution to quadrature function
         qj = self.pathCostsFun.evaluate(self.integratorVars.get('states',j).flat,self.integratorVars.get('algVars',j).flat,controls,time,parameters);
         J = J + self.B(j+1)*qj*h;
      end

      finalAlgVars = self.integratorVars.get('algVars',self.d).flat;
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

