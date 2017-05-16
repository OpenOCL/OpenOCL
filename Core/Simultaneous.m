classdef Simultaneous < handle
  %COLLOCATION Collocation discretization of OCP to NLP
  %   Discretizes continuous OCP formulation to be solved as an NLP
  
  properties
    nlpFun
    nlpVarsStruct
    integratorFun
    lowerBounds
    upperBounds
    
    scalingMin
    scalingMax
    
    system
  end
  
  properties(Access = private)
    ocpHandler
    N
    
    
    nx
    nu
    ni
    np
    
    stateVars
    controlVars
  end
  
  methods
    
    function self = Simultaneous(system,integrator,ocpHandler,N)
      
      self.N = N;
      self.ocpHandler = ocpHandler;
      
      
      self.integratorFun = integrator.integratorFun;
      self.ni = integrator.getIntegratorVarsSize;
      
      self.system = system;
      
      integratorVarsStruct = integrator.integratorVarsStruct;
      self.nlpVarsStruct = VarStructure('nlpVars');
      self.nlpVarsStruct.addRepeated({system.statesStruct,...
                                      integratorVarsStruct,...
                                      system.controlsStruct},self.N);
      self.nlpVarsStruct.add(system.statesStruct);
      
%       system.parametersStruct.compile;
      self.nlpVarsStruct.add(self.system.parametersStruct);
      self.nlpVarsStruct.add('time',[1 1]);
      
      self.nlpVarsStruct.compile;
      
      % initialize bounds      
      self.lowerBounds = Var(self.nlpVarsStruct,-inf);
      self.upperBounds = Var(self.nlpVarsStruct,inf);
      self.lowerBounds.get('time').set(0);
      
      self.scalingMin = Var(self.nlpVarsStruct,0);
      self.scalingMax = Var(self.nlpVarsStruct,1);

    end
    
    function setOcpHandler(self,ocpHandler)
      self.ocpHandler = ocpHandler;
      self.nx = ocpHandler.getStatesSize;
      self.nu = ocpHandler.getControlsSize;
      self.np = ocpHandler.getParametersSize;
      
      nv = self.getNumberOfVars;
      pSize = self.getParameters.size;
      self.nlpFun = Function(@self.getNLPFun,{self.nlpVars},5);
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
        state = guess.get('states',i).flat;
        guess.get('integratorVars',i).get('states').set(state);
      end
      
    end
    
    
    function setBound(self,id,slice,lower,upper)
      % addBound(id,slice,lower,upper)
      % addBound(id,slice,value)
      
      if strcmp(slice,'end')
        slice = length(self.lowerBounds.getDeep(id).subVars);
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
        error('Can not scale with zero range for the variable');
      end
      
      self.scalingMin.getDeep(id,slice).set(valMin);
      self.scalingMax.getDeep(id,slice).set(valMax);      
      
    end
    
    function checkScaling(self)
      
      if any(isinf(self.scalingMin.flat)) || any(isinf(self.scalingMax.flat))
        error('Scaling information for some variable missing. Provide scaling for all variables or set scaling option to false.');
      end
      
    end
    
    function parameters = getParameters(self)
      parameters = self.ocpHandler.getParameters;
      parameters.set(0);
    end  
    
    function getCallback(self,var,values)
      self.ocpHandler.callbackFunction(var,values);
    end
    
    


    function nv = getNumberOfVars(self)
      nv = self.N*self.nu + (self.N+1)*self.nx + self.N*self.ni+self.np+1;
    end
    
    function np = getNumberOfParameters(self)
      np = self.np;
    end

    function [costs,constraints,constraints_LB,constraints_UB,timeGrid] = getNLPFun(self,nlpInputs)
      
      T = nlpInputs(end);                         % end time
      parameters = nlpInputs(end-self.np:end-1);  % parameters

      timeGrid = linspace(0,T,self.N+1);
      
      constraints = [];
      constraints_LB = [];
      constraints_UB = [];
      costs = 0;
      
      initialStates = nlpInputs(1:self.nx,1);
      thisStates = initialStates;
      curIndex = self.nx;
      
      for k=1:self.N
        
        thisIntegratorVars = nlpInputs(curIndex+1:curIndex+self.ni);
        curIndex = curIndex+self.ni;
        
        thisControl = nlpInputs(curIndex+1:curIndex+self.nu);
        curIndex = curIndex+self.nu;
        
        % add integrator equation of direction collocation
        [finalStates, finalAlgVars, integrationCosts, integratorEquations] = self.integratorFun.evaluate(thisStates,thisIntegratorVars,thisControl,timeGrid(k),timeGrid(k+1),parameters);

        constraints = [constraints; integratorEquations];
        constraints_LB = [constraints_LB; zeros(size(integratorEquations))];
        constraints_UB = [constraints_UB; zeros(size(integratorEquations))];
        
        costs = costs + integrationCosts;
        
        % go to next time gridpoint
        thisStates = nlpInputs(curIndex+1:curIndex+self.nx);
        curIndex = curIndex+self.nx;
        
        % path constraints
        [pathConstraint,lb,ub] = self.ocpHandler.pathConstraintsFun.evaluate(thisStates, finalAlgVars, thisControl,timeGrid(k+1),parameters);
        constraints = [constraints; pathConstraint];
        constraints_LB = [constraints_LB; lb];
        constraints_UB = [constraints_UB; ub];
        
        % continuity equation
        constraints = [constraints; thisStates - finalStates];
        constraints_LB = [constraints_LB; zeros(self.nx,1)];
        constraints_UB = [constraints_UB; zeros(self.nx,1)];
      end
      
      % add terminal cost
      terminalCosts = self.ocpHandler.arrivalCostsFun.evaluate(thisStates,T,parameters);
      costs = costs + terminalCosts;

      % add terminal constraints
      [boundaryConditions,lb,ub] = self.ocpHandler.boundaryConditionsFun.evaluate(initialStates,thisStates,parameters);
      constraints = [constraints; boundaryConditions];
      constraints_LB = [constraints_LB; lb];
      constraints_UB = [constraints_UB; ub];
      
    end
  end
  
end

