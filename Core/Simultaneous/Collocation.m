classdef Collocation < handle
  %COLLOCATION Collocation discretization of OCP to NLP
  %   Discretizes continuous OCP formulation to be solved as an NLP
  
  properties
    ocpHandler
    model
    N
    
    collocationPoints
    d
    
    C
    D
    B
    
    nx
    nu
    nz
    np
    
    nlpVars
  end
  
  methods
    
    function self = Collocation(ocp,model,N,d)
      
      self.ocpHandler = OCPHandler(ocp);
      self.model = model;
      self.N = N;
        
      self.collocationPoints = collocationPoints(d);
      
      self.d = d;
      
      [self.C,self.D,self.B] = self.getCoefficients;
      
      self.nx = prod(model.state.size);
      self.nu = prod(model.controls.size);
      self.nz = prod(model.algState.size);
      
      self.np = prod(self.ocpHandler.getParameters().size) ;
      
      state = Var('state', [self.nx 1]);
      controls = Var('controls', [self.nu 1]);
      colStates = Var('colStates',[self.nx self.d]);
      algVars = Var('algVars',[self.nz self.d]);
      
      self.nlpVars = Var('nlpVars');
      self.nlpVars.addRepeated([state,colStates,algVars,controls],self.N);
      self.nlpVars.add(state);
      
      if strcmp(self.ocpHandler.getEndTime, 'free')
        timeVar = Var('time',[1 1]);
        self.nlpVars.add(timeVar);
      end

    end
    
    
    function parameters = getParameters(self)
      parameters = self.ocpHandler.getParameters;
      parameters.set(0);
    end
    
    
    function initialGuess = getInitialGuess(self)
      
      collocationBlock = Var('colStateBlock');
      colState = self.model.state.copy;
      colState.id = 'colState';
      collocationBlock.addRepeated(colState,self.d);
      algStateBlock = Var('algVars');
      algStateBlock.addRepeated(self.model.algState,self.d);
      
      initialGuess = Var('nlpVars');
      initialGuess.addRepeated([self.model.state,...
                                collocationBlock,...
                                algStateBlock,...
                                self.model.controls],self.N);
      initialGuess.add(self.model.state);
      
      
      if strcmp(self.ocpHandler.getEndTime, 'free')
        timeVar = Var('time',[1 1]);
        initialGuess.add(timeVar);
      end
      
      initialGuess.compile;
      
      
      initialGuess.set(0);
      
      [lowerBounds,upperBounds] = self.ocpHandler.getBounds(initialGuess);
      
      lowVal = lowerBounds.value;
      upVal = upperBounds.value;
      
      guessValues = (lowVal + upVal) / 2;
      
      % set to lowerBounds if upperBounds are inf
      indizes = isinf(upVal);
      guessValues(indizes) = lowVal(indizes);
      
      % set to upperBounds of lowerBoudns are inf
      indizes = isinf(lowVal);
      guessValues(indizes) = upVal(indizes);
      
      % set to zero if both lower and upper bounds are inf
      indizes = isinf(lowVal) & isinf(upVal);
      guessValues(indizes) = 0;

      initialGuess.set(guessValues);
      
    end
    
    
    function [lowerBounds, upperBounds] = getBounds(self,nlpVars)
      
      [lowerBounds,upperBounds] = self.ocpHandler.getBounds(nlpVars);
      
    end
    
    
    function [C,D,B] = getCoefficients(self)
      
      tau_root = self.collocationPoints;
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
    
    
    function [cost,constraints,constraints_LB,constraints_UB] = evaluate(self,varValues,parameters)
      

      if strcmp(self.ocpHandler.getEndTime, 'free')
        h = varValues(end) / self.N;
      else
        h = self.ocpHandler.getEndTime / self.N;
      end
      
      thisTime = 0;
      
      constraints = [];
      constraints_LB = [];
      constraints_UB = [];
      cost = 0;

      initialState = varValues(1:self.nx,1);
      thisState = initialState;
      curIndex = self.nx;
      
      states = zeros(self.nx,self.N+1);
      states(:,1) = thisState;
      controls = zeros(self.nu,self.N);
      
      for k=1:self.N
        
        thisColStates = reshape(varValues(curIndex+1:curIndex+self.nx*self.d), self.nx, self.d);
        curIndex = curIndex+self.nx*self.d;
        
        thisAlgStates = reshape(varValues(curIndex+1:curIndex+self.nz*self.d), self.nz, self.d);
        curIndex = curIndex+self.nz*self.d;
  
        thisControl = varValues(curIndex+1:curIndex+self.nu);
        controls(:,k) = thisControl;
        curIndex = curIndex+self.nu;
        
        % Obtain collocation expressions
        [colEquations, stateFinal,J] = self.collocationIntervalFun(thisState,thisColStates,thisAlgStates,thisControl,h,parameters);
        
        thisAlgState = thisAlgStates(:,self.d);
