classdef Stage < handle

  properties
    T
    
    daefun
    pathcostfun
    gridcostfun
    gridconstraintfun
    
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
    
    function self = Stage(T, varargin)
      
      emptyfh = @(varargin)[];
      
      p = ocl.utils.ArgumentParser;
      
      p.addKeyword('vars', emptyfh, @oclIsFunHandle);
      p.addKeyword('dae', emptyfh, @oclIsFunHandle);
      p.addKeyword('pathcosts', emptyfh, @oclIsFunHandle);
      p.addKeyword('gridcosts', emptyfh, @oclIsFunHandle);
      
      p.addKeyword('gridconstraints', emptyfh, @oclIsFunHandle);
      
      r = p.parse(varargin{:});
      
      varsfh = r.vars;
      daefh = r.dae;
      pathcostsfh = r.pathcosts;
      gridcostsfh = r.gridcosts;  
      gridconstraintsfh = r.gridconstraints;

      oclAssert( (isscalar(T) || isempty(T)) && isreal(T), ... 
        ['Invalid value for parameter T.', oclDocMessage()] );
      self.T = T;
      
      vars = ocl.model.vars(varsfh);
      
      x_struct = vars.states;
      z_struct = vars.algvars;
      u_struct = vars.controls;
      p_struct = vars.parameters;
      x_order = vars.x_order;
      
      self.daefun = @(x,z,u,p) ocl.model.dae(daefh, x_struct, z_struct, u_struct, p_struct, x_order, x, z, u, p);
      self.pathcostfun = @(x,z,u,p) ocl.model.pathcosts(pathcostsfh, x_struct, z_struct, u_struct, p_struct, x, z, u, p);
      self.gridcostfun = @(k,K,x,p) ocl.model.gridcosts(gridcostsfh, x_struct, p_struct, k, N, x, p);
      self.gridconstraintfun = @(k,K,x,p) ocl.model.gridconstraints(gridconstraintsfh, x_struct, p_struct, k, N, x, p);
      
      self.nx = length(x_struct);
      self.nz = length(z_struct);
      self.nu = length(u_struct);
      self.np = length(p_struct);
      
      self.states = x_struct;
      self.algvars = z_struct;
      self.controls = u_struct;
      self.parameters = p_struct;
      
    end
    
  end
end
