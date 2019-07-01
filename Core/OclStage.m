classdef OclStage < handle

  properties
    T
    H_norm
    integrator
    
    pathcostfun
    gridcostsfh
    pointcostsarray
    
    gridconstraintsfh
    
    callbacksetupfh
    callbackfh
    
    integratormap
    
    
    stateBounds

    stateBounds0
    stateBoundsF
    controlBounds
    parameterBounds
    
    nx
    nz
    nu
    np
    
    states
    algvars
    controls
    parameters
  end
  
  properties (Access = private)

  end
  
  methods
    
    function self = OclStage(T, varargin)
      
      emptyfh = @(varargin)[];
      
      p = ocl.utils.ArgumentParser;
      
      p.addKeyword('vars', emptyfh, @oclIsFunHandle);
      p.addKeyword('dae', emptyfh, @oclIsFunHandle);
      p.addKeyword('pathcosts', emptyfh, @oclIsFunHandle);
      p.addKeyword('gridcosts', emptyfh, @oclIsFunHandle);
      
      p.addKeyword('gridconstraints', emptyfh, @oclIsFunHandle);
      
      p.addKeyword('callbacksetup', emptyfh, @oclIsFunHandle);
      p.addKeyword('callback', emptyfh, @oclIsFunHandle);
      
      p.addKeyword('pointcosts', {}, @(el) iscell(el) && (isempty(el) || isa(el{1}, 'ocl.Pointcost')));

      p.addParameter('N', 20, @isnumeric);
      p.addParameter('d', 3, @isnumeric);
      
      r = p.parse(varargin{:});
      
      varsfhInput = r.vars;
      daefhInput = r.dae;
      
      pathcostsfhInput = r.pathcosts;
      gridcostsfhInput = r.gridcosts;  
      pointcostsarrayInput = r.pointcosts;  
      
      gridconstraintsfhInput = r.gridconstraints;
      
      callbacksetupfh = r.callbacksetup;
      callbackfh = r.callback;
      
      H_normInput = r.N;
      dInput = r.d;

      oclAssert( (isscalar(T) || isempty(T)) && isreal(T), ... 
        ['Invalid value for parameter T.', oclDocMessage()] );
      self.T = T;
      
      oclAssert( (isscalar(H_normInput) || isnumeric(H_normInput)) && isreal(H_normInput), ...
        ['Invalid value for parameter N.', oclDocMessage()] );
      if isscalar(H_normInput)
        H_normInput = repmat(1/H_normInput, 1, H_normInput);
      elseif abs(sum(H_normInput)-1) > 1e-6 
        H_normInput = H_normInput/sum(H_normInput);
        oclWarning(['Timesteps given in pararmeter N are not normalized! ', ...
                    'N either be a scalar value or a normalized vector with the length ', ...
                    'of the number of control grid. Check the documentation of N. ', ...
                    'Make sure the timesteps sum up to 1, and contain the relative ', ...
                    'length of the timesteps. OpenOCL normalizes the timesteps and proceeds.']);
      end
      
      system = OclSystem(varsfhInput, daefhInput);
      daefun = @(x,z,u,p) ocl.model.daefun(system.states, system.algvars, system.controls, ...
                                           system.parameters, system.statesOrder, ...
                                           x, z, u, p);
                                         
      colocation = OclCollocation(system.states, system.algvars, system.controls, ...
                                  system.parameters, daefun, pathcostsfhInput, dInput, ...
                                  system.stateBounds, system.algvarBounds);
      
      self.H_norm = H_normInput;
      self.integrator = colocation;
      
      self.pathcostfun = @colocation.pathcostfun;
      self.gridcostsfh = gridcostsfhInput;
      self.pointcostsarray = pointcostsarrayInput;
      
      self.gridconstraintsfh = gridconstraintsfhInput;
      
      self.callbacksetupfh = callbacksetupfh;
      self.callbackfh = callbackfh;
      
      self.nx = colocation.num_x;
      self.nz = colocation.num_z;
      self.nu = colocation.num_u;
      self.np = colocation.num_p;
      
      self.states = system.states;
      self.algvars = system.algvars;
      self.controls = system.controls;
      self.parameters = system.parameters;
      
      self.stateBounds = OclBounds(-inf * ones(self.nx, 1), inf * ones(self.nx, 1));
      self.stateBounds0 = OclBounds(-inf * ones(self.nx, 1), inf * ones(self.nx, 1));
      self.stateBoundsF = OclBounds(-inf * ones(self.nx, 1), inf * ones(self.nx, 1));
      self.controlBounds = OclBounds(-inf * ones(self.nu, 1), inf * ones(self.nu, 1));
      self.parameterBounds = OclBounds(-inf * ones(self.np, 1), inf * ones(self.np, 1));
      
      names = fieldnames(system.stateBounds);
      for k=1:length(names)
        id = names{k};
        self.setStateBounds(id, system.stateBounds.(id).lower, system.stateBounds.(id).upper);
      end
      
      names = fieldnames(system.controlBounds);
      for k=1:length(names)
        id = names{k};
        self.setControlBounds(id, system.controlBounds.(id).lower, system.controlBounds.(id).upper);
      end
      
      names = fieldnames(system.parameterBounds);
      for k=1:length(names)
        id = names{k};
        self.setParameterBounds(id, system.parameterBounds.(id).lower, system.parameterBounds.(id).upper);
      end
      
    end

    function r = N(self)
      r = length(self.H_norm);
    end
    
    function setStateBounds(self,id,varargin)
      
      self.integrator.setStateBounds(id,varargin{:});
      
      x_lb = Variable.create(self.states, self.stateBounds.lower);
      x_ub = Variable.create(self.states, self.stateBounds.upper);
      
      bounds = OclBounds(varargin{:});
      
      x_lb.get(id).set(bounds.lower);
      x_ub.get(id).set(bounds.upper);
      
      self.stateBounds.lower = x_lb.value;
      self.stateBounds.upper = x_ub.value;
    end
    
    function setInitialStateBounds(self,id,varargin)
      x0_lb = Variable.create(self.states, self.stateBounds0.lower);
      x0_ub = Variable.create(self.states, self.stateBounds0.upper);
      
      bounds = OclBounds(varargin{:});
      
      x0_lb.get(id).set(bounds.lower);
      x0_ub.get(id).set(bounds.upper);
      
      self.stateBounds0.lower = x0_lb.value;
      self.stateBounds0.upper = x0_ub.value;
    end
    
    function setEndStateBounds(self,id,varargin)
      xF_lb = Variable.create(self.states, self.stateBoundsF.lower);
      xF_ub = Variable.create(self.states, self.stateBoundsF.upper);
      
      bounds = OclBounds(varargin{:});
      
      xF_lb.get(id).set(bounds.lower);
      xF_ub.get(id).set(bounds.upper);
      
      self.stateBoundsF.lower = xF_lb.value;
      self.stateBoundsF.upper = xF_ub.value;
    end
    
    function setAlgvarBounds(self,id,varargin)
      self.integrator.setAlgvarBounds(id,varargin{:});
    end
    
    function setControlBounds(self,id,varargin)
      u_lb = Variable.create(self.controls, self.controlBounds.lower);
      u_ub = Variable.create(self.controls, self.controlBounds.upper);
      
      bounds = OclBounds(varargin{:});
      
      u_lb.get(id).set(bounds.lower);
      u_ub.get(id).set(bounds.upper);
      
      self.controlBounds.lower = u_lb.value;
      self.controlBounds.upper = u_ub.value;
    end
    
    function setParameterBounds(self,id,varargin)
      p_lb = Variable.create(self.parameters, self.parameterBounds.lower);
      p_ub = Variable.create(self.parameters, self.parameterBounds.upper);
      
      bounds = OclBounds(varargin{:});
      
      p_lb.get(id).set(bounds.lower);
      p_ub.get(id).set(bounds.upper);
      
      self.parameterBounds.lower = p_lb.value;
      self.parameterBounds.upper = p_ub.value;
    end
    
    function r = gridcostfun(self,k,N,x,p)
      gridCostHandler = OclCost();
      
      x = Variable.create(self.states,x);
      p = Variable.create(self.parameters,p);
      
      self.gridcostsfh(gridCostHandler,k,N,x,p);
      
      r = gridCostHandler.value;
    end
    
    function r = pointcostfun(self, k, x, p)
      ch = OclCost();
      
      x = Variable.create(self.states,x);
      p = Variable.create(self.parameters,p);
      
      fh = self.pointcostsarray{k};
      fh(ch, x, p);
      
      r = ch.value;
    end
    
    function [val,lb,ub] = gridconstraintfun(self,k,N,x,p)
      gridConHandler = OclConstraint();
      x = Variable.create(self.states,x);
      p = Variable.create(self.parameters,p);
      
      self.gridconstraintsfh(gridConHandler,k,N,x,p);
      
      val = gridConHandler.values;
      lb = gridConHandler.lowerBounds;
      ub = gridConHandler.upperBounds;
    end
    
    function callbacksetupfun(self)
      self.callbacksetupfh();
    end
    
    function u = callbackfun(self,x,z,u,t0,t1,p)
      
      x = Variable.create(self.states,x);
      z = Variable.create(self.algvars,z);
      u = Variable.create(self.states,u);
      p = Variable.create(self.parameters,p);
      
      t0 = Variable.Matrix(t0);
      t1 = Variable.Matrix(t1);
      
      u = self.callbackfh(x,z,u,t0,t1,p);
    end
    
  end
  
end
