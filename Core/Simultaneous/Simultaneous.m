classdef Simultaneous < handle
  %COLLOCATION Collocation discretization of OCP to NLP
  %   Discretizes continuous OCP formulation to be solved as an NLP
  
  properties
    nlpFun
    nlpVars
    integratorFun
  end
  
  properties(Access = private)
    ocpHandler
    N
    model
    
    nx
    nu
    ni
    np
    
    stateVars
    controlVars
    
    isCollocation
    lowerBounds
    upperBounds
    
  end
  
  methods
    
    function self = Simultaneous(model,integrator,N,endTime)
      self.N = N;
      
      
      self.integratorFun = integrator.integratorFun;
      self.ni = integrator.getIntegratorVarsSize;
      
      self.model = model;
      
      self.nlpFun = Function(@self.getNLPFun,2,4);
      
      self.isCollocation = true;
      
      
      state = model.state;
      self.stateVars = Var('states');
      self.stateVars.addRepeated(state,N+1);
      self.stateVars.compile;
      
      controls = model.controls;
      self.controlVars = Var('controls');
      self.controlVars.addRepeated(controls,N);
      self.controlVars.compile;
      
      
      integratorVars = integrator.getIntegratorVars;
      self.nlpVars = Var('nlpVars');
      self.nlpVars.addRepeated([self.model.state,...
                                integratorVars,...
                                self.model.controls],self.N);
      self.nlpVars.add(self.model.state);
      
      if strcmp(endTime, 'free')
        timeVar = Var('time',[1 1]);
        self.nlpVars.add(timeVar);
      end
      
      self.nlpVars.compile;


    end
    
    function parameters = getParameters(self)
      parameters = self.ocpHandler.getParameters;
      parameters.set(0);
    end  
    
    function getCallback(self,var,values)
      self.ocpHandler.callbackFunction(var,values);
    end
    
    
    function setOcpHandler(self,ocpHandler)
      self.ocpHandler = ocpHandler;
      self.nx = ocpHandler.getStatesSize;
      self.nu = ocpHandler.getControlsSize;
      self.np = ocpHandler.getParametersSize;
    end

    function nv = getNumberOfVars(self)
      nv = self.N*self.nu + (self.N+1)*self.nx + self.N*self.ni;
      
      if strcmp(self.ocpHandler.getEndTime, 'free')
        nv = nv+1;
      end
      
    end
    
    function np = getNumberOfParameters(self)
      np = self.np;
    end
    
    function [lb,ub] = getBounds(self)
      lb = self.lowerBounds;
      ub = self.upperBounds;
    end

    
    function [costs,constraints,constraints_LB,constraints_UB] = getNLPFun(self,nlpInputs,parameters)
      

      if strcmp(self.ocpHandler.getEndTime, 'free')
        T = nlpInputs(end);
      else
        T = self.ocpHandler.getEndTime;
      end

      timeGrid = linspace(0,T,self.N+1);
      
      constraints = [];
      constraints_LB = [];
      constraints_UB = [];
      costs = 0;
      
      initialState = nlpInputs(1:self.nx,1);
      thisState = initialState;
      curIndex = self.nx;
      
      states = cell(1,self.N+1);
      states{1} = initialState;
      controls = cell(1,self.N);
      
      for k=1:self.N
        
        thisIntegratorVars = nlpInputs(curIndex+1:curIndex+self.ni);
        curIndex = curIndex+self.ni;
        
        thisControl = nlpInputs(curIndex+1:curIndex+self.nu);
        controls{k} = thisControl;
        curIndex = curIndex+self.nu;
        
        % add integrator equation in case of direction collocation
        % or call integrator in case of multiple shooting
        if self.isCollocation

          [finalState, finalAlgVars, integrationCosts, integratorEquations] = self.integratorFun.evaluate(thisState,thisIntegratorVars,thisControl,timeGrid(k),timeGrid(k+1),parameters);
          
          constraints = [constraints; integratorEquations];
          constraints_LB = [constraints_LB; zeros(size(integratorEquations))];
          constraints_UB = [constraints_UB; zeros(size(integratorEquations))];

        else
          [finalState, finalAlgVars, integrationCosts] = self.integratorFun.evaluate(thisState,thisControl,timeGrid(k),timeGrid(k+1),parameters);
        end
        
        

        costs = costs + integrationCosts;
        
        % go to next time gridpoint
        thisState = nlpInputs(curIndex+1:curIndex+self.nx);
        states{k+1} = thisState;
        curIndex = curIndex+self.nx;
        
        % path constraints
        [pathConstraint,lb,ub] = self.ocpHandler.pathConstraintsFun.evaluate(thisState, finalAlgVars, thisControl,timeGrid(k+1),parameters);
        constraints = [constraints; pathConstraint];
        constraints_LB = [constraints_LB; lb];
        constraints_UB = [constraints_UB; ub];
        
        % continuity equation
        constraints = [constraints; thisState - finalState];
        constraints_LB = [constraints_LB; zeros(self.nx,1)];
        constraints_UB = [constraints_UB; zeros(self.nx,1)];
      end
      
      % add terminal cost
      terminalCosts = self.ocpHandler.terminalCostsFun.evaluate(thisState,T,parameters);
      costs = costs + terminalCosts;
      
      % add least squares (tracking) cost
      self.stateVars.set([states{:}]);
      self.controlVars.set([controls{:}]);
      costs = costs + self.ocpHandler.leastSquaresCostsFun.evaluate(self.stateVars,self.controlVars);

      % add terminal constraints
      [boundaryConditions,lb,ub] = self.ocpHandler.boundaryConditionsFun.evaluate(initialState,thisState,parameters);
      constraints = [constraints; boundaryConditions];
      constraints_LB = [constraints_LB; lb];
      constraints_UB = [constraints_UB; ub];
      
    end
    
    
    function initialGuess = getInitialGuess(self)
      
      initialGuess = self.nlpVars;
      
      
      initialGuess.set(0);
      
      [self.lowerBounds,self.upperBounds] = self.ocpHandler.getBounds(initialGuess);
      
      lowVal = self.lowerBounds.value;
      upVal = self.upperBounds.value;
      
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

  end
  
end

