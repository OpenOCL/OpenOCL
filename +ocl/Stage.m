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
    terminalcostfh
    
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
    
    x_guess
    z_guess
    u_guess
    p_guess
    
    userdata
    
  end
  
  methods
    
    function self = Stage(T, varargin)
      
      ocl.utils.checkStartup()
      
      p = ocl.utils.ArgumentParser;
      
      p.addKeyword('vars', ocl.utils.emptyfh, @ocl.utils.isFunHandle);
      p.addKeyword('dae', ocl.utils.emptyfh, @ocl.utils.isFunHandle);
      p.addKeyword('pathcosts', ocl.utils.emptyfh, @ocl.utils.isFunHandle);
      p.addKeyword('gridcosts', ocl.utils.emptyfh, @ocl.utils.isFunHandle);
      p.addKeyword('gridconstraints', ocl.utils.emptyfh, @ocl.utils.isFunHandle);
      p.addKeyword('terminalcost', ocl.utils.emptyfh, @ocl.utils.isFunHandle);
      
      p.addParameter('N', 20, @isnumeric);
      p.addParameter('d', 3, @isnumeric);
      
      p.addParameter('userdata', [], @(in)true);
      
      r = p.parse(varargin{:});
      
      varsfh = r.vars;
      daefh = r.dae;
      pathcostsfh = r.pathcosts;
      gridcostsfh = r.gridcosts;  
      gridconstraintsfh = r.gridconstraints;
      terminalcostfh = r.terminalcost;
      H_norm_in = r.N;
      d_in = r.d;
      userdata = r.userdata;

      % arguments consistency checks
      ocl.utils.assert( (isscalar(T) || isempty(T)) && isreal(T), ... 
        ['Invalid value for parameter T.', ocl.utils.docMessage()] );
      
      ocl.utils.assert( (isscalar(H_norm_in) || isnumeric(H_norm_in)) && isreal(H_norm_in), ...
        ['Invalid value for parameter N.', ocl.utils.docMessage()] );
      
      if isscalar(H_norm_in)
        H_norm_in = repmat(1/H_norm_in, 1, H_norm_in);
      elseif abs(sum(H_norm_in)-1) > 1e-6 
        H_norm_in = H_norm_in/sum(H_norm_in);
        ocl.utils.warning(['Timesteps given in pararmeter N are not normalized! ', ...
                    'N either be a scalar value or a normalized vector with the length ', ...
                    'of the number of control grid. Check the documentation of N. ', ...
                    'Make sure the timesteps sum up to 1, and contain the relative ', ...
                    'length of the timesteps. OpenOCL normalizes the timesteps and proceeds.']);
      end
      
      [x_struct, z_struct, u_struct, p_struct, ...
          x_bounds_v, z_bounds_v, u_bounds_v, p_bounds_v, ...
          x_order] = ocl.model.vars(varsfh, userdata);
      
      self.T = T;
      self.H_norm = H_norm_in;
      self.N = length(H_norm_in);
      self.d = d_in;
      
      self.daefh = daefh;
      self.pathcostsfh = pathcostsfh;
      self.gridcostsfh = gridcostsfh;
      self.gridconstraintsfh = gridconstraintsfh;
      self.terminalcostfh = terminalcostfh;
      
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
      self.x0_bounds = ocl.types.Bounds();
      self.xF_bounds = ocl.types.Bounds();
      self.z_bounds = z_bounds_v;
      self.u_bounds = u_bounds_v;
      self.p_bounds = p_bounds_v;
      
      self.x_guess = ocl.types.InitialGuess(x_struct);
      self.z_guess = ocl.types.InitialGuess(z_struct);
      self.u_guess = ocl.types.InitialGuess(u_struct);
      self.p_guess = ocl.types.InitialGuess(p_struct);
      
      self.userdata = userdata;
    end
    
    %%% Initial guess
    function initialize(self, id, points, values, T)
      % setGuess(id, points, values)
      
      points = ocl.Variable.getValue(points);
      values = ocl.Variable.getValue(values);
      
      if nargin==5
        points = points / T;
      end

      % check if id is a state, control, algvar or parameter
      if ocl.utils.fieldnamesContain(self.x_struct.getNames(), id)
        self.setStateGuess(id, points, values);
      elseif ocl.utils.fieldnamesContain(self.z_struct.getNames(), id)
        self.setAlgvarGuess(id, points, values);
      elseif ocl.utils.fieldnamesContain(self.u_struct.getNames(), id)
        self.setControlGuess(id, points, values);
      elseif ocl.utils.fieldnamesContain(self.p_struct.getNames(), id)
        self.setParameterGuess(id, points, values);
      else
        ocl.utils.warning(['You specified a guess for a variable that does not exist: ', id]);
      end
      
    end
    
    function setStateGuess(self, id, points, values)
      self.x_guess.set(id, points, values);
    end
    
    function setAlgvarGuess(self, id, points, values)
      self.z_guess.set(id, points, values);
    end
    
    function setControlGuess(self, id, points, values)
      self.u_guess.set(id, points, values);
    end
    
    function setParameterGuess(self, id, points, values)
      self.p_guess.set(id, points, values);
    end
    
    %%% Bounds
    function setBounds(self, id, varargin)
      if ocl.utils.fieldnamesContain(self.x_struct.getNames(), id)
        self.setStateBounds(id, varargin{:});
      elseif ocl.utils.fieldnamesContain(self.z_struct.getNames(), id)
        self.setAlgvarBounds(id, varargin{:});
      elseif ocl.utils.fieldnamesContain(self.u_struct.getNames(), id)
        self.setControlBounds(id, varargin{:});
      elseif ocl.utils.fieldnamesContain(self.p_struct.getNames(), id)
        self.setParameterBounds(id, varargin{:});
      else
        ocl.utils.warning(['You specified a guess for a variable that does not exist: ', id]);
      end
    end
    
    function setInitialBounds(self, id, varargin)
      self.setInitialStateBounds(id, varargin{:});
    end
    
    function setEndBounds(self, id, varargin)
      self.setEndStateBounds(id, varargin{:});
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
