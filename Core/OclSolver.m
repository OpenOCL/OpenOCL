function solver = OclSolver(system, ocp, options)
  N = options.nlp.controlIntervals;
  integrator = CollocationIntegrator(system,options.nlp.collocationOrder);
  nlp = Simultaneous(system,integrator,N);

  ocpHandler = OCPHandler(ocp,system,nlp.varsStruct);
  integrator.ocpHandler = ocpHandler;
  nlp.ocpHandler = ocpHandler;

  if ~options.debug
    ocpHandler.pathConstraintsFun     = CasadiFunction(ocpHandler.pathConstraintsFun);
    system.systemFun                  = CasadiFunction(system.systemFun,false,options.system_casadi_mx);
    nlp.integratorFun                 = CasadiFunction(nlp.integratorFun,false,options.system_casadi_mx);
  end
    
  if strcmp(options.solverInterface,'casadi')
    solver = CasadiNLPSolver(nlp,options);
  else
    error('Solver interface not implemented.')
  end 
end