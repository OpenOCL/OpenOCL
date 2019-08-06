classdef Solver < handle
  
  properties
    acados_ocp_p
    
    x_struct_p
    z_struct_p
    u_struct_p
    p_struct_p
    
    x0_bounds_p
    
    N_p
    T_p
    
    x_guess_p
    u_guess_p
  end
  
  methods
    function self = Solver(varargin)
      
      ocl.acados.setup();
      
      wsp = ocl.utils.workspacePath();
      acados_build_dir = fullfile(wsp, 'export');
      
      p = ocl.utils.ArgumentParser;
      
      p.addRequired('T', @(el) isnumeric(el) );
      p.addKeyword('vars', ocl.utils.emptyfh, @ocl.utils.isFunHandle);
      p.addKeyword('dae', ocl.utils.emptyfh, @ocl.utils.isFunHandle);
      p.addKeyword('pathcosts', ocl.utils.zerofh, @ocl.utils.isFunHandle);
      p.addKeyword('gridcosts', ocl.utils.zerofh, @ocl.utils.isFunHandle);
      p.addKeyword('gridconstraints', ocl.utils.emptyfh, @ocl.utils.isFunHandle);
      p.addKeyword('terminalcost', ocl.utils.emptyfh, @ocl.utils.isFunHandle);
      
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
      terminalcostfh = r.terminalcost;
      
      [x_struct, z_struct, u_struct, p_struct, ...
        x_bounds, ~, u_bounds, ~, ...
        x_order] = ocl.model.vars(varsfh);
      
      nx = length(x_struct);
      nz = length(z_struct);
      nu = length(u_struct);
      np = length(p_struct);
      
      ocl.utils.assert(nz==0, 'Algebraic variable are currently not support in the acados interface.');
      ocl.utils.assert(np==0, 'Parameters are currently not support in the acados interface.');
      
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
      
      terminalcostfun = @(x,p) ocl.model.terminalcost( ...
        terminalcostfh, ...
        x_struct, ...
        p_struct, ...
        x, p);
    
      [x_lb, x_ub] = ocl.model.bounds(x_struct, x_bounds);
      [lbx, ubx, Jbx] = ocl.acados.bounds(x_lb, x_ub);
      
      [u_lb, u_ub] = ocl.model.bounds(u_struct, u_bounds);
      [lbu, ubu, Jbu] = ocl.acados.bounds(u_lb, u_ub);
      
      ocp = ocl.acados.construct( ...
        nx, nu, ...
        T, N, ...
        daefun, gridcostfun, pathcostfun, gridconstraintfun, ...
        terminalcostfun, ...
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
      
      self.x_guess_p = ocl.types.InitialGuess(x_struct);
      self.u_guess_p = ocl.types.InitialGuess(u_struct);
    end
    
    function initialize(self, id, points, values, T)
      
      points = ocl.Variable.getValue(points);
      values = ocl.Variable.getValue(values);
      
      if nargin==5
        points = points / T;
      end
      
      x_ids = self.x_struct_p.getNames();
      u_ids = self.u_struct_p.getNames();
      
      if ocl.utils.fieldnamesContain(x_ids, id)
        self.x_guess_p.set(id, points, values);
      elseif ocl.utils.fieldnamesContain(u_ids, id)
        self.u_guess_p.set(id, points, values);
      else
        ocl.utils.error(['Unknown id: ' , id, ' (not a state and not a control)']);
      end
    end
    
    function [sol_out,times_out] = solve(self)
      
      ocp = self.acados_ocp_p;
      x_struct = self.x_struct_p;
      u_struct = self.u_struct_p;
      N = self.N_p;
      T = self.T_p;
      x0_bounds = self.x0_bounds_p;
      x_guess = self.x_guess_p.data;
      u_guess = self.u_guess_p.data;
      
      % x0
      [x0_lb, x0_ub] = ocl.model.bounds(x_struct, x0_bounds);
      ocl.utils.assert(all(x0_lb == x0_ub), 'Initial state must be a fixed value (not a box constraint) in the acados interface.');
      ocp.set('constr_x0', x0_lb);
      
      % init x
      x_traj_structure = ocl.types.Structure();
      for k=1:N+1
        x_traj_structure.add('x', x_struct);
      end
      x_traj = ocl.Variable.create(x_traj_structure, 0);
      x_traj = x_traj.x;
      x_traj.set(ocp.get('x'));
      
      times_target = linspace(0,1,N+1);
      names = fieldnames(x_guess);
      for k=1:length(names)
        id = names{k};
        xdata = x_guess.(id).x;
        ydata = x_guess.(id).y;
        
        ytarget = interp1(xdata, ydata, times_target,'linear','extrap');
        
        x_traj.get(id).set(ytarget);
      end
      ocp.set('init_x', x_traj.value);
      
      % init u
      u_traj_structure = ocl.types.Structure();
      for k=1:N
        u_traj_structure.add('u', u_struct);
      end
      u_traj = ocl.Variable.create(u_traj_structure, 0);
      u_traj = u_traj.u;
      u_traj.set(ocp.get('u'));
      
      times_target = linspace(0,1,N+1);
      times_target = times_target(1:end-1);
      names = fieldnames(u_guess);
      for k=1:length(names)
        id = names{k};
        xdata = u_guess.(id).x;
        ydata = u_guess.(id).y;
        
        ytarget = interp1(xdata, ydata, times_target,'linear','extrap');
        
        u_traj.get(id).set(ytarget);
      end
      ocp.set('init_u', u_traj.value);
      
      % solve
      ocl.acados.solve(ocp);
      x_traj = ocp.get('x');
      u_traj = ocp.get('u');
      
      sol_struct = ocl.types.Structure();
      times_struct = ocl.types.Structure();

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

      sol_out = ocl.Variable.create(sol_struct, 0);
      sol_out.states.set(x_traj);
      sol_out.controls.set(u_traj);
      
      x_times = linspace(0,T,N+1);
      u_times = x_times(1:end-1);

      times_out = ocl.Variable.create(times_struct, 0);        
      times_out.states.set(x_times);
      times_out.controls.set(u_times);
      
      % clear initial guess
      self.x_guess_p = ocl.types.InitialGuess(x_struct);
      self.u_guess_p = ocl.types.InitialGuess(u_struct);
      
    end
    
    function setInitialStateBounds(self, id, varargin)

      x0_bounds = self.x0_bounds_p;
      x0_bounds.set(id, varargin{:});
    end
    
    function setInitialState(self, id, value)
      self.setInitialStateBounds(id, value);
    end
    
  end
end
