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
    
    x_traj_p
    u_traj_p
    
    sol_out_p
    times_out_p
    
    verbose_p
    print_level_p
  end
  
  methods
    function self = Solver(varargin)
      
      ocl.acados.setup();
      
      wsp = ocl.utils.workspacePath();
      acados_build_dir = fullfile(wsp, 'export');
      
      p = ocl.utils.ArgumentParser;
      
      p.addRequired('T', @(el) isnumeric(el) );
      p.addKeyword('vars', @ocl.utils.emptyfun, @ocl.utils.isFunHandle);
      p.addKeyword('dae', @ocl.utils.emptyfun, @ocl.utils.isFunHandle);
      p.addKeyword('pathcosts', @ocl.utils.zerofun, @ocl.utils.isFunHandle);
      p.addKeyword('gridcosts', @ocl.utils.zerofun, @ocl.utils.isFunHandle);
      p.addKeyword('gridconstraints', @ocl.utils.emptyfun, @ocl.utils.isFunHandle);
      p.addKeyword('terminalcost', @ocl.utils.emptyfun, @ocl.utils.isFunHandle);
      
      p.addParameter('N', 20, @isnumeric);
      p.addParameter('d', 3, @isnumeric);
      
      p.addParameter('verbose', true, @islogical);
      p.addParameter('print_level', 3, @isnumeric);
      
      p.addParameter('userdata', [], @(in)true);
      
      r = p.parse(varargin{:});
      
      T = r.T;
      N = r.N;
      varsfh = r.vars;
      daefh = r.dae;
      pathcostsfh = r.pathcosts;
      gridcostsfh = r.gridcosts;
      gridconstraintsfh = r.gridconstraints;
      terminalcostfh = r.terminalcost;
      verbose = r.verbose;
      print_level = r.print_level;
      userdata = r.userdata;
      
      model_changed = ocl.acados.hasModelChanged({varsfh, daefh, pathcostsfh, ...
        gridcostsfh, gridconstraintsfh, terminalcostfh}, N);
      
      [x_struct, z_struct, u_struct, p_struct, ...
        x_bounds, ~, u_bounds, ~, ...
        x_order] = ocl.model.vars(varsfh, userdata);
      
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
        x, z, u, p, userdata);
      
      gridcostfun = @(k,K,x,p) ocl.model.gridcosts( ...
        gridcostsfh, ...
        x_struct, ...
        p_struct, ...
        k, K, x, p, userdata);
      
      pathcostfun = @(x,z,u,p) ocl.model.pathcosts( ...
        pathcostsfh, ...
        x_struct, ...
        z_struct, ...
        u_struct, ...
        p_struct, ...
        x, z, u, p, userdata);
      
      gridconstraintfun = @(k,K,x,p) ocl.model.gridconstraints( ...
        gridconstraintsfh, ...
        x_struct, ...
        p_struct, ...
        k, K, x, p, userdata);
      
      terminalcostfun = @(x,p) ocl.model.terminalcost( ...
        terminalcostfh, ...
        x_struct, ...
        p_struct, ...
        x, p, userdata);
    
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
        acados_build_dir, ...
        model_changed, ...
        print_level);
      
      % ig variables
      x_traj_structure = ocl.types.Structure();
      for k=1:N+1
        x_traj_structure.add('x', x_struct);
      end
      x_traj = ocl.Variable.create(x_traj_structure, 0);
      x_traj = x_traj.x;
      
      u_traj_structure = ocl.types.Structure();
      for k=1:N
        u_traj_structure.add('u', u_struct);
      end
      u_traj = ocl.Variable.create(u_traj_structure, 0);
      u_traj = u_traj.u;
      
      % solution variables
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
      times_out = ocl.Variable.create(times_struct, 0);
      
      self.x_traj_p = x_traj;
      self.u_traj_p = u_traj;
      
      self.sol_out_p = sol_out;
      self.times_out_p = times_out;
      
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
      
      self.verbose_p = verbose;
      self.print_level_p = print_level;
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
    
    function [sol_out,times_out,solver_info] = solve(self)
      
      ocp = self.acados_ocp_p;
      x_struct = self.x_struct_p;
      u_struct = self.u_struct_p;
      N = self.N_p;
      T = self.T_p;
      x0_bounds = self.x0_bounds_p;
      x_guess = self.x_guess_p.data;
      u_guess = self.u_guess_p.data;
      verbose = self.verbose_p;
      x_traj = self.x_traj_p;
      u_traj = self.u_traj_p;
      sol_out = self.sol_out_p;
      times_out = self.times_out_p;
      print_level = self.print_level_p;
      
      % x0
      [x0_lb, x0_ub] = ocl.model.bounds(x_struct, x0_bounds);
      ocl.utils.assert(all(x0_lb == x0_ub), 'Initial state must be a fixed value (not a box constraint) in the acados interface.');
      ocp.set('constr_x0', x0_lb);
      
      % init x
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
      init_x = x_traj.value;
      ocp.set('init_x', init_x);
      
      % init u
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
      init_u = u_traj.value;
      ocp.set('init_u', init_u);
      
      if print_level >= 5
        ocl.utils.debug('Acados debug constr_x0: ');
        ocl.utils.debug(x0_lb);
        
        ocl.utils.debug('Acados debug init_x: ');
        ocl.utils.debug(init_x);
        
        ocl.utils.debug('Acados debug init_u: ');
        ocl.utils.debug(init_u);
      end
      
      % solve
      ocl.acados.solve(ocp);
      
      x_traj = ocp.get('x');
      u_traj = ocp.get('u');
      
      sol_out.states.set(x_traj);
      sol_out.controls.set(u_traj);
      
      x_times = linspace(0,T,N+1);
      u_times = x_times(1:end-1);
   
      times_out.states.set(x_times);
      times_out.controls.set(u_times);
      
      % clear initial guess
      self.x_guess_p = ocl.types.InitialGuess(x_struct);
      self.u_guess_p = ocl.types.InitialGuess(u_struct);
      
      if verbose
        disp(self.stats())
      end
      
      if nargout >= 3
        solver_info = self.info();
      end

    end
    
    function setMaxIterations(self, N)
      self.acados_ocp_p.opts_struct.nlp_solver_max_iter = N;
    end

    function r = info(self)
      
      acados_ocp = self.acados_ocp_p;
      
      r = struct;
      r.stats = self.stats();
      r.success = ~acados_ocp.get('status');
    end
    
    function r = stats(self)
      
      r = '';
      
      acados_ocp = self.acados_ocp_p;
      
      status = acados_ocp.get('status');
      sqp_iter = acados_ocp.get('sqp_iter');
      time_tot = acados_ocp.get('time_tot');
      time_lin = acados_ocp.get('time_lin');
      time_reg = acados_ocp.get('time_reg');
      time_qp_sol = acados_ocp.get('time_qp_sol');
      
      r = [r, sprintf('\nstatus = %d, sqp_iter = %d, time_int = %f [ms] (time_lin = %f [ms], time_qp_sol = %f [ms], time_reg = %f [ms])\n', status, sqp_iter, time_tot*1e3, time_lin*1e3, time_qp_sol*1e3, time_reg*1e3)];

      stat = acados_ocp.get('stat');
      r = [r, sprintf('\niter\tres_g\t\tres_b\t\tres_d\t\tres_m\t\tqp_stat\tqp_iter')];
      if size(stat,2)>7
        r = [r, sprintf('\tqp_res_g\tqp_res_b\tqp_res_d\tqp_res_m')];
      end
      r = [r, newline];
      for ii=1:size(stat,1)
        r = [r, sprintf('%d\t%e\t%e\t%e\t%e\t%d\t%d', stat(ii,1), stat(ii,2), stat(ii,3), stat(ii,4), stat(ii,5), stat(ii,6), stat(ii,7))];
        if size(stat,2)>7
          r = [r, sprintf('\t%e\t%e\t%e\t%e', stat(ii,8), stat(ii,9), stat(ii,10), stat(ii,11))];
        end
        r = [r, newline];
      end
      r = [r, newline];

      if status==0
        r = [r, sprintf('\nsuccess!\n\n')];
      else
        r = [r, sprintf('\nsolution failed!\n\n')];
      end
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
