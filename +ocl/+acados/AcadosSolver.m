classdef AcadosSolver < handle
  
  properties
    acados_ocp_p
    
    x_struct_p
    z_struct_p
    u_struct_p
    p_struct_p
    
    x0_bounds_p
    
    N_p
    T_p
  end
  
  methods
    function self = AcadosSolver(varargin)
      
      ocl.acados.setup();
      ocl.utils.checkStartup();
      
      wsp = ocl.utils.workspacePath();
      acados_build_dir = fullfile(wsp, 'export');
      
      zerofh = @(varargin) 0;
      emptyfh = @(varargin) [];
      
      p = ocl.utils.ArgumentParser;
      
      p.addRequired('T', @(el) isnumeric(el) );
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
        pathcostsfh, ...0
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
        lbx, ubx, Jbx, lbu, ubu, Jbu, ...
        acados_build_dir);
      
      self.acados_ocp_p = ocp;
      self.x_struct_p = x_struct;
      self.z_struct_p = z_struct;
      self.u_struct_p = u_struct;
      self.p_struct_p = p_struct;
      
      self.x0_bounds_p = ocl.types.Bounds();
      self.N_p = N;
      self.T_p = T;
    end
    
    function [sol_out,times_out] = solve(self)
      
      ocp = self.acados_ocp_p;
      x_struct = self.x_struct_p;
      u_struct = self.u_struct_p;
      N = self.N_p;
      T = self.T_p;
      
      ocl.acados.solve(ocp);
      x_traj = ocp.get('x');
      u_traj = ocp.get('u');
      
      sol_struct = OclStructure();
      times_struct = OclStructure();

      sol_struct.add('states', x_struct);
      times_struct.add('states', [1,1]);
      
      for j=1:N
        sol_struct.add('states', x_struct);
        times_struct.add('states', [1,1]);
      end

      for j=1:N
        sol_struct.add('controls', u_struct);
        times_struct.add('controls', [1,1]);
      end

      sol_out = Variable.create(sol_struct, 0);
      sol_out.states.set(x_traj);
      sol_out.controls.set(u_traj);
      
      x_times = linspace(0,T,N+1);
      u_times = x_times(1:end-1);

      times_out = Variable.create(times_struct, 0);        
      times_out.states.set(x_times);
      times_out.controls.set(u_times);
      
    end
    
    function setInitialStateBounds(self, id, varargin)

      x0_bounds = self.x0_bounds_p;
      x_struct = self.x_struct_p;
      ocp = self.acados_ocp_p;

      x0_bounds.set(id, varargin{:});
      
      [x0_lb, x0_ub] = ocl.model.bounds(x_struct, x0_bounds);
      
      oclAssert(all(x0_lb == x0_ub), 'Initial state must be a fixed value (not a box constraint) in the acados interface.');
      
      ocp.set('constr_x0', x0_lb);
    end
    
    function setInitialState(self, id, value)
      self.setInitialStateBounds(id, value);
    end
    
  end
end
