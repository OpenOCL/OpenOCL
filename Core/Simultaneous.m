classdef Simultaneous < handle
  %COLLOCATION Collocation discretization of OCP to NLP
  %   Discretizes continuous OCP formulation to be solved as an NLP
  
  properties
    nlpFun
    nlpVars
    integratorFun
    lowerBounds
    upperBounds
    
    scalingMin
    scalingMax
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

    
  end
  
  methods
    
    function self = Simultaneous(model,integrator,N)
      self.N = N;
      
      
      self.integratorFun = integrator.integratorFun;
      self.ni = integrator.getIntegratorVarsSize;
      
      self.model = model;
      
      self.isCollocation = true;
      
      
      state = model.state;
      self.stateVars = Var('states');
      self.stateVars.addRepeated({state},N+1);
      self.stateVars.compile;
      
      controls = model.controls;
      self.controlVars = Var('controls');
      self.controlVars.addRepeated({controls},N);
      self.controlVars.compile;
      
      
      integratorVars = integrator.getIntegratorVars;
      self.nlpVars = Var('nlpVars');
      self.nlpVars.addRepeated({self.model.state,...
                                integratorVars,...
                                self.model.controls},self.N);
      self.nlpVars.add(self.model.state);
      
      self.model.parameters.compile;
      self.nlpVars.add(self.model.parameters);
      self.nlpVars.add('time',[1 1]);
      
      self.nlpVars.compile;
      
      % initialize bounds
      self.lowerBounds = self.nlpVars.copy;
      self.upperBounds = self.nlpVars.copy;
      
      self.lowerBounds.set(-inf);
      self.upperBounds.set(inf);
      self.lowerBounds.get('time').set(0);
      
      self.scalingMin = self.lowerBounds.copy;
      self.scalingMax = self.upperBounds.copy;

    end
    
    function cost = getDiscreteCost(self,varValues)
      self.nlpVars.set(varValues);
      cost = self.ocpHandler.getDiscreteCost(self.nlpVars);
    end
    
    
    function initialGuess = getInitialGuess(self)
      
      initialGuess = self.nlpVars.copy;
      initialGuess.set(0);
      
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
    
    function interpolateGuess(self,guess)
      
      for i=1:self.N
        state = guess.get('state',i).flat;
        guess.get('integratorVars',i).get('state').set(state);
      end
      
    end
    
    
    function setBound(self,id,slice,lower,upper)
      % addBound(id,slice,lower,upper)
      % addBound(id,slice,value)
      
      if strcmp(slice,'end')
        slice = length(self.lowerBounds.get(id).subVars);
      end
      
      if nargin == 4
        upper = lower;
      end
      
      self.lowerBounds.getDeep(id,slice).set(lower);
      self.upperBounds.getDeep(id,slice).set(upper);
      
      self.scalingMin.getDeep(id,slice).set(lower);
      self.scalingMax.getDeep(id,slice).set(upper);
    end
    
    function setScaling(self,id,slice,valMin,valMax)

      if strcmp(slice,'end')
        slice = length(self.lowerBounds.get(id).subVars);
      end
      
      if valMin == valMax
        warning('Can not scale with zero range for the variable');
      end
      
      self.scalingMin.getDeep(id,slice).set(valMin);
      self.scalingMax.getDeep(id,slice).set(valMax);      
      
    end
    
    function checkScaling(self)
      
      if any(isinf(self.scalingMin.flat)) || any(isinf(self.scalingMax.flat))
        warning('Scaling information for some variable missing.');
      end
      
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
      
      nv = self.getNumberOfVars;
      pSize = self.getParameters.size;
      self.nlpFun = Function(@self.getNLPFun,{[nv 1], pSize},4);
    end

    function nv = getNumberOfVars(self)
      nv = self.N*self.nu + (self.N+1)*self.nx + self.N*self.ni+self.np+1;
    end
    
    function np = getNumberOfParameters(self)
      np = self.np;
    end

    function [costs,constraints,constraints_LB,constraints_UB] = getNLPFun(self,nlpInputs)
      
      T = nlpInputs(end);                         % end time
      parameters = nlpInputs(end-self.np:end-1);  % parameters

      timeGrid = linspace(0,T,self.N+1);
      
      constraints = [];
      constraints_LB = [];
      constraints_UB = [];
      costs = 0;
      
      initialState = nlpInputs(1:self.nx,1);
      thisState = initialState;
      curIndex = self.nx;
      
      for k=1:self.N
        
        thisIntegratorVars = nlpInputs(curIndex+1:curIndex+self.ni);
        curIndex = curIndex+self.ni;
        
        thisControl = nlpInputs(curIndex+1:curIndex+self.nu);
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

      % add terminal constraints
      [boundaryConditions,lb,ub] = self.ocpHandler.boundaryConditionsFun.evaluate(initialState,thisState,parameters);
      constraints = [constraints; boundaryConditions];
      constraints_LB = [constraints_LB; lb];
      constraints_UB = [constraints_UB; ub];
      
    end
  end
  
end

