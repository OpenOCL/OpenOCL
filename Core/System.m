classdef (Abstract) System < handle
  
  properties
    statesStruct
    algVarsStruct
    controlsStruct
    parametersStruct
    
    ode
    alg
    
    initialConditions
    systemFun
  end
  
  properties (Access = private)
    odeVar
  end

  methods
    
    function self = System()
      self.statesStruct     = TreeNode('states');
      self.algVarsStruct    = TreeNode('algVars');
      self.controlsStruct   = TreeNode('controls');
      self.parametersStruct = TreeNode('parameters');
      
      self.initialConditions = Variable.Matrix([]);
      
      self.setupVariables;
      
      self.systemFun = Function(self,@(self,varargin)self.getEquations(varargin{:}), ...
        {self.statesStruct,self.algVarsStruct,self.controlsStruct,self.parametersStruct},2);
      
    end
    
    function setupVariables(varargin)
      error('Not Implemented.');
    end
    function setupEquation(varargin)
      error('Not Implemented.');
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
      % evaluate the system equations for the assigned variables
      
      self.alg = Variable.createLike(statesIn,MatrixStructure([0,1]));
      self.ode = statesIn.varStructure.childPointers;

      self.setupEquation(statesIn,algVarsIn,controlsIn,parametersIn);
      
      ode = struct2cell(self.ode);
      ode = vertcat(ode{:});
      ode = CasadiVariable.createLike(statesIn,MatrixStructure(size(ode)),ode);
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
      if isa(equation,'Variable')
        eq = equation.value;
        self.ode.(id) = eq(:);
      else
        self.ode.(id) = equation(:);
      end
    end
    
    function setAlgEquation(self,equation)
      self.alg = [self.alg;equation];
    end
    
    function setInitialCondition(self,value)
      self.initialConditions = [self.initialConditions; value];      
    end
    
    function  ic = getInitialCondition(self,statesIn,parametersIn)
      self.initialConditions = Variable.createLike(statesIn,MatrixStructure([0,1]));
      self.initialCondition(statesIn,parametersIn)
      ic = self.initialConditions;
    end
    
    function solutionCallback(self,solution)
      sN = solution.get('states').size;
      N = sN(2);
      parameters = solution.get('parameters');
      
      for k=1:N-1
        states = solution.get('states',k+1);
        algVars = solution.get('integratorVars',k).get('algVars');
        controls =  solution.get('controls',k);
        self.simulationCallback(states,algVars,controls,parameters);
      end
    end
  end
end

