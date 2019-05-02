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
      self.pathcostfh = pathcostsfh;
      self.pathconfh = pathconfh;
      
      self.nx = integrator.nx;
      self.nz = integrator.nz;
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
    
  end
  
end
