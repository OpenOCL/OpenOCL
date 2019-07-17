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
    
    x_bounds

    x0_bounds
    xF_bounds
    z_bounds
    u_bounds
    p_bounds
    
    nx
    nz
    nu
    np
    
    x_struct
    z_struct
    u_struct
    p_struct
    x_order
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
      
      [x_struct, z_struct, u_struct, p_struct, ...
          x_bounds_v, z_bounds_v, u_bounds_v, p_bounds_v, ...
          x_order] = ocl.model.vars(varsfh);
      
      self.T = T;
      self.H_norm = H_norm_in;
      self.N = length(H_norm_in);
      self.d = d_in;
      
      self.daefh = daefh;
      self.pathcostsfh = pathcostsfh;
      self.gridcostsfh = gridcostsfh;
      self.gridconstraintsfh = gridconstraintsfh;
      
      self.nx = length(x_struct);
      self.nz = length(z_struct);
      self.nu = length(u_struct);
      self.np = length(p_struct);
      
      self.x_struct = x_struct;
      self.z_struct = z_struct;
      self.u_struct = u_struct;
      self.p_struct = p_struct;
      self.x_order = x_order;
      
      self.x_bounds = x_bounds_v;
      self.x0_bounds = ocl.Bounds();
      self.xF_bounds = ocl.Bounds();
      self.z_bounds = z_bounds_v;
      self.u_bounds = u_bounds_v;
      self.p_bounds = p_bounds_v;
    end
    
    function setStateBounds(self, id, varargin)
      self.x_bounds.set(id, varargin{:});
    end
    
    function setInitialStateBounds(self, id, varargin)
      self.x0_bounds.set(id, varargin{:});
    end
    
    function setEndStateBounds(self, id, varargin)
      self.xF_bounds.set(id, varargin{:});
    end
    
    function setAlgvarBounds(self, id, varargin)
      self.z_bounds.set(id, varargin{:});
    end
    
    function setControlBounds(self, id, varargin)
      self.u_bounds.set(id, varargin{:});
    end
    
    function setParameterBounds(self, id, varargin)
      self.p_bounds.set(id, varargin{:});
    end
    
  end
end
