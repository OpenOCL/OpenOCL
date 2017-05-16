classdef CollocationIntegrator < ImplicitIntegrationScheme
  
  properties
    integratorFun
    integratorVarsStruct
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
  end
  
  
  methods
    
    function self = CollocationIntegrator(system,pathCostsFun,d)
      self = self@ImplicitIntegrationScheme(system);
      
      self.pathCostsFun = pathCostsFun;
      
      self.nx     = prod(self.system.statesStruct.size);
      self.nz     = prod(self.system.algVarsStruct.size);
      self.d      = d;
      self.ni     = d*self.nx+d*self.nz;
      np          = prod(system.parametersStruct.size);
      nu          = prod(system.controlsStruct.size);

      self.tau_root = collocationPoints(d);
      [self.C,self.D,self.B] = self.getCoefficients(self.tau_root);
      
      
      self.integratorVarsStruct = VarStructure('integratorVars');
      self.integratorVarsStruct.addRepeated({self.system.statesStruct,self.system.algVarsStruct},self.d);
      self.integratorVarsStruct.compile;
      
      time0 = VarStructure('time0',[1 1]);
      timeF = VarStructure('timeF', [1 1]);
      
      self.integratorFun = Function(@self.getIntegrator,{system.statesStruct,...
                                                    self.integratorVarsStruct,...
                                                    system.controlsStruct,...
                                                    time0,timeF,...
                                                    system.parametersStruct},4);
                                                  
    end

    function ni = getIntegratorVarsSize(self)
      ni          = self.ni;
    end
    
    function var = getIntegratorVars(self)
      var = self.integratorVars;
    end

    function [finalStates, finalAlgVars, costs, equations] = getIntegrator(self,states,integratorVars,controls,startTime,finalTime,parameters)
      
      h = finalTime-startTime;

      equations = Expression;
      J = Expression;
      
      % Loop over collocation points
      finalStates = self.D(1)*states;
      for j=1:self.d
         % Expression for the state derivative at the collocation point
         xp = self.C(1,j+1)*states;
         for r=1:self.d
             xp = xp + self.C(r+1,j+1)*integratorVars.get('states',r);
         end

         time = startTime + self.tau_root(j+1);

         % Append collocation equations
         [ode,alg] = self.system.evaluate(integratorVars.get('states',j), ...
                                         integratorVars.get('algVars',j), ...
                                         controls,parameters);
         equations = [equations; h*ode-xp; alg];

         % Add contribution to the end state
         finalStates = finalStates + self.D(j+1)*integratorVars.get('states',j);

         % Add contribution to quadrature function
         qj = self.pathCostsFun.evaluate(integratorVars.get('states',j),integratorVars.get('algVars',j),controls,time,parameters);
         J = J + self.B(j+1)*qj*h;
      end

      finalAlgVars = integratorVars.get('algVars',self.d);
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

