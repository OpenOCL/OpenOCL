classdef Simultaneous < handle
  %COLLOCATION Collocation discretization of OCP to NLP
  %   Discretizes continuous OCP formulation to be solved as an NLP
  
  properties
    nlpFun
    nlpVarsStruct
    integratorFun
    system
    
    lowerBounds
    upperBounds
    scalingMin
    scalingMax
  end
  
  properties(Access = private)
    ocpHandler
    N
  end
  
  methods
    
    function self = Simultaneous(system,integrator,ocpHandler,N)
      
      self.N = N;
      self.ocpHandler = ocpHandler;
      
      self.integratorFun = integrator.integratorFun;
      self.system = system;
      
      integratorVarsStruct = integrator.integratorVarsStruct;
      self.nlpVarsStruct = TreeNode('nlpVars');
      self.nlpVarsStruct.addRepeated({system.statesStruct,...
                                      integratorVarsStruct,...
                                      system.controlsStruct},self.N);
      self.nlpVarsStruct.add(system.statesStruct);
      
%       system.parametersStruct.compile;
      self.nlpVarsStruct.add(self.system.parametersStruct);
      self.nlpVarsStruct.add('time',[1 1]);
      
      self.nlpVarsStruct.compile;
      
      % initialize bounds      
      nlpVarsFlatFlat = self.nlpVarsStruct.getFlat;
      
      self.lowerBounds = Arithmetic(nlpVarsFlatFlat,-inf);
      self.upperBounds = Arithmetic(nlpVarsFlatFlat,inf);
      self.lowerBounds.get('time').set(0);
      
      self.scalingMin = Arithmetic(nlpVarsFlatFlat,0);
      self.scalingMax = Arithmetic(nlpVarsFlatFlat,1);
      
      self.nlpFun = Function(@self.getNLPFun,{self.nlpVarsStruct},5);

    end    
    
    function initialGuess = getInitialGuess(self)
      
      initialGuess = Arithmetic(self.nlpVarsStruct,0);
      
      lowVal  = self.lowerBounds.value;
      upVal   = self.upperBounds.value;
      
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
        state = guess.get('states',i).value;
        guess.get('integratorVars',i).get('states').set(state);
      end
      
    end
    
    function setParameter(self,id,varargin)
      % setParameter(id,lower,upper)
      % setParameter(id,value)     
      self.setBound(id,1,varargin{:},false)
    end
    
    function setInitialBounds(self,id,varargin)
      % setInitialBound(id,lower,upper)
      % setInitialBound(id,value)     
      self.setBound(id,1,varargin{:},false)
    end
    
    function setEndBounds(self,id,varargin)
      % setEndBound(id,lower,upper)
      % setEndBound(id,value)     
      self.setBound(id,'end',varargin{:},false)
    end
    
    function setBounds(self,id,varargin)
      % setVariableBound(id,lower,upper)
      % setVariableBound(id,value)     
      self.setBound(id,':',varargin{:})
    end
    
    function setBound(self,id,slice,varargin)
      % addBound(id,slice,lower,upper,showWarning=true)
      % addBound(id,slice,value,showWarning=true)
      
      if nargin == 4
        lower = varargin{1};
        upper = varargin{1};
        showWarning = true;
      elseif nargin == 5
        if islogical(varargin{2})
          lower = varargin{1};
          upper = varargin{1};
          showWarning = varargin{2};
        else
          lower = varargin{1};
          upper = varargin{2};
          showWarning = true;
        end
      elseif nargin == 6
          lower = varargin{1};
          upper = varargin{2};
          showWarning = varargin{3};
      end
      
      if showWarning && (any(~isinf(self.lowerBounds.get(id,slice).value)) || ...
         any(~isinf(self.upperBounds.get(id,slice).value)))
        warning('Existing bound overwritten. Make sure that setBounds is always called before setInitialBounds and setEndBounds');
      end
      
      self.lowerBounds.get(id,slice).set(lower);
      self.upperBounds.get(id,slice).set(upper);
      
      self.scalingMin.get(id,slice).set(lower);
      self.scalingMax.get(id,slice).set(upper);
    end
    
    function setVariableScaling(self,id,varargin)
      % setVariableScaling(id,lower,upper)
      % setVariableScaling(id,value)     
      self.setScaling(id,':',varargin{:})
    end
    
    function setScaling(self,id,slice,valMin,valMax)
      
      if valMin == valMax
        error('Can not scale with zero range for the variable');
      end
      self.scalingMin.get(id,slice).set(valMin);
      self.scalingMax.get(id,slice).set(valMax);     
      
    end
    
    function checkScaling(self)
      
      if any(isinf(self.scalingMin.value)) || any(isinf(self.scalingMax.value))
        error('Scaling information for some variable missing. Provide scaling for all variables or set scaling option to false.');
      end
      
    end
    
    function parameters = getParameters(self)
      parameters = Var(self.system.parametersStruct,0);
    end
    
    function getCallback(self,var,values)
      self.ocpHandler.callbackFunction(var,values);
    end

    function [costs,constraints_Val,constraints_LB,constraints_UB,timeGrid] = getNLPFun(self,nlpVars)
      
      T = nlpVars.get('time');                 % end time
      parameters = nlpVars.get('parameters');  % parameters

      timeGrid = linspace(0,T,self.N+1);
      
      constraints = Constraint(nlpVars);
      costs = Arithmetic.Matrix(0);
      
      initialStates = nlpVars.get('states',1);
      thisStates = initialStates;
      
      for k=1:self.N
        
        thisIntegratorVars = nlpVars.get('integratorVars',k);
        thisControls = nlpVars.get('controls',k);
        
        % add integrator equation of direction collocation
        [finalStates, finalAlgVars, integrationCosts, integratorEquations] = self.integratorFun.evaluate(thisStates,thisIntegratorVars,thisControls,timeGrid(k),timeGrid(k+1),T,parameters);

        constraints.add(integratorEquations,'==',0);
        
        costs = costs + integrationCosts;
        
        % go to next time gridpoint
        thisStates = nlpVars.get('states',k+1);
        
        % path constraints
        [pathConstraint,lb,ub] = self.ocpHandler.pathConstraintsFun.evaluate(thisStates, finalAlgVars, thisControls,timeGrid(k+1),parameters);
        constraints.add(lb,pathConstraint,ub);
        
        % continuity equation
        constraints.add(thisStates - finalStates, '==',0);
        
      end
      
      % add terminal cost
      terminalCosts = self.ocpHandler.arrivalCostsFun.evaluate(thisStates,T,parameters);
      costs = costs + terminalCosts;

      % add terminal constraints
      [boundaryConditions,lb,ub] = self.ocpHandler.boundaryConditionsFun.evaluate(initialStates,thisStates,parameters);
      constraints.add(lb,boundaryConditions,ub);
      
      costs = costs + self.ocpHandler.getDiscreteCost(nlpVars);
      
      constraints_Val = constraints.values;
      constraints_LB  = constraints.lowerBounds;
      constraints_UB  = constraints.upperBounds;
      
    end
  end
  
end

