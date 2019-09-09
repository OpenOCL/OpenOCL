function ocp = construct( ...
    nx, nu, ...
    T, N, ...
    daefun, gridcostfun, pathcostfun, gridconstraintfun, ...
    terminalcostfun, ...
    lbx, ubx, Jbx, lbu, ubu, Jbu, ...
    acados_build_dir, ...
    build_model, ...
    print_level)

casadi_sym = @casadi.SX.sym;

x_sym = casadi_sym('x', nx);
u_sym = casadi_sym('u', nu);
xd_sym = casadi_sym('xd', nx);

% system equations
[ode,~] = daefun(x_sym, [], u_sym, []);
f_expl = ode;

lagrange_cost = pathcostfun(x_sym, [], u_sym, []);
mayer_cost = gridcostfun(N+1, N+1, x_sym, []);

% end constraints
[endconstraints, endconstraints_lb, endconstraints_ub] = ...
    gridconstraintfun(N+1, N+1, x_sym, []);

% interface compatibility checks
ocl.utils.assert(~isempty(T), 'Free endtime is not supported in the acados interface. In most cases it is possible to reformulate a time-optimal control problem by doing a coordinate transformation.')

for k=1:N
  gridcost = gridcostfun(k, N+1, x_sym, []);
  ocl.utils.assert(gridcost == 0, 'In the gridcosts only terminal cost (mayer cost) are supported in the acados interface.');
end

for k=1:N
  [gridconstraint,~,~] = gridconstraintfun(k, N+1, x_sym, []);
  ocl.utils.assert(isempty(gridconstraint), 'In the gridconstraints only terminal constraints are supported in the acados interface.');
end

mayer_cost = mayer_cost + terminalcostfun(x_sym, []);

n_endconstraints = length(endconstraints);

ocp_model = acados_ocp_model();

% dims
ocp_model.set('T', T);
ocp_model.set('dim_nx', nx);
ocp_model.set('dim_nu', nu);
ocp_model.set('dim_nbx', length(lbx));
ocp_model.set('dim_nbu', length(lbu));
ocp_model.set('dim_ng', 0);
ocp_model.set('dim_ng_e', 0);
ocp_model.set('dim_nh', 0);
ocp_model.set('dim_nh_e', n_endconstraints);

% symbolics
ocp_model.set('sym_x', x_sym);
ocp_model.set('sym_u', u_sym);
ocp_model.set('sym_xdot', xd_sym);

% cost
ocp_model.set('cost_type', 'ext_cost');
ocp_model.set('cost_type_e', 'ext_cost'); % mayer
ocp_model.set('cost_expr_ext_cost', lagrange_cost);
ocp_model.set('cost_expr_ext_cost_e', mayer_cost);

% dynamics
ocp_model.set('dyn_type', 'explicit');
ocp_model.set('dyn_expr_f', f_expl);

% bounds
ocp_model.set('constr_lbx', lbx);
ocp_model.set('constr_ubx', ubx);
ocp_model.set('constr_Jbx', Jbx);

ocp_model.set('constr_lbu', lbu);
ocp_model.set('constr_ubu', ubu);
ocp_model.set('constr_Jbu', Jbu);

% constraints (non-linear terminal)
if ~isempty(endconstraints)
  ocp_model.set('constr_expr_h_e', endconstraints);
  ocp_model.set('constr_lh_e', endconstraints_lb);
  ocp_model.set('constr_uh_e', endconstraints_ub);
end

%% acados ocp opts
nlp_solver_ext_qp_res = 1;
nlp_solver_max_iter = 100;
nlp_solver_tol_stat = 1e-8;
nlp_solver_tol_eq   = 1e-8;
nlp_solver_tol_ineq = 1e-8;
nlp_solver_tol_comp = 1e-8;
qp_solver_cond_N = 5;
qp_solver_cond_ric_alg = 0;
qp_solver_ric_alg = 0;
qp_solver_warm_start = 2;
sim_method_num_stages = 4;
sim_method_num_steps = 3;

if build_model
  codgen_model = 'true';
  ocl.utils.info('Compiling model...')
  mex_files = cellstr(ls(fullfile(ocl.utils.workspacePath, 'export', ['*.', mexext])));
  
  for k=1:length(mex_files)
    [~, mex_name] = fileparts(mex_files{k});
    clear(mex_name)
  end
else
  codgen_model = 'false';
end

ocp_opts = acados_ocp_opts();
nlp_solver = 'sqp';
ocp_opts.set('compile_mex', 'false');
ocp_opts.set('codgen_model', codgen_model);
ocp_opts.set('param_scheme', 'multiple_shooting_unif_grid');
ocp_opts.set('param_scheme_N', N);
ocp_opts.set('nlp_solver', nlp_solver);
ocp_opts.set('nlp_solver_exact_hessian', 'false');
ocp_opts.set('regularize_method', 'no_regularize');
ocp_opts.set('nlp_solver_ext_qp_res', nlp_solver_ext_qp_res);
ocp_opts.set('nlp_solver_max_iter', nlp_solver_max_iter);
ocp_opts.set('nlp_solver_tol_stat', nlp_solver_tol_stat);
ocp_opts.set('nlp_solver_tol_eq', nlp_solver_tol_eq);
ocp_opts.set('nlp_solver_tol_ineq', nlp_solver_tol_ineq);
ocp_opts.set('nlp_solver_tol_comp', nlp_solver_tol_comp);
ocp_opts.set('qp_solver', 'partial_condensing_hpipm');
ocp_opts.set('qp_solver_cond_N', qp_solver_cond_N);
ocp_opts.set('qp_solver_cond_ric_alg', qp_solver_cond_ric_alg);
ocp_opts.set('qp_solver_ric_alg', qp_solver_ric_alg);
ocp_opts.set('qp_solver_warm_start', qp_solver_warm_start);
ocp_opts.set('sim_method', 'erk');
ocp_opts.set('sim_method_num_stages', sim_method_num_stages);
ocp_opts.set('sim_method_num_steps', sim_method_num_steps);

ocp_opts.set('output_dir', acados_build_dir);

ocp = acados_ocp(ocp_model, ocp_opts);
setenv('OCL_MODEL_DATENUM', num2str(now));
setenv('OCL_MODEL_N', num2str(N));

x_traj_init = zeros(nx, N+1);
u_traj_init = zeros(nu, N);
ocp.set('init_x', x_traj_init);
ocp.set('init_u', u_traj_init);


if print_level >= 5 
  ocl.utils.debug('Acados debug ocp model: ');
  names = fieldnames(ocp_model.model_struct);
  for k=1:length(names)
    ocl.utils.debug([names{k}, ': ']);
    ocl.utils.debug(ocp_model.model_struct.(names{k}));
    ocl.utils.debug(' ');
  end
  
  ocl.utils.debug('Acados debug ocp options: ');
  names = fieldnames(ocp_opts.opts_struct);
  for k=1:length(names)
    ocl.utils.debug([names{k}, ': ']);
    ocl.utils.debug(ocp_opts.opts_struct.(names{k}));
    ocl.utils.debug(' ');
  end
  
end
