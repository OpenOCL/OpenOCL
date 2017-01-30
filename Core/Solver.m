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
      
      options.nlp = struct;
      options.nlp.discretization        = 'collocation';
      options.nlp.discretizationPoints  = 20;
      options.nlp.collocationOrder      = 3;
      options.nlp.solver                = 'ipopt';
      options.nlp.scaling               = true;
      options.nlp.detectParameters      = true;

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
    
    function nlp = getNLP(ocp,model,options)
      
      N = options.nlp.discretizationPoints;
      parameters = ocp.getParameters;
      integrator = CollocationIntegrator(model,options.nlp.collocationOrder,parameters);
      
      nlp = Simultaneous(model,integrator,N);
      
      ocpHandler = OCPHandler(ocp,nlp.nlpVars);

      nlp.setOcpHandler(ocpHandler);
      integrator.setPathCostsFun(ocpHandler.pathCostsFun);
      
      ocpHandler.pathCostsFun           = CasadiFunction(ocpHandler.pathCostsFun);
      ocpHandler.terminalCostsFun       = CasadiFunction(ocpHandler.terminalCostsFun);
      ocpHandler.boundaryConditionsFun  = CasadiFunction(ocpHandler.boundaryConditionsFun);
      ocpHandler.pathConstraintsFun     = CasadiFunction(ocpHandler.pathConstraintsFun);
      model.modelFun = CasadiFunction(model.modelFun);
      nlp.integratorFun          = CasadiFunction(nlp.integratorFun);
%       ocpHandler.leastSquaresCostsFun   = CasadiFunction(ocpHandler.leastSquaresCostsFun);

      
%       nlp.nlpFun = CasadiFunction(nlp.nlpFun);
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

