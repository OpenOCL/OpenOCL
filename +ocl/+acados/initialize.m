function initialize(stage)

H_norm = stage.H_norm;

oclAssert(isequal(H_norm(2:end), H_norm(1:end-1)), 'Only uniform discretizatin is supported with acados at the moment.');

T = stage.T;
N = length(H_norm);
nx = stage.nx;
nu = stage.nu;

oclAssert(stage.nz==0, 'No algebraic variable are currently support in the acados interface.');

daefun = stage.integrator.daefun;

casadi_sym = @casadi.SX.sym;

x_sym = casadi_sym('x',nx);
u_sym = casadi_sym('u',nu);
xd_sym = casadi_sym('xd',nx);

% system equations
[ode,~] = daefun(x_sym, [], u_sym, []);
f_impl = ode - xd_sym;

% lagrange cost
ch = OclCost();
pathcostfun(ch, x_sym, [], u_sym, []);
lagrange_cost = ch.value;

% mayer cost
ch = OclCost();
gridcostfun(ch, N+1, N+1, x_sym, []);
mayer_cost = ch.value;

% end constraints
ch = OclConstraint();
gridconstraintsfun(ch, N+1, N+1, x_sym, []);
end_constraints = ch.values;
end_constraints_lb = ch.lowerBounds;
end_constraints_ub = ch.upperBounds;

% bounds
x_lb = stateBounds.lower;
x_ub = stateBounds.upper;

u_lb = controlBounds.lower;
u_ub = controlBounds.upper;


ocp_model = acados_ocp_model();

% dims
ocp_model.set('T', T);
ocp_model.set('dim_nx', nx);
ocp_model.set('dim_nu', nu);
ocp_model.set('dim_nbx', nbx);
ocp_model.set('dim_nbu', nbu);
ocp_model.set('dim_ng', 0);
ocp_model.set('dim_ng_e', ng_e);
ocp_model.set('dim_nh', 0);
ocp_model.set('dim_nh_e', 0);

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
ocp_model.set('dyn_type', 'implicit');
ocp_model.set('dyn_expr_f', f_impl);

% constraints
ocp_model.set('constr_x0', x0);
ocp_model.set('constr_Jbx', Jbx);
ocp_model.set('constr_lbx', lbx);
ocp_model.set('constr_ubx', ubx);
ocp_model.set('constr_Jbu', Jbu);
ocp_model.set('constr_lbu', lbu);
ocp_model.set('constr_ubu', ubu);

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

ocp_opts = acados_ocp_opts();
ocp_opts.set('compile_mex', 'true');
ocp_opts.set('codgen_model', 'true');
ocp_opts.set('param_scheme', 'multiple_shooting_unif_grid');
ocp_opts.set('param_scheme_N', N);
ocp_opts.set('nlp_solver', 'sqp');
ocp_opts.set('nlp_solver_exact_hessian', 'true');
ocp_opts.set('regularize_method', 'project_reduc_hess');
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
ocp_opts.set('sim_method', 'irk');
ocp_opts.set('sim_method_num_stages', sim_method_num_stages);
ocp_opts.set('sim_method_num_steps', sim_method_num_steps);