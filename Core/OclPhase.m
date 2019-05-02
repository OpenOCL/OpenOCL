classdef OclPhase < handle

  properties
    T
    H_norm
    integrator

    bounds
    bounds0
    boundsF
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
    lagrangecostfh
    pathcostfh
    pathconfh
  end
  
  methods
    
    function self = OclPhase(T, H_norm, integrator, pathcostsfh, pathconfh)

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
      self.lagrangecostfh = lagrangecostsfh;
      self.pathcostfh = pathcostsfh;
      self.pathconfh = pathconfh;
    end

    function r = N(self)
      r = length(self.H_norm);
    end
    
    function setBounds(self,id,varargin)
      % setInitialBounds(id,value)
      % setInitialBounds(id,lower,upper)
      self.bounds = OclBounds(id, varargin{:});
    end
    
    function setInitialBounds(self,id,varargin)
      % setInitialBounds(id,value)
      % setInitialBounds(id,lower,upper)
      self.bounds0 = OclBounds(id, varargin{:});
    end
    
    function setEndBounds(self,id,varargin)
      % setInitialBounds(id,value)
      % setInitialBounds(id,lower,upper)
      self.boundsF = OclBounds(id, varargin{:});
    end
    
    function r = lagrangecostfun(self,x,z,u,p)
      pcHandler = OclCost();
      
      x = Variable.create(self.states,x);
      z = Variable.create(self.algvars,z);
      u = Variable.create(self.controls,u);
      p = Variable.create(self.parameters,p);
      
      self.pathcostfh(pcHandler,x,z,u,p);
      
      r = pcHandler.value;
    end
    
    function r = pathcostfun(self,k,N,x,p)
      pcHandler = OclCost();
      
      x = Variable.create(self.states,x);
      p = Variable.create(self.parameters,p);
      
      self.pathcostfh(pcHandler,k,N,x,p);
      
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
