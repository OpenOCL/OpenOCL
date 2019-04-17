classdef OclSystem < handle

  properties
    statesStruct
    algVarsStruct
    controlsStruct
    parametersStruct

    ode
    alg

    fh

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

      defFhVars = @(varargin)[];
      defFhEq = @(varargin)[];
      defFhIC = @(varargin)[];
      defFhCB = @(varargin)[];
      defFhCBS = @(varargin)[];

      p = inputParser;
      p.addOptional('varsfunOpt', [], @oclIsFunHandleOrEmpty);
      p.addOptional('eqfunOpt', [], @oclIsFunHandleOrEmpty);
      p.addOptional('icfunOpt', [], @oclIsFunHandleOrEmpty);

      p.addParameter('varsfun', defFhVars, @oclIsFunHandle);
      p.addParameter('eqfun', defFhEq, @oclIsFunHandle);
      p.addParameter('icfun', defFhIC, @oclIsFunHandle);
      p.addParameter('cbfun', defFhCB, @oclIsFunHandle);
      p.addParameter('cbsetupfun', defFhCBS, @oclIsFunHandle);
      p.parse(varargin{:});

      varsfun = p.Results.varsfunOpt;
      if isempty(varsfun)
        varsfun = p.Results.varsfun;
      end

      eqfun = p.Results.eqfunOpt;
      if isempty(eqfun)
        eqfun = p.Results.eqfun;
      end

      icfun = p.Results.icfunOpt;
      if isempty(icfun)
        icfun = p.Results.icfun;
      end

      self.fh = struct;
      self.fh.vars = varsfun;
      self.fh.eq = eqfun;
      self.fh.ic = icfun;

      self.fh.cb = p.Results.cbfun;
      self.fh.cbsetup = p.Results.cbsetupfun;

      self.statesStruct     = OclStructure();
      self.algVarsStruct    = OclStructure();
      self.controlsStruct   = OclStructure();
      self.parametersStruct = OclStructure();

      self.bounds = struct;
      self.ode = struct;
    end

    function r = nx(self)
      r = prod(self.statesStruct.size());
    end

    function r = nz(self)
      r = prod(self.algVarsStruct.size());
    end

    function r = nu(self)
      r = prod(self.controlsStruct.size());
    end

    function r = np(self)
      r = prod(self.parametersStruct.size());
    end

    function setup(self)

      self.fh.vars(self);

      sx = self.statesStruct.size();
      sz = self.algVarsStruct.size();
      su = self.controlsStruct.size();
      sp = self.parametersStruct.size();

      fhEq = @(self,varargin)self.getEquations(varargin{:});
      self.systemFun = OclFunction(self, fhEq, {sx,sz,su,sp},2);

      fhIC = @(self,varargin)self.getInitialConditions(varargin{:});
      self.icFun = OclFunction(self, fhIC, {sx,sp},1);
    end

    function setupVariables(varargin)
      error('Not Implemented.');
    end
    function setupEquations(varargin)
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

    function addState(self,id,varargin)
      % addState(id)
      % addState(id,s)
      % addState(id,s,lb=lb,lb=ub)

      p = inputParser;
      p.addRequired('id', @ischar);
      p.addOptional('s', 1, @isnumeric);
      p.addParameter('lb', -inf, @isnumeric);
      p.addParameter('ub', inf, @isnumeric);
      p.parse(id,varargin{:});

      id = p.Results.id;

      self.ode.(id) = [];
      self.statesStruct.add(id, p.Results.s);
      self.bounds.(id).lower = p.Results.lb;
      self.bounds.(id).upper = p.Results.ub;
    end
    function addAlgVar(self,id,varargin)
      % addAlgVar(id)
      % addAlgVar(id,s)
      % addAlgVar(id,s,lb=lb,ub=ub)
      p = inputParser;
      p.addRequired('id', @ischar);
      p.addOptional('s', 1, @isnumeric);
      p.addParameter('lb', -inf, @isnumeric);
      p.addParameter('ub', inf, @isnumeric);
      p.parse(id,varargin{:});

      id = p.Results.id;

      self.algVarsStruct.add(id, p.Results.s);
      self.bounds.(id).lower = p.Results.lb;
      self.bounds.(id).upper = p.Results.ub;
    end
    function addControl(self,id,varargin)
      % addControl(id)
      % addControl(id,s)
      % addControl(id,s,lb=lb,ub=ub)
      p = inputParser;
      p.addRequired('id', @ischar);
      p.addOptional('s', 1, @isnumeric);
      p.addParameter('lb', -inf, @isnumeric);
      p.addParameter('ub', inf, @isnumeric);
      p.parse(id,varargin{:});

      id = p.Results.id;

      self.controlsStruct.add(id,p.Results.s);
      self.bounds.(id).lower = p.Results.lb;
      self.bounds.(id).upper = p.Results.ub;
    end
    function addParameter(self,id,varargin)
      % addParameter(id)
      % addParameter(id,s)
      % addParameter(id,s,defaultValue)
      p = inputParser;
      p.addRequired('id', @ischar);
      p.addOptional('s', 1, @isnumeric);
      p.addParameter('default', 0, @isnumeric);
      p.parse(id,varargin{:});

      id = p.Results.id;

      self.parametersStruct.add(id,p.Results.s);
      self.bounds.(id).lower = p.Results.default;
      self.bounds.(id).upper = p.Results.default;
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
      
      t = times.states;

      for k=1:N-1
        states = solution.states(:,:,k+1);
        algVars = solution.integrator(:,:,k).algVars;
        controls =  solution.controls(:,:,k);
        parameters = solution.parameters(:,:,k);
        self.fh.cb(states,algVars,controls,t(:,:,k),t(:,:,k+1),parameters);
      end
    end

    function callSimulationCallbackSetup(self)
      self.fh.cbsetup();
    end

    function u = callSimulationCallback(self,states,algVars,controls,timesBegin,timesEnd,parameters)
      x = Variable.create(self.statesStruct,states);
      z = Variable.create(self.algVarsStruct,algVars);
      u = Variable.create(self.controlsStruct,controls);
      p = Variable.create(self.parametersStruct,parameters);

      t0 = Variable.Matrix(timesBegin);
      t1 = Variable.Matrix(timesEnd);

      self.fh.cb(x,z,u,t0,t1,p);
      u = Variable.getValueAsColumn(u);
    end

  end
end
