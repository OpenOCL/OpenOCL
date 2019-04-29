function solver = OclSolver(varargin)
  % OclSolver(T, system, ocp, options, H_norm)
  % OclSolver(phase, options)
  % OclSolver(phaseList, options)
  % OclSolver(T, @varsfun, @daefun, @ocpfuns... , options)
  % OclSolver(phaseList, integratorList, options)
  preparationTic = tic;
  
  phaseList = {};
  
  if isnumeric(varargin{1}) && isa(varargin{2}, 'OclSystem')
    % OclSolver(T, system, ocp, options, H_norm)
    T = varargin{1};
    system = varargin{2};
    ocp = varargin{3};
    options = varargin{4};
    
    N = options.nlp.controlIntervals;
    d = options.nlp.collocationOrder;
    
    if nargin >= 5
      H_norm = varargin{5};
    else
      H_norm = repmat(1/N,1,N);
    end
    
    if length(T) == 1
      % T = final time
    elseif length(T) == N+1
      % T = N+1 timepoints at states
      H_norm = (T(2:N+1)-T(1:N))/ T(end);
      T = T(end);
    elseif length(T) == N
      % T = N timesteps
      H_norm = T/sum(T);
      T = sum(T);
    elseif isempty(T)
      % T = [] free end time
      T = [];
    else
      oclError('Dimension of T does not match the number of control intervals.')
    end
    
    fhPC = @(self,varargin) getPathCosts(s, varargin{:});
    pathcostfun = OclFunction(fhPC, {system.states,system.algvars,system.controls,system.parameters}, 1);
    
    integrator = OclCollocation(system.states, system.algvars, system.nu, system.np, system.daefun, d);
    
    phase = OclPhase(T, system.varsfh, system.daefh, ocp.pathcosts, ...
                     ocp.arrivalcosts, ocp.pathconstraints, ...
                     ocp.boundaryconditions, ocp.discretecosts, H_norm, integrator);
    phaseList{1} = phase;
  end
  
  nlp = Simultaneous(phaseList,options);
  
  phaseHandler.setNlpVarsStruct(nlp.varsStruct);
  integrator.pathCostsFun = phaseHandler.pathCostsFun;
  nlp.ocpHandler = phaseHandler;
    
  if strcmp(options.solverInterface,'casadi')
    preparationTime = toc(preparationTic);
    solver = CasadiNLPSolver(nlp,options);
    solver.timeMeasures.preparation = preparationTime;
  else
    error('Solver interface not implemented.')
  end 
end