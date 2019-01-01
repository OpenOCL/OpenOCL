classdef OCL < handle
  methods (Static)
    function solver = Solver(system, ocp, options)
      
      N = options.nlp.controlIntervals;
      integrator = CollocationIntegrator(system,options.nlp.collocationOrder);
      nlp = Simultaneous(system,integrator,N);

      ocpHandler = OCPHandler(ocp,system,nlp.varsStruct);
      integrator.ocpHandler = ocpHandler;
      nlp.ocpHandler = ocpHandler;

      % ocpHandler.pathConstraintsFun     = CasadiFunction(ocpHandler.pathConstraintsFun);
      % system.systemFun                  = CasadiFunction(system.systemFun,false,options.system_casadi_mx);
      % nlp.integratorFun                 = CasadiFunction(nlp.integratorFun,false,options.system_casadi_mx);

      if strcmp(options.solverInterface,'casadi')
        solver = CasadiNLPSolver(nlp,options);
      else
        error('Solver interface not implemented.')
      end 
    end
    
    function options = Options()
      options = struct;
      options.solverInterface   = 'casadi';
      options.iterationCallback = false;
      options.system_casadi_mx  = false;
      options.nlp = struct;
      options.nlp.discretization         = 'collocation';
      options.nlp.controlIntervals       = 20;
      options.nlp.collocationOrder       = 3;
      options.nlp.solver                 = 'ipopt';
      options.nlp.scaling                = false;
      options.nlp.detectParameters       = false;
      options.nlp.outputLifting          = false;
      options.nlp.casadi.iteration_callback_step = 1;
      options.nlp.ipopt = struct;
      options.nlp.ipopt.linear_solver = 'mumps';
      options.nlp.ipopt.hessian_approximation = 'exact';
    end
  end
end