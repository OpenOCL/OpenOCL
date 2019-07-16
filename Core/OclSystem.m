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
    
    x_struct
    z_struct
    u_struct
    p_struct
    x_bounds
    z_bounds
    u_bounds
    p_bounds
    
    x_order
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
      
      svh = ocl.VarHandler;
      varsfh(svh);
     
      self.daefun = @(x,z,u,p) ocl.model.dae(daefh, svh.x_struct, svh.z_struct, ...
                                             svh.u_struct, svh.p_struct, ...
                                             svh.x_order, x, z, u, p);
      
      self.x_struct = svh.x_struct;
      self.z_struct = svh.z_struct;
      self.u_struct = svh.u_struct;
      self.p_struct = svh.p_struct;
      
      self.x_order = svh.x_order;
      
      self.x_bounds = svh.x_bounds;
      self.z_bounds = svh.z_bounds;
      self.u_bounds = svh.u_bounds;
      self.p_bounds = svh.p_bounds;
    end

    function r = nx(self)
      r = length(self.x_struct);
    end

    function r = nz(self)
      r = length(self.z_struct);
    end

    function r = nu(self)
      r = length(self.u_struct);
    end

    function r = np(self)
      r = length(self.p_struct);
    end
    
    function simulationCallbackSetup(~)
      % simulationCallbackSetup()
    end

    function simulationCallback(varargin)
      % simulationCallback(states,algVars,controls,timeBegin,timesEnd,parameters)
    end

    function ic = icfun(self,x,p)
      icHandler = OclConstraint();
      x = Variable.create(self.x_struct,x);
      p = Variable.create(self.p_struct,p);
      self.icfh(icHandler,x,p)
      ic = icHandler.values;
      assert(all(icHandler.lowerBounds==0) && all(icHandler.upperBounds==0),...
          'In initial condition are only equality constraints allowed.');
    end

    function callbacksetupfun(self)
      self.callbacksetupfh();
    end

    function u = callbackfun(self,x,z,u,t0,t1,p)
      x = Variable.create(self.x_struct,x);
      z = Variable.create(self.z_struct,z);
      u = Variable.create(self.u_struct,u);
      p = Variable.create(self.p_struct,p);

      t0 = Variable.Matrix(t0);
      t1 = Variable.Matrix(t1);

      self.callbackfh(x,z,u,t0,t1,p);
      u = Variable.getValueAsColumn(u);
    end

  end
end
