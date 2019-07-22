classdef Solver < handle
  
  properties
    acados_ocp
    
    state_bounds
    
    x_struct
    z_struct
    u_struct
    p_struct
    
    x0_bounds
  end
  
  methods
    function self = Solver(varargin)
      
      ocl.utils.checkStartup()
      
      zerofh = @(varargin) 0;
      emptyfh = @(varargin) [];
      
      p = ocl.utils.ArgumentParser;
      
      p.addRequired('T', @(el) isnumeric(el) || isempty(el) );
      p.addKeyword('vars', emptyfh, @oclIsFunHandle);
      p.addKeyword('dae', emptyfh, @oclIsFunHandle);
      p.addKeyword('pathcosts', zerofh, @oclIsFunHandle);
      p.addKeyword('gridcosts', zerofh, @oclIsFunHandle);
      p.addKeyword('gridconstraints', emptyfh, @oclIsFunHandle);
      
      p.addParameter('N', 20, @isnumeric);
      p.addParameter('d', 3, @isnumeric);
      
      r = p.parse(varargin{:});
      
      T = r.T;
      N = r.N;
      varsfh = r.vars;
      daefh = r.dae;
      pathcostsfh = r.pathcosts;
      gridcostsfh = r.gridcosts;
      gridconstraintsfh = r.gridconstraints;
      
      [x_struct, z_struct, u_struct, p_struct, ...
        x_bounds, ~, u_bounds, ~, ...
        x_order] = ocl.model.vars(varsfh);
      
      nx = length(x_struct);
      nz = length(z_struct);
      nu = length(u_struct);
      np = length(p_struct);
      
      oclAssert(nz==0, 'No algebraic variable are currently support in the acados interface.');
      oclAssert(np==0, 'No parameters are currently support in the acados interface.');
      
      daefun = @(x,z,u,p) ocl.model.dae( ...
        daefh, ...
        x_struct, ...
        z_struct, ...
        u_struct, ...
        p_struct, ...
        x_order, ...
        x, z, u, p);
      
      gridcostfun = @(k,K,x,p) ocl.model.gridcosts( ...
        gridcostsfh, ...
        x_struct, ...
        p_struct, ...
        k, K, x, p);
      
      pathcostfun = @(x,z,u,p) ocl.model.pathcosts( ...
        pathcostsfh, ...
        x_struct, ...
        z_struct, ...
        u_struct, ...
        p_struct, ...
        x, z, u, p);
      
      gridconstraintfun = @(k,K,x,p) ocl.model.gridconstraints( ...
        gridconstraintsfh, ...
        x_struct, ...
        p_struct, ...
        k, K, x, p);
    
      [x_lb, x_ub] = ocl.model.bounds(x_struct, x_bounds);
      [lbx, ubx, Jbx] = ocl.acados.bounds(x_lb, x_ub);
      
      [u_lb, u_ub] = ocl.model.bounds(u_struct, u_bounds);
      [lbu, ubu, Jbu] = ocl.acados.bounds(u_lb, u_ub);
      
      ocp = ocl.acados.initialize( ...
        nx, nu, ...
        T, N, ...
        daefun, gridcostfun, pathcostfun, gridconstraintfun, ...
        lbx, ubx, Jbx, lbu, ubu, Jbu);
      
      self.acados_ocp = ocp;
      self.x_struct = x_struct;
      self.z_struct = z_struct;
      self.u_struct = u_struct;
      self.p_struct = p_struct;
      
      self.x0_bounds = ocl.types.Bounds();
    end
    
    function solve(self)
      ocp = self.acados_ocp;
      ocl.acados.solve(ocp);
    end
    
    function setInitialStateBounds(self, id, varargin)
      % bounds
      self.x0_bounds.set(id, varargin{:});
      
      [x0_lb, x0_ub] = ocl.model.bounds(self.x_struct, self.x0_bounds);
      
      oclAssert(all(x0_lb == x0_ub), 'Initial state must be a fixed value (not a box constraint) in the acados interface.');
      
      self.acados_ocp.set('constr_x0', x0_lb);
    end
    
    function setInitialState(self, id, value)
      self.setInitialStateBounds(id, value);
    end
    
  end
end
