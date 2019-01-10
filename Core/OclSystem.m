classdef (Abstract) OclSystem < handle
  
  properties
    statesStruct
    algVarsStruct
    controlsStruct
    parametersStruct
    
    nx
    nz
    nu
    np
    
    ode
    alg
    
    thisInitialConditions
    systemFun
    icFun
  end
  
  properties (Access = private)
    odeVar
  end

  methods
    
    function self = OclSystem()
      self.statesStruct     = OclStructure();
      self.algVarsStruct    = OclStructure();
      self.controlsStruct   = OclStructure();
      self.parametersStruct = OclStructure();
      
      self.ode = struct;
      self.setupVariables;
      
      sx = self.statesStruct.size();
      sz = self.algVarsStruct.size();
      su = self.controlsStruct.size();
      sp = self.parametersStruct.size();
      
      self.nx = prod(sx);
      self.nz = prod(sz);
      self.nu = prod(su);
      self.np = prod(sp);
      
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
    
    function initialConditions(~,~,~)
      % initialConditions(states,parameters)
    end
    
    function initialCondition(~,~,~)
      % initialCondition(states,parameters)
      % This methods is deprecated in favor of initialConditions
      % It will be removed in future versions.
    end
    
    function simulationCallbackSetup(~)
      % simulationCallbackSetup()
    end
    
    function simulationCallback(varargin)
      % simulationCallback(states,algVars,controls,timeBegin,timesEnd,parameters)
    end
    
    function [ode,alg] = getEquations(self,states,algVars,controls,parameters)
      % evaluate the system equations for the assigned variables
      
      self.alg = [];
      
      x = Variable.create(self.statesStruct,states);
      z = Variable.create(self.algVarsStruct,algVars);
      u = Variable.create(self.controlsStruct,controls);
      p = Variable.create(self.parametersStruct,parameters);

      self.setupEquation(x,z,u,p);
     
      ode = struct2cell(self.ode);
      ode = vertcat(ode{:});
      alg = self.alg;
    end
    
    function ic = getInitialConditions(self,states,parameters)
      self.thisInitialConditions = [];
      x = Variable.create(self.statesStruct,states);
      p = Variable.create(self.parametersStruct,parameters);
      self.initialCondition(x,p)
      self.initialConditions(x,p)
      ic = self.thisInitialConditions;
    end
    
    function addState(self,id,varargin)
      self.ode.(id) = [];
      self.statesStruct.add(id,varargin{:});
    end
    function addAlgVar(self,id,varargin)
      self.algVarsStruct.add(id,varargin{:});
    end
    function addControl(self,id,varargin)
      self.controlsStruct.add(id,varargin{:});
    end
    function addParameter(self,id,varargin)
      self.parametersStruct.add(id,varargin{:});
    end

    function setODE(self,id,eq)
      self.ode.(id) = Variable.getValueAsColumn(eq);
    end
    
    function setAlgEquation(self,eq)
      self.alg = [self.alg;Variable.getValueAsColumn(eq)];
    end
    
    function setInitialCondition(self,eq)
      self.thisInitialConditions = [self.thisInitialConditions; Variable.getValueAsColumn(eq)];      
    end
    
    function solutionCallback(self,times,solution)
      sN = size(solution.states);
      N = sN(3);
      parameters = solution.parameters;
      t = times.states;
      
      for k=1:N-1
        states = solution.states(:,:,k+1);
        algVars = solution.integrator(:,:,k).algVars;
        controls =  solution.controls(:,:,k);
        self.simulationCallback(states,algVars,controls,t(:,:,k),t(:,:,k+1),parameters);
      end
    end
    
    function callSimulationCallback(self,states,algVars,controls,timesBegin,timesEnd,parameters)
      x = Variable.create(self.statesStruct,states);
      z = Variable.create(self.algVarsStruct,algVars);
      u = Variable.create(self.controlsStruct,controls);
      p = Variable.create(self.parametersStruct,parameters);
      
      t0 = Variable.Matrix(timesBegin);
      t1 = Variable.Matrix(timesEnd);
      
      self.simulationCallback(x,z,u,t0,t1,p);
      
    end
    
  end
end

