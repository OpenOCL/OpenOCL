classdef OclSystem < handle

  properties
    varsfh
    daefh
    icfh
    cbfh
    cbsetupfh
    
    thisInitialConditions
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

      daefun = p.Results.eqfunOpt;
      if isempty(daefun)
        daefun = p.Results.eqfun;
      end

      icfun = p.Results.icfunOpt;
      if isempty(icfun)
        icfun = p.Results.icfun;
      end

      self.varsfh = varsfun;
      self.daefh = daefun;
      self.icfh = icfun;

      self.cbfh = p.Results.cbfun;
      self.cbsetupfh = p.Results.cbsetupfun;
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
    
    function simulationCallbackSetup(~)
      % simulationCallbackSetup()
    end

    function simulationCallback(varargin)
      % simulationCallback(states,algVars,controls,timeBegin,timesEnd,parameters)
    end
    
    function sysvars = varsfun(self)
      
      OclSysvarsHandler svh;
      self.varsfh(svh);
      sysvars = svh.getSysvars();
    end

    function [ode,alg] = daefun(self,x,z,u,p)
      % evaluate the system equations for the assigned variables

      x = Variable.create(self.states,x);
      z = Variable.create(self.algvars,z);
      u = Variable.create(self.controls,u);
      p = Variable.create(self.parameters,p);

      daehandler = OclDaeHandler();
      self.daefh(daehandler,x,z,u,p);

      ode = daehandler.getOde(self.nx, self.statesOrder);
      alg = daehandler.getAlg(self.nz);
    end

    function ic = icfun(self,x,p)
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
      self.cbsetupfh();
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