%         lagrangeCost = self.ocpHandler.getLagrangeCost(thisState, thisAlgState, thisControl, thisTime);
        cost = cost + J;
        
        constraints = [constraints; colEquations];
        constraints_LB = [constraints_LB; zeros(size(colEquations))];
        constraints_UB = [constraints_UB; zeros(size(colEquations))];
        

        
        thisState = varValues(curIndex+1:curIndex+self.nx);
        states(:,k+1) = thisState;
        curIndex = curIndex+self.nx;
        
        [pathConstraint,lb,ub] = self.ocpHandler.pathConstraintsFun(thisState, thisAlgState, thisControl,thisTime,parameters);
        constraints = [constraints; pathConstraint];
        constraints_LB = [constraints_LB; lb];
        constraints_UB = [constraints_UB; ub];
        
        constraints = [constraints; thisState - stateFinal];
        constraints_LB = [constraints_LB; zeros(self.nx,1)];
        constraints_UB = [constraints_UB; zeros(self.nx,1)];
        
        thisTime = k*h;

      end
      
      % add terminal cost
      mayCost = self.ocpHandler.terminalCostsFun(thisState, thisTime,parameters);
      cost = cost + mayCost;
      
      % add least squares (tracking) cost
      vars = self.nlpVars.copy;
      vars.set(varValues);
      cost = cost + self.ocpHandler.leastSquaresCostFun(vars);

      % add terminal constraints
      [boundaryConditions,lb,ub] = self.ocpHandler.boundaryConditionsFun(initialState,thisState,parameters);
      constraints = [constraints; boundaryConditions];
      constraints_LB = [constraints_LB; lb];
      constraints_UB = [constraints_UB; ub];
      
    end
    

    function [colEquations, stateFinal,J] = collocationIntervalFun(self,thisState,thisColStates,thisAlgStates,thisControl,h,parameters)
      [colEquations, stateFinal,J] = self.collocationInterval(thisState,thisColStates,thisAlgStates,thisControl,h,parameters);
    end
    
    function [colEquations, stateFinal,J] = collocationInterval(self,thisState,thisColStates,thisAlgStates,thisControl,h,parameters)
      
      params = parameters.get('modelParams').flat;
      
      colEquations = [];
      J = 0;
      
      % Loop over collocation points
      stateFinal = self.D(1)*thisState;
      for j=1:self.d
         % Expression for the state derivative at the collocation point
         xp = self.C(1,j+1)*thisState;
         for r=1:self.d
             xp = xp + self.C(r+1,j+1)*thisColStates(:,r);
         end

         % Append collocation equations
         [ode,alg] = self.model.evaluate(thisColStates(:,j), ...
                                         thisAlgStates(:,j), ...
                                         thisControl,params);
         colEquations = [colEquations; h*ode-xp; alg];

         % Add contribution to the end state
         stateFinal = stateFinal + self.D(j+1)*thisColStates(:,j);

         % Add contribution to quadrature function
         qj = self.ocpHandler.pathCostsFun(thisColStates(:,j),thisAlgStates(:,j),thisControl,h,parameters.flat);
         J = J + self.B(j+1)*qj*h;
      end
      
    end
    
    function P = lagrangePolynomial(self,tau,i)
      
      P = 1;
      for j=1:self.d+1
        if j ~= i
          P = P * (tau-self.collocationPoints(j))/(self.collocationPoints(i)-self.collocationPoints(j));
        end
      end
      
    end

  end
  
end

