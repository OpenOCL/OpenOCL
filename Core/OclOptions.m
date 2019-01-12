function options = OclOptions()
  options = struct;
  options.solverInterface   = 'casadi';
  options.iterationCallback = false;
  options.system_casadi_mx  = false;
  options.nlp = struct;
  options.nlp.discretization         = 'collocation';
  options.nlp.controlIntervals       = 20;
  options.nlp.collocationOrder       = 3;
  options.nlp.solver                 = 'ipopt';
  options.nlp.detectParameters       = false;
  options.nlp.outputLifting          = false;
  options.nlp.casadi.iteration_callback_step = 1;
  options.nlp.ipopt = struct;
  options.nlp.ipopt.linear_solver = 'mumps';
  options.nlp.ipopt.hessian_approximation = 'exact';
end