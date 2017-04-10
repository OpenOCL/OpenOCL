classdef (Abstract) System < handle
  
  properties(Constant)
    DOT_PREFIX = 'D';
  end  
  
  properties
    states
    algVars
    controls
    parameters
    ode
    alg
    
    initialConditions
    
    algEqIndex    = 1;
    systemFun
  end
  
  methods (Abstract)
   setupVariables(self)
   setupEquation(self)
  end
  
  methods
    
    function self = System(parameters)
      self.states     = Var('states');
      self.algVars    = Var('algVars');
      self.controls   = Var('controls');
      
      if nargin == 0
        self.parameters = Parameters;
      else
        self.parameters  = parameters.copy;
      end
      
      self.initialConditions = [];
      

      self.ode         = Var('ode');
      self.alg         = Var('alg');
      
      self.setupVariables;
      
      self.states.compile;
      self.algVars.compile;
      self.controls.compile;
%       self.parameters.compile;
      self.ode.compile;
      self.alg.compile;
      
      self.systemFun = UserFunction(@self.evaluate,{self.states,self.algVars,self.controls,self.parameters},2);
      
    end
    
    function initialCondition(~,~,~)
    end
    
    function simulationCallbackSetup(self)
    end
    
    function simulationCallback(self,states,algVars,controls,parameters)
    end
    
    function [ode,alg] = evaluate(self,states,algVars,controls,parameters)
      % evaluate the system equations for the assigned 
      
      self.alg = Var('alg');

      self.setupEquation(states,algVars,controls,parameters);
      
      ode = self.ode;
      alg = self.alg;
    end
    
    function addState(self,id,size)
      self.states.add(id,size);
      self.ode.add([System.DOT_PREFIX id],size)
    end
    function addAlgVar(self,id,size)
      self.algVars.add(id,size);
    end
    function addControl(self,id,size)
      self.controls.add(id,size);
    end
    function addParameter(self,id,size)
      self.parameters.add(id,size);
    end
    
    
    function state = getState(self,id)
      state = self.states.get(id).value;
    end
    function algVar= getAlgVar(self,id)
      algVar = self.algVars.get(id).value;
    end
    function control = getControl(self,id)
      control = self.controls.get(id).value;
    end
    function param = getParameter(self,id)
      param = self.parameters.get(id).value;
    end

    function setODE(self,id,equation)
      %
      self.ode.get([System.DOT_PREFIX id]).set(equation);
    end
    
    function setAlgEquation(self,equation)
      self.alg.add(Var(equation,'algEq'));
    end
    
    
    function setInitialCondition(self,value)
      self.initialConditions = [self.initialConditions; value];      
    end
    
    function  ic = getInitialCondition(self,states,parameters)
      self.initialConditions = [];
      self.initialCondition(states,parameters)
      ic = self.initialConditions;
    end
    
    function controls = callIterationCallback(self,states,algVars,parameters)
      controls = self.controls;
      controls.set(0);
      self.simulationCallback(states,algVars,controls,parameters);
    end
    
    function solutionCallback(self,solution)
      
      N = solution.get('states').getNumberOfVars;
      parameters = solution.get('parameters');
      
      for k=1:N-1
        states = solution.get('states',k+1);
        algVars = solution.get('integratorVars',k).get('algVars',3);
        self.callIterationCallback(states,algVars,parameters);
      end
      
    end
    
  end
  
end

