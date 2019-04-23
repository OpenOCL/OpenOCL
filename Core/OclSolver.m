function solver = OclSolver(T, system, ocp, options, varargin)
  % OclSolver(T, system, ocp, options, H_norm)
  % OclSolver(phase, options)
  % OclSolver(phaseList, options)
  % OclSolver(T, @varsfun, @daefun, @ocpfuns... , options)
  preparationTic = tic;
  
  ocpHandler = OclPhaseHandler(phaseList,options);
  ocpHandler.setup();
  
  N = options.nlp.controlIntervals;
  integrator = CollocationIntegrator(system,options.nlp.collocationOrder);
  nlp = Simultaneous(system,ocpHandler,integrator,N,options);
  
  ocpHandler.setNlpVarsStruct(nlp.varsStruct);
  integrator.pathCostsFun = ocpHandler.pathCostsFun;
  nlp.ocpHandler = ocpHandler;

  
  ocpHandler.pathConstraintsFun     = CasadiFunction(ocpHandler.pathConstraintsFun);
  system.systemFun                  = CasadiFunction(system.systemFun,false,options.system_casadi_mx);
  nlp.integratorFun                 = CasadiFunction(nlp.integratorFun,false,options.system_casadi_mx);
  
  nlp.integratorMap = CasadiMapFunction(nlp.integratorFun,N);
  nlp.pathconstraintsMap = CasadiMapFunction(ocpHandler.pathConstraintsFun, N-1);
    
  if strcmp(options.solverInterface,'casadi')
    preparationTime = toc(preparationTic);
    solver = CasadiNLPSolver(nlp,options);
    solver.timeMeasures.preparation = preparationTime;
  else
    error('Solver interface not implemented.')
  end 
end