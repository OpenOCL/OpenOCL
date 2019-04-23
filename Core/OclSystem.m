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
    parameterBounds

    thisInitialConditions

    systemfun
    icfun
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
      self.parameterBounds = struct;
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

      svh = OclSysvarsHandler();
      self.fh.vars(svh);
      
      self.statesOrder = svh.statesOrder;

      sx = svh.statesStruct.size();
      sz = svh.algVarsStruct.size();
      su = svh.controlsStruct.size();
      sp = svh.parametersStruct.size();

      fhEq = @(self,varargin)self.getEquations(varargin{:});
      self.systemfun = OclFunction(self, fhEq, {sx,sz,su,sp},2);

      fhIC = @(self,varargin)self.getInitialConditions(varargin{:});
      self.icfun = OclFunction(self, fhIC, {sx,sp},1);
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

      daehandler = OclDaeHandler();
      self.fh.eq(daehandler,x,z,u,p);

      ode = daehandler.getOde(self.nx);
      alg = daehandler.getAlg(self.nz);
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
