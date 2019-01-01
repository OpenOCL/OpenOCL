classdef (Abstract) OclSystem < handle
  
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
    
    function self = OclSystem()
      self.statesStruct     = OclTree();
      self.algVarsStruct    = OclTree();
      self.controlsStruct   = OclTree();
      self.parametersStruct = OclTree();
      
      self.setupVariables;
      
      sx = self.statesStruct.size();
      sz = self.algVarsStruct.size();
      su = self.controlsStruct.size();
      sp = self.parametersStruct.size();
      
      fh = @(self,varargin)self.getEquations(varargin{:});
      self.systemFun = OclFunction(self, fh, {sx,sz,su,sp},2);
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
      
      self.alg = []
      self.ode = struct;
      
      x = Variable.create(self.statesStruct,statesIn);
      z = Variable.create(self.algVarsStruct,algVarsIn);
      u = Variable.create(self.controlsStruct,controlsIn);
      p = Variable.create(self.parametersStruct,parametersIn);

      self.setupEquation(x,z,u,p);
     
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

    function setODE(self,id,eq)
      if isa(eq,'Variable')
        eq = eq.value;
      end
      self.ode.(id) = eq(:);
    end
    
    function setAlgEquation(self,eq)
      if isa(eq,'Variable')
        eq = eq.value;
      end
      self.alg = [self.alg;eq];
    end
    
    function setInitialCondition(self,value)
      if isa(value,'Variable')
        value = value.value;
      end
      self.initialConditions = [self.initialConditions; value];      
    end
    
    function  ic = getInitialCondition(self,statesIn,parametersIn)
      self.initialConditions = [];
      self.initialCondition(statesIn,parametersIn)
      ic = Variable.createLike(statesIn,self.initialConditions);
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

