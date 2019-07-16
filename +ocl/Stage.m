classdef Stage < handle

  properties
    T
    
    N
    d
    
    H_norm
    
    daefh
    pathcostsfh
    gridcostsfh
    gridconstraintsfh
    
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
    statesOrder
  end
  
  properties (Access = private)

  end
  
  methods
    
    function self = Stage(T, varargin)
      
      emptyfh = @(varargin)[];
      
      p = ocl.utils.ArgumentParser;
      
      p.addKeyword('vars', emptyfh, @oclIsFunHandle);
      p.addKeyword('dae', emptyfh, @oclIsFunHandle);
      p.addKeyword('pathcosts', emptyfh, @oclIsFunHandle);
      p.addKeyword('gridcosts', emptyfh, @oclIsFunHandle);
      p.addKeyword('gridconstraints', emptyfh, @oclIsFunHandle);
      
      p.addParameter('N', 20, @isnumeric);
      p.addParameter('d', 3, @isnumeric);
      
      r = p.parse(varargin{:});
      
      varsfh = r.vars;
      daefh = r.dae;
      pathcostsfh = r.pathcosts;
      gridcostsfh = r.gridcosts;  
      gridconstraintsfh = r.gridconstraints;
      H_norm_in = r.N;
      d_in = r.d;

      % arguments consistency checks
      oclAssert( (isscalar(T) || isempty(T)) && isreal(T), ... 
        ['Invalid value for parameter T.', oclDocMessage()] );
      
      oclAssert( (isscalar(H_norm_in) || isnumeric(H_norm_in)) && isreal(H_norm_in), ...
        ['Invalid value for parameter N.', oclDocMessage()] );
      
      if isscalar(H_norm_in)
        H_norm_in = repmat(1/H_norm_in, 1, H_norm_in);
      elseif abs(sum(H_norm_in)-1) > 1e-6 
        H_norm_in = H_norm_in/sum(H_norm_in);
        oclWarning(['Timesteps given in pararmeter N are not normalized! ', ...
                    'N either be a scalar value or a normalized vector with the length ', ...
                    'of the number of control grid. Check the documentation of N. ', ...
                    'Make sure the timesteps sum up to 1, and contain the relative ', ...
                    'length of the timesteps. OpenOCL normalizes the timesteps and proceeds.']);
      end
      
      self.T = T;
      self.H_norm = H_norm_in;
      self.N = length(H_norm_in);
      self.d = d_in;
      
      [x_struct, z_struct, u_struct, p_struct, ...
          x_bounds, z_bounds, u_bounds, p_bounds, ...
          x_order] = ocl.model.vars(varsfh);
      
      self.daefh = daefh;
      self.pathcostsfh = pathcostsfh;
      self.gridcostsfh = gridcostsfh;
      self.gridconstraintsfh = gridconstraintsfh;
      
      self.nx = length(x_struct);
      self.nz = length(z_struct);
      self.nu = length(u_struct);
      self.np = length(p_struct);
      
      self.states = x_struct;
      self.algvars = z_struct;
      self.controls = u_struct;
      self.parameters = p_struct;
      self.statesOrder = x_order;
      
      self.stateBounds = ocl.Bounds();
      self.stateBounds0 = ocl.Bounds();
      self.controlBounds = ocl.Bounds();
      self.parameterBounds = ocl.Bounds();
    end
    
    function setStateBounds(self, id, varargin)
      self.stateBounds.set(id, varargin{:});
    end
    
    function setInitialStateBounds(self, id, varargin)
      self.stateBounds0.set(id, varargin{:});
    end
    
    function setControlBounds(self, id, varargin)
      self.controlBounds.set(id, varargin{:});
    end
    
    function setParameterBounds(self, id, varargin)
      self.parameterBounds.set(id, varargin{:});
    end
    
  end
end
