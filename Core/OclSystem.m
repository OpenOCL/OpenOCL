classdef OclSystem < handle
  
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
    
    fh
    opts
    
    bounds
    
    thisInitialConditions
    
    systemFun
    icFun
  end
  
  properties (Access = private)
    odeVar
  end

  methods
    
    function self = OclSystem(varargin)
      % OclSystem()
      % OclSystem(fhVarSetup,fhEquationSetup)
      % OclSystem(fhVarSetup,fhEquationSetup,fhInitialCondition)
      % OclSystem(__,'independent_variable',name)
      % OclSystem(__,'dependent',isDependent)
      
      defFhVars = @(varargin)self.setupVariables(varargin{:});
      defFhEq = @(varargin)self.setupEquation(varargin{:});
      defFhIC = @(varargin)self.initialConditions(varargin{:});
      
      p = inputParser;
      p.addOptional('fhVars',defFhVars,@oclIsFunHandle);
      p.addOptional('fhEq',defFhEq,@oclIsFunHandle);
      p.addOptional('fhIC',defFhIC,@oclIsFunHandle);
      p.addParameter('independent_variable','time',@isstring);
      p.addParameter('dependent',false,@islogical);
      p.parse(varargin{:});
      
      self.fh = struct;
      self.fh.vars = p.Results.fhVars;
      self.fh.eq = p.Results.fhEq;
      self.fh.ic = p.Results.fhIC;
      
      self.opts = struct;
      self.opts.independent_variable = p.Results.independent_variable;
      self.opts.dependent = p.Results.dependent;
      
      self.statesStruct     = OclStructure();
      self.algVarsStruct    = OclStructure();
      self.controlsStruct   = OclStructure();
      self.parametersStruct = OclStructure();
      
      self.bounds = struct;
      self.ode = struct;
    end
    
    function setup(self)
      self.fh.vars(self);
      
      if self.opts.dependent
        self.addState(self.opts.independent_variable);
      end
      
      sx = self.statesStruct.size();
      sz = self.algVarsStruct.size();
      su = self.controlsStruct.size();
      sp = self.parametersStruct.size();
      
      self.nx = prod(sx);
      self.nz = prod(sz);
      self.nu = prod(su);
      self.np = prod(sp);
      
      fhEq = @(self,varargin)self.getEquations(varargin{:});
      self.systemFun = OclFunction(self, fhEq, {sx,sz,su,sp},2);
      
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
    
    function simulationCallbackSetup(~)
      % simulationCallbackSetup()
    end
    
    function simulationCallback(varargin)
      % simulationCallback(states,algVars,controls,timeBegin,timesEnd,parameters)
    end
    
    function [ode,alg] = getEquations(self,states,algVars,controls,parameters)
      % evaluate the system equations for the assigned variables
      
      % reset alg and ode
      self.alg = [];
      names = fieldnames(self.ode);
      for i=1:length(names)
        self.ode.(names{i}) = [];
      end
      
      x = Variable.create(self.statesStruct,states);
      z = Variable.create(self.algVarsStruct,algVars);
      u = Variable.create(self.controlsStruct,controls);
      p = Variable.create(self.parametersStruct,parameters);

      self.fh.eq(self,x,z,u,p);
      
      if self.opts.dependent
        self.setODE(self.opts.independent_variable,1);
      end
     
      ode = struct2cell(self.ode);
      ode = vertcat(ode{:});
      alg = self.alg;
      
      if length(alg) ~= self.nz
        oclException(['Number of algebraic equations does not match ',...
                      'number of algebraic variables.']);
      end      
      if length(ode) ~= self.nx
        oclException(['Number of ode equations does not match ',...
                      'number of state variables.']);
      end
    end
    
    function ic = getInitialConditions(self,states,parameters)
      icHandler = OclConstraint(self);
      x = Variable.create(self.statesStruct,states);
      p = Variable.create(self.parametersStruct,parameters);
      self.fh.ic(icHandler,x,p)
      ic = icHandler.values;
      assert(all(icHandler.lowerBounds==0) && all(icHandler.upperBounds==0),...
          'In initial condition are only equality constraints allowed.');
    end
    
    function addState(self,id,s,lb,ub)
      % addState(id)
      % addState(id,size)
      % addState(id,size,lb,ub)
      if nargin==2
        s = 1;
      end
      if nargin <=3
        lb = -inf;
        ub = inf;
      end
      self.ode.(id) = [];
      self.statesStruct.add(id,s);
      self.bounds.(id).lower = lb;
      self.bounds.(id).upper = ub;
    end
    function addAlgVar(self,id,s,lb,ub)
      % addAlgVar(id)
      % addAlgVar(id,size)
      % addAlgVar(id,size,lb,ub)
      if nargin==2
        s = 1;
      end
      if nargin <=3
        lb = -inf;
        ub = inf;
      end
      self.algVarsStruct.add(id,s);
      self.bounds.(id).lower = lb;
      self.bounds.(id).upper = ub;
    end
    function addControl(self,id,s,lb,ub)
      % addControl(id)
      % addControl(id,size)
      % addControl(id,size,lb,ub)
      if nargin==2
        s = 1;
      end
      if nargin <=3
        lb = -inf;
        ub = inf;
      end
      self.controlsStruct.add(id,s);
      self.bounds.(id).lower = lb;
      self.bounds.(id).upper = ub;
    end
    function addParameter(self,id,s,defaultValue)
      % addParameter(id)
      % addParameter(id,size)
      % addParameter(id,size,defaultValue)
      if nargin==2
        s = 1;
      end
      if nargin <=3
        lb = -inf;
        ub = inf;
      else
        lb = defaultValue;
        ub = defaultValue;
      end
      self.parametersStruct.add(id,s);
      self.bounds.(id).lower = lb;
      self.bounds.(id).upper = ub;
    end

    function setODE(self,id,eq)
      if ~isfield(self.ode,id)
        oclException(['State ', id, ' does not exist.']);
      end
      if ~isempty(self.ode.(id))
        oclException(['Ode for var ', id, ' already defined']);
      end
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

