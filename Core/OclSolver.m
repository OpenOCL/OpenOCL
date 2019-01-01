function solver = OclSolver(system, ocp, options)
  N = options.nlp.controlIntervals;
  ocpHandler = OCPHandler(ocp,system);
  integrator = CollocationIntegrator(system,ocpHandler.pathCostsFun,options.nlp.collocationOrder);
  nlp = Simultaneous(system,integrator,ocpHandler,N);
  ocpHandler.nlpVarsStruct = nlp.nlpVarsStruct;
  
  ocpHandler.pathConstraintsFun     = CasadiFunction(ocpHandler.pathConstraintsFun);
  system.systemFun                  = CasadiFunction(system.systemFun,false,options.system_casadi_mx);
  nlp.integratorFun                 = CasadiFunction(nlp.integratorFun,false,options.system_casadi_mx);
  
  if strcmp(options.solverInterface,'casadi')
    solver = CasadiNLPSolver(nlp,options);
  else
    error('Solver interface not implemented.')
  end
end