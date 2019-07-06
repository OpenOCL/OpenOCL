function initialize( ...
    T, N, ...
    varsfh, daefh, gridcostsfh, pathcostsfh, gridconstraintsfh, ...
    x0, x_lb, x_ub, u_lb, u_ub)

vars = ocl.model.vars(varsfh);
x_struct = vars.states;
z_struct = vars.algvars;
u_struct = vars.controls;
p_struct = vars.parameters;
x_order = vars.statesOrder;

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

gridconstraintsfun = @(k,K,x,p) ocl.model.gridconstraints( ...
  gridconstraintsfh, ...
  x_struct, ...
  p_struct, ...
  k, K, x, p);

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
[gridconstraints, gridconstraints_lb, gridconstraints_ub] = ...
    gridconstraintsfun(N+1, N+1, x_sym, []);

% bounds
x_bounds_select = ~isinf(x_lb) | ~isinf(x_ub);
u_bounds_select = ~isinf(u_lb) | ~isinf(u_ub);

Jbx = diag(x_bounds_select);
Jbu = diag(u_bounds_select);

Jbx = Jbx(any(Jbx,2),:);
Jbu = Jbu(any(Jbu,2),:);

lbx = x_lb(x_bounds_select);
ubx = x_ub(x_bounds_select);

lbu = u_lb(u_bounds_select);
ubu = u_ub(u_bounds_select);

ocp_model = acados_ocp_model();

% dims
ocp_model.set('T', T);
ocp_model.set('dim_nx', nx);
ocp_model.set('dim_nu', nu);
ocp_model.set('dim_nbx', sum(x_bounds_select));
ocp_model.set('dim_nbu', sum(u_bounds_select));
ocp_model.set('dim_ng', 0);
ocp_model.set('dim_ng_e', 0);
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
ocp_model.set('dyn_type', 'explicit');
ocp_model.set('dyn_expr_f', f_expl);

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
ocp_opts.set('sim_method', 'erk');
ocp_opts.set('sim_method_num_stages', sim_method_num_stages);
ocp_opts.set('sim_method_num_steps', sim_method_num_steps);

disp('initialize done')

ocp = acados_ocp(ocp_model, ocp_opts);

x_traj_init = zeros(nx, N+1);
u_traj_init = zeros(nu, N);
ocp.set('init_x', x_traj_init);
ocp.set('init_u', u_traj_init);

% solve
tic;
ocp.solve();
time_ext = toc


status = ocp.get('status');
sqp_iter = ocp.get('sqp_iter');
time_tot = ocp.get('time_tot');
time_lin = ocp.get('time_lin');
time_reg = ocp.get('time_reg');
time_qp_sol = ocp.get('time_qp_sol');

fprintf('\nstatus = %d, sqp_iter = %d, time_ext = %f [ms], time_int = %f [ms] (time_lin = %f [ms], time_qp_sol = %f [ms], time_reg = %f [ms])\n', status, sqp_iter, time_ext*1e3, time_tot*1e3, time_lin*1e3, time_qp_sol*1e3, time_reg*1e3);

stat = ocp.get('stat');
if (strcmp(nlp_solver, 'sqp'))
	fprintf('\niter\tres_g\t\tres_b\t\tres_d\t\tres_m\t\tqp_stat\tqp_iter');
	if size(stat,2)>7
		fprintf('\tqp_res_g\tqp_res_b\tqp_res_d\tqp_res_m');
	end
	fprintf('\n');
	for ii=1:size(stat,1)
		fprintf('%d\t%e\t%e\t%e\t%e\t%d\t%d', stat(ii,1), stat(ii,2), stat(ii,3), stat(ii,4), stat(ii,5), stat(ii,6), stat(ii,7));
		if size(stat,2)>7
			fprintf('\t%e\t%e\t%e\t%e', stat(ii,8), stat(ii,9), stat(ii,10), stat(ii,11));
		end
		fprintf('\n');
	end
	fprintf('\n');
else % sqp_rti
	fprintf('\niter\tqp_stat\tqp_iter');
	if size(stat,2)>3
		fprintf('\tqp_res_g\tqp_res_b\tqp_res_d\tqp_res_m');
	end
	fprintf('\n');
	for ii=1:size(stat,1)
		fprintf('%d\t%d\t%d', stat(ii,1), stat(ii,2), stat(ii,3));
		if size(stat,2)>3
			fprintf('\t%e\t%e\t%e\t%e', stat(ii,4), stat(ii,5), stat(ii,6), stat(ii,7));
		end
		fprintf('\n');
	end
	fprintf('\n');
end



if status==0
	fprintf('\nsuccess!\n\n');
else
	fprintf('\nsolution failed!\n\n');
end
