% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
classdef OclSystem < handle

  properties
    varsfh
    daefh
    icfh
    callbackfh
    callbacksetupfh
    
    thisInitialConditions
    
    states
    algvars
    controls
    parameters
    stateBounds
    algvarBounds
    controlBounds
    parameterBounds
    
    statesOrder
  end

  methods

    function self = OclSystem(varargin)
      % OclSystem()
      % OclSystem(fhVarSetup,fhEquationSetup)
      % OclSystem(fhVarSetup,fhEquationSetup,fhInitialCondition)

      emptyfh = @(varargin)[];

      p = ocl.ArgumentParser;

      p.addKeyword('vars', emptyfh, @oclIsFunHandle);
      p.addKeyword('dae', emptyfh, @oclIsFunHandle);
      p.addKeyword('ic', emptyfh, @oclIsFunHandle);
      p.addKeyword('callbacksetup', emptyfh, @oclIsFunHandle);
      p.addKeyword('callback', emptyfh, @oclIsFunHandle);
      
      r = p.parse(varargin{:});

      varsfun = r.vars;
      daefun = r.dae;
      icfun = r.ic;
      callbacksetupfh = r.callbacksetup;
      callbackfh = r.callback;

      self.varsfh = varsfun;
      self.daefh = daefun;
      self.icfh = icfun;

      self.callbacksetupfh = callbacksetupfh;
      self.callbackfh = callbackfh;
      
      svh = OclSysvarsHandler;
      self.varsfh(svh);
      
      self.states = svh.states;
      self.algvars = svh.algvars;
      self.controls = svh.controls;
      self.parameters = svh.parameters;
      self.stateBounds = svh.stateBounds;
      self.algvarBounds = svh.algvarBounds;
      self.controlBounds = svh.controlBounds;
      self.parameterBounds = svh.parameterBounds;
      
      self.statesOrder = svh.statesOrder;

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
      icHandler = OclConstraint();
      x = Variable.create(self.states,x);
      p = Variable.create(self.parameters,p);
      self.icfh(icHandler,x,p)
      ic = icHandler.values;
      assert(all(icHandler.lowerBounds==0) && all(icHandler.upperBounds==0),...
          'In initial condition are only equality constraints allowed.');
    end

    function cbsetupfun(self)
      self.callbacksetupfh();
    end

    function u = cbfun(self,states,algVars,controls,timesBegin,timesEnd,parameters)
      x = Variable.create(self.states,states);
      z = Variable.create(self.algvars,algVars);
      u = Variable.create(self.controls,controls);
      p = Variable.create(self.parameters,parameters);

      t0 = Variable.Matrix(timesBegin);
      t1 = Variable.Matrix(timesEnd);

      self.callbackfh(x,z,u,t0,t1,p);
      u = Variable.getValueAsColumn(u);
    end

  end
end
