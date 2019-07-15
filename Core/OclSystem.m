% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
classdef OclSystem < handle

  properties
    daefun
    
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

      p = ocl.utils.ArgumentParser;

      p.addKeyword('vars', emptyfh, @oclIsFunHandle);
      p.addKeyword('dae', emptyfh, @oclIsFunHandle);
      p.addKeyword('ic', emptyfh, @oclIsFunHandle);
      p.addKeyword('callbacksetup', emptyfh, @oclIsFunHandle);
      p.addKeyword('callback', emptyfh, @oclIsFunHandle);
      
      r = p.parse(varargin{:});

      varsfh = r.vars;
      daefh = r.dae;
      icfh = r.ic;
      callbacksetupfh = r.callbacksetup;
      callbackfh = r.callback;

      self.icfh = icfh;

      self.callbacksetupfh = callbacksetupfh;
      self.callbackfh = callbackfh;
      
      svh = OclSysvarsHandler;
      varsfh(svh);
     
      self.daefun = @(x,z,u,p) ocl.model.dae(daefh, svh.states, svh.algvars, ...
                                             svh.controls, svh.parameters, ...
                                             svh.statesOrder, x, z, u, p);
      
      self.states = svh.states;
      self.algvars = svh.algvars;
      self.controls = svh.controls;
      self.parameters = svh.parameters;
      
      self.statesOrder = svh.statesOrder;
      
      self.stateBounds = svh.stateBounds;
      self.algvarBounds = svh.algvarBounds;
      self.controlBounds = svh.controlBounds;
      self.parameterBounds = svh.parameterBounds;
    end

    function r = nx(self)
      r = length(self.states);
    end

    function r = nz(self)
      r = length(self.algvars);
    end

    function r = nu(self)
      r = length(self.controls);
    end

    function r = np(self)
      r = length(self.parameters);
    end
    
    function simulationCallbackSetup(~)
      % simulationCallbackSetup()
    end

    function simulationCallback(varargin)
      % simulationCallback(states,algVars,controls,timeBegin,timesEnd,parameters)
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

    function callbacksetupfun(self)
      self.callbacksetupfh();
    end

    function u = callbackfun(self,x,z,u,t0,t1,p)
      x = Variable.create(self.states,x);
      z = Variable.create(self.algvars,z);
      u = Variable.create(self.controls,u);
      p = Variable.create(self.parameters,p);

      t0 = Variable.Matrix(t0);
      t1 = Variable.Matrix(t1);

      self.callbackfh(x,z,u,t0,t1,p);
      u = Variable.getValueAsColumn(u);
    end

  end
end
