classdef OclPhase < handle

  properties
    T
    H_norm
    integrator
    
    lagrangecostsfun
    pathcostsfh
    pathconfh
    
    integratormap

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
    
    function self = OclPhase(T, H_norm, integrator, pathcostsfh, pathconfh, ...
                             states, algvars, controls, parameters, ...
                             controlBounds, parameterBounds)

      oclAssert( (isscalar(T) || isempty(T)) && isreal(T), ... 
        ['Invalid value for parameter T.', oclDocMessage()] );
      self.T = T;
      
      oclAssert( (isscalar(H_norm) || isnumeric(H_norm)) && isreal(H_norm), ...
        ['Invalid value for parameter N.', oclDocMessage()] );
      if isscalar(H_norm)
        self.H_norm = repmat(1/H_norm, 1, H_norm);
      else
        self.H_norm = H_norm;
        if abs(sum(self.H_norm)-1) > eps 
          self.H_norm = self.H_norm/sum(self.H_norm);
          oclWarning(['Timesteps given in pararmeter N are not normalized! ', ...
                      'N either be a scalar value or a normalized vector with the length ', ...
                      'of the number of control interval. Check the documentation of N. ', ...
                      'Make sure the timesteps sum up to 1, and contain the relative ', ...
                      'length of the timesteps. OpenOCL normalizes the timesteps and proceeds.']);
        end
      end
      
      self.integrator = integrator;
      self.pathcostsfh = pathcostsfh;
      self.pathconfh = pathconfh;
      self.lagrangecostsfun = @integrator.lagrangecostsfun;
      
      self.nx = integrator.nx;
      self.nz = integrator.nz;
      self.nu = integrator.nu;
      self.np = integrator.np;
      
      self.states = states;
      self.algvars = algvars;
      self.controls = controls;
      self.parameters = parameters;
      
      self.stateBounds0 = OclBounds(-inf * ones(self.nx, 1), inf * ones(self.nx, 1));
      self.stateBoundsF = OclBounds(-inf * ones(self.nx, 1), inf * ones(self.nx, 1));
      self.controlBounds = OclBounds(-inf * ones(self.nu, 1), inf * ones(self.nu, 1));
      self.parameterBounds = OclBounds(-inf * ones(self.np, 1), inf * ones(self.np, 1));
      
      names = fieldnames(controlBounds);
      for k=1:length(names)
        id = names{k};
        self.setControlBounds(id, controlBounds.(id).lower, controlBounds.(id).upper);
      end
      
      names = fieldnames(parameterBounds);
      for k=1:length(names)
        id = names{k};
        self.setParameterBounds(id, parameterBounds.(id).lower, parameterBounds.(id).upper);
      end
      
    end

    function r = N(self)
      r = length(self.H_norm);
    end
    
    function setStateBounds(self,id,varargin)
      self.integrator.setStateBounds(id,varargin{:});
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
    
    function r = pathcostfun(self,k,N,x,p)
      pcHandler = OclCost();
      
      x = Variable.create(self.states,x);
      p = Variable.create(self.parameters,p);
      
      self.pathcostsfh(pcHandler,k,N,x,p);
      
      r = pcHandler.value;
    end
    
    function [val,lb,ub] = pathconfun(self,k,N,x,p)
      pathConstraintHandler = OclConstraint();
      x = Variable.create(self.states,x);
      p = Variable.create(self.parameters,p);
      
      self.pathconfh(pathConstraintHandler,k,N,x,p);
      
      val = pathConstraintHandler.values;
      lb = pathConstraintHandler.lowerBounds;
      ub = pathConstraintHandler.upperBounds;
    end
    
  end
  
end
