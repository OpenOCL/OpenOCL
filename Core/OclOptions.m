function opt = OclOptions()
  opt = struct;
  opt.solverInterface   = 'casadi';
  opt.system_casadi_mx  = false;
  opt.nlp_casadi_mx     = false;
  opt.controls_regularization = true;
  opt.controls_regularization_value = 1e-6;
  opt.path_constraints_at_boundary = true;
  opt.nlp = struct;
  opt.nlp.discretization         = 'collocation';
  opt.nlp.controlIntervals       = 20;
  opt.nlp.collocationOrder       = 3;
  opt.nlp.solver                 = 'ipopt';
  opt.nlp.casadi = struct;
  opt.nlp.ipopt = struct;
  opt.nlp.ipopt.linear_solver = 'mumps';
  opt.nlp.ipopt.hessian_approximation = 'exact';
end