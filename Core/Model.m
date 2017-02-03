classdef (Abstract) Model < handle
  
  properties(Constant)
    DOT_PREFIX = 'D';
  end  
  
  properties
    state
    algState
    controls
    parameters
    ode
    alg
    
    initialConditions
    
    algEqIndex    = 1;
    modelFun
  end
  
  methods (Abstract)
   setupVariables(self)
   setupEquation(self)
  end
  
  methods
    
    function self = Model(parameters)
      self.state       = Var('state');
      self.algState    = Var('algState');
      self.controls    = Var('controls');
      
      if nargin == 0
        self.parameters = Var('parameters');
      else
        self.parameters  = parameters;
      end
      
      self.initialConditions = [];
      

      self.ode         = Var('ode');
      self.alg         = Var('alg');
      
      self.setupVariables;
      
      self.state.compile;
      self.algState.compile;
      self.controls.compile;
      self.parameters.compile;
      self.ode.compile;
      self.alg.compile;
      
      self.modelFun = UserFunction(@self.evaluate,{self.state,self.algState,self.controls,self.parameters},2);
      
    end
    
    function [ode,alg] = evaluate(self,state,algState,controls,parameters)
      % evaluate the model equations for the assigned 
      
      self.alg = Var('alg');

      self.setupEquation(state,algState,controls,parameters);
      
      ode = self.ode;
      alg = self.alg;
    end
    
    function addState(self,id,size)
      self.state.add(id,size);
      self.ode.add([Model.DOT_PREFIX id],size)
    end
    function addAlgState(self,id,size)
      self.algState.add(id,size);
    end
    function addControl(self,id,size)
      self.controls.add(id,size);
    end
    function addParameter(self,id,size)
      self.parameters.add(id,size);
    end
    
    
    function state = getState(self,id)
      state = self.state.get(id).value;
    end
    function algState = getAlgState(self,id)
      algState = self.algState.get(id).value;
    end
    function control = getControl(self,id)
      control = self.controls.get(id).value;
    end
    function param = getParameter(self,id)
      param = self.parameters.get(id).value;
    end

    function setODE(self,id,equation)
      %
      self.ode.get([Model.DOT_PREFIX id]).set(equation);
    end
    
    function setAlgEquation(self,equation)
      self.alg.add(Var(equation,'algEq'));
    end
    
    
    function setInitialCondition(self,value)
      self.initialConditions = [self.initialConditions; value];      
    end
    
    function  ic = getInitialCondition(self,state,parameters)
      self.initialConditions = [];
      self.initialCondition(state,parameters)
      ic = self.initialConditions;
    end
    
    function controls = callIterationCallback(self,state,algVars,parameters)
      controls = self.controls;
      controls.set(0);
      self.simulationCallback(state,algVars,controls,parameters);
    end
    
    function solutionCallback(self,solution)
      
      N = solution.get('state').getNumberOfVars;
      parameters = solution.get('parameters');
      
      for k=1:N-1
        state = solution.get('state',k+1);
        algVars = solution.get('integratorVars',k).get('algState',3);
        self.callIterationCallback(state,algVars,parameters);
      end
      
    end
    
  end
  
end

