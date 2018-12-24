classdef Solver < handle
  %SOLVER Solver class
  
  properties
  end
  
  methods(Abstract)
    solve(initialGuess)
  end
  
  methods(Static)
    function options = getOptions()
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
%       options.nlp.ipopt.acceptable_tol = 1e-3;
%       options.nlp.ipopt.tol = 1e-5;

%       options.nlp.ipopt.constr_viol_tol = 1e-6;
%       options.nlp.ipopt.compl_inf_tol = 1e-6;
%       options.nlp.ipopt.expect_infeasible_problem = 'no';
%       options.nlp.ipopt.start_with_resto = 'no';
%       options.nlp.ipopt.check_derivatives_for_naninf = 'no';
%       options.nlp.ipopt.print_info_string = 'no';
      
%       options.nlp.ipopt.nlp_scaling_max_gradient = 10;
%       options.nlp.ipopt.nlp_scaling_min_value = 0.1;
%       options.nlp.ipopt.mu_strategy = 'monotone';
      
      
      options.nlp.ipopt.hessian_approximation = 'exact';

    end
    
    function nlp = getNLP(ocp,system,options)
      
      if isfield(options.nlp,'discretizationPoints') && ...
         isnumeric(options.nlp.discretizationPoints)
        error(['You are using a deprecated option: Please use ', ...
               'the option field "options.nlp.controlIntervals" instead of ', ...
               '"options.nlp.discretizationPoints" for the Solver.']);
      end
      
      N = options.nlp.controlIntervals;
      ocpHandler = OCPHandler(ocp,system);
      integrator = CollocationIntegrator(system,ocpHandler.pathCostsFun,options.nlp.collocationOrder);
      nlp = Simultaneous(system,integrator,ocpHandler,N);
      
%       ocpHandler.pathCostsFun           = CasadiFunction(ocpHandler.pathCostsFun);
%       ocpHandler.arrivalCostsFun        = CasadiFunction(ocpHandler.arrivalCostsFun);
%       ocpHandler.boundaryConditionsFun  = CasadiFunction(ocpHandler.boundaryConditionsFun);
%       ocpHandler.pathConstraintsFun     = CasadiFunction(ocpHandler.pathConstraintsFun);
      system.systemFun                  = CasadiFunction(system.systemFun,false,true);
      nlp.integratorFun                 = CasadiFunction(nlp.integratorFun);

    end
    
    function solver = getSolver(nlp,options)
      
      if strcmp(options.solverInterface,'casadi')
        solver = CasadiNLPSolver(nlp,options);
      else
        error('Solver interface not implemented.')
      end
      
    end
    
  end
  
  methods
    
    function self = Solver()
      
    end

  end
  
end

