classdef OclPhase < handle

  properties
    T
    H_norm
    integrator
    
    lagrangecostsfun
    pathcostsfh
    pathconfh

    stateBounds
    stateBounds0
    stateBoundsF
    
    algvarBounds
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
    
    function self = OclPhase(T, H_norm, integrator, pathcostsfh, pathconfh, states, algvars, controls, parameters)

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
    end

    function r = N(self)
      r = length(self.H_norm);
    end
    
    function setStateBounds(self,id,varargin)
      self.stateBounds = OclBounds(id, varargin{:});
    end
    
    function setInitialStateBounds(self,id,varargin)
      self.stateBounds0 = OclBounds(id, varargin{:});
    end
    
    function setEndStateBounds(self,id,varargin)
      self.stateBoundsF = OclBounds(id, varargin{:});
    end
    
    function setAlgvarBounds(self,id,varargin)
      self.algvarBounds = OclBounds(id, varargin{:});
    end
    
    function setParameterBounds(self,id,varargin)
      self.parameterBounds = OclBounds(id, varargin{:});
    end
    
    function setControlBounds(self,id,varargin)
      self.controlBounds = OclBounds(id, varargin{:});
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
