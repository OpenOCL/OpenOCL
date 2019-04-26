classdef OclSystem < handle

  properties
    fh

    thisInitialConditions

    systemfun
    icfun
  end

  properties (Access = private)
    odeVar
    sysvars
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
    end
    
    function r = states(self)
      r = self.sysvars.states;
    end
    function r = algvars(self)
      r = self.sysvars.algvars;
    end
    function r = controls(self)
      r = self.sysvars.controls;
    end
    function r = parameters(self)
      r = self.sysvars.parameters;
    end
    function r = bounds(self)
      r = self.sysvars.bounds;
    end
    
    function r = parameterBounds(self)
      r = self.sysvars.parameterBounds;
    end
    
    function r = statesOrder(self)
      r = self.sysvars.statesOrder;
    end

    function r = nx(self)
      r = prod(self.states.size());
    end

    function r = nz(self)
      r = prod(self.algvars.size());
    end

    function r = nu(self)
      r = prod(self.controls.size());
    end

    function r = np(self)
      r = prod(self.parameters.size());
    end

    function setup(self)

      svh = OclSysvarsHandler();
      self.fh.vars(svh);
      
      self.sysvars = svh.getSysvars();

      sx = self.states().size();
      sz = self.algvars().size();
      su = self.controls().size();
      sp = self.parameters().size();

      fhEq = @(self,varargin)self.getEquations(varargin{:});
      self.systemfun = OclFunction(self, fhEq, {sx,sz,su,sp},2);

      fhIC = @(self,varargin)self.getInitialConditions(varargin{:});
      self.icfun = OclFunction(self, fhIC, {sx,sp},1);
    end

    function simulationCallbackSetup(~)
      % simulationCallbackSetup()
    end

    function simulationCallback(varargin)
      % simulationCallback(states,algVars,controls,timeBegin,timesEnd,parameters)
    end

    function [ode,alg] = getEquations(self,x,z,u,p)
      % evaluate the system equations for the assigned variables

      x = Variable.create(self.states,x);
      z = Variable.create(self.algvars,z);
      u = Variable.create(self.controls,u);
      p = Variable.create(self.parameters,p);

      daehandler = OclDaeHandler();
      self.fh.eq(daehandler,x,z,u,p);

      ode = daehandler.getOde(self.nx, self.statesOrder);
      alg = daehandler.getAlg(self.nz);
    end

    function ic = getInitialConditions(self,x,p)
      icHandler = OclConstraint(self);
      x = Variable.create(self.statesStruct,x);
      p = Variable.create(self.parametersStruct,p);
      self.fh.ic(icHandler,x,p)
      ic = icHandler.values;
      assert(all(icHandler.lowerBounds==0) && all(icHandler.upperBounds==0),...
          'In initial condition are only equality constraints allowed.');
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
