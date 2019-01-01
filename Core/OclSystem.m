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
    icFun
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
      
      fhIC = @(self,varargin)self.getInitialConditions(varargin{:});
      self.icFun = OclFunction(self, fhIC, {sx,sp},1);
    end
    
    function setupVariables(varargin)
      error('Not Implemented.');
    end
    function setupEquation(varargin)
      error('Not Implemented.');
    end
    
    function initialCondition(~,~,~)
      % initialCondition(states,parameters)
    end
    
    function simulationCallbackSetup(~)
      % simulationCallbackSetup()
    end
    
    function simulationCallback(~,~,~,~,~)
      % simulationCallback(states,algVars,controls,parameters)
    end
    
    function [ode,alg] = getEquations(self,states,algVars,controls,parameters)
      % evaluate the system equations for the assigned variables
      
      self.alg = [];
      self.ode = struct;
      
      x = Variable.create(self.statesStruct,states);
      z = Variable.create(self.algVarsStruct,algVars);
      u = Variable.create(self.controlsStruct,controls);
      p = Variable.create(self.parametersStruct,parameters);

      self.setupEquation(x,z,u,p);
     
      ode = struct2array(self.ode).';
      alg = self.alg;
    end
    
    function ic = getInitialConditions(self,states,parameters)
      self.initialConditions = [];
      x = Variable.create(self.statesStruct,states);
      p = Variable.create(self.parametersStruct,parameters);
      self.initialCondition(x,p)
      ic = self.initialConditions;
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
      self.ode.(id) = oclValue(eq(:));
    end
    
    function setAlgEquation(self,eq)
      self.alg = [self.alg;oclValue(eq)];
    end
    
    function setInitialCondition(self,eq)
      self.initialConditions = [self.initialConditions; oclValue(eq)];      
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

