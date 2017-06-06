classdef (Abstract) System < handle
  
  properties(Constant)
    DOT_PREFIX = 'D';
  end  
  
  properties
    statesStruct
    algVarsStruct
    controlsStruct
    parametersStruct
    
    ode
    alg
    
    initialConditions
    
    algEqIndex    = 1;
    systemFun
  end
  
  properties (Access = private)
    odeVar
  end
  
  methods (Abstract)
   setupVariables(self)
   setupEquation(self)
  end
  
  methods
    
    function self = System(parametersStruct)
      self.statesStruct     = TreeNode('states');
      self.algVarsStruct    = TreeNode('algVars');
      self.controlsStruct   = TreeNode('controls');
      
      if nargin == 0
        self.parametersStruct = Parameters;
      else
        self.parametersStruct  = parametersStruct;
      end
      
      self.initialConditions = Arithmetic.Matrix([]);
      

      self.ode         = TreeNode('ode');
      self.alg         = Arithmetic.Matrix([]);
      
      self.setupVariables;
      
      self.statesStruct.compile;
      self.algVarsStruct.compile;
      self.controlsStruct.compile;
      
      self.systemFun = Function(@self.getEquations, ...
        {self.statesStruct,self.algVarsStruct,self.controlsStruct,self.parametersStruct},2);
      
    end
    
    function initialCondition(~,~,~)
    end
    
    function simulationCallbackSetup(self)
    end
    
    function simulationCallback(self,states,algVars,controls,parameters)
    end
    
    function [ode,alg] = evaluate(self,states,algVars,controls,parameters)
      [ode,alg] = self.systemFun.evaluate(states,algVars,controls,parameters);
    end
    
    function [ode,alg] = getEquations(self,statesIn,algVarsIn,controlsIn,parametersIn)
      % evaluate the system equations for the assigned 
      
      self.alg = Arithmetic.create(statesIn,MatrixStructure([0,1]));
      self.ode = Arithmetic.create(statesIn,statesIn.varStructure);

      self.setupEquation(statesIn,algVarsIn,controlsIn,parametersIn);
      
      ode = self.ode;
      alg = self.alg;
    end
    
    function addState(self,id,size)
      self.statesStruct.add(id,size);
    end
    function addAlgVar(self,id,size)
      self.algVarsStruct.add(id,size);
    end
    function addControl(self,id,size)
      self.controlsStruct.add(id,size);
    end
    function addParameter(self,id,size)
      self.parametersStruct.add(id,size);
    end

    function setODE(self,id,equation)
      self.ode.get(id).set(equation);
    end
    
    function setAlgEquation(self,equation)
      self.alg = [self.alg;equation];
    end
    
    function setInitialCondition(self,value)
      self.initialConditions = [self.initialConditions; value];      
    end
    
    function  ic = getInitialCondition(self,statesIn,parametersIn)
      self.initialConditions = Arithmetic.create(statesIn,MatrixStructure([0,1]));
      self.initialCondition(statesIn,parametersIn)
      ic = self.initialConditions;
    end
    
    function controls = callIterationCallback(self,states,algVars,parameters)
      controls =  Arithmetic(self.controlsStruct,0);
      self.simulationCallback(states,algVars,controls,parameters);
    end
    
    function solutionCallback(self,solution)
      sN = solution.get('states').size;
      N = sN(2);
      parameters = solution.get('parameters');
      
      for k=1:N-1
        states = solution.get('states',k+1);
        algVars = solution.get('integratorVars',k).get('algVars');
        self.callIterationCallback(states,algVars(end),parameters);
      end
      
    end
    
  end
  
end

