classdef CasadiSolver < NLPSolver
  
  properties (Access = private)
    nlpData
    options
  end
  
  methods
    
    function self = CasadiSolver(system, phaseList,options)
      
      constructTotalTic = tic;
      
      % create variables as casadi symbolics
      if options.nlp_casadi_mx
        vars = casadi.MX.sym('v', nlp.nv,1);
      else
        vars = casadi.SX.sym('v', nlp.nv,1);
      end
      
      for k=1:length(phaseList)
        phase = phaseList{k};
        
        x = expr('x', system.nx);
        z = expr('u', system.nz);
        u = expr('z', system.nu);
        p = expr('p', system.np);
        x0 = expr('x0', system.nx);
        xF = expr('xF', system.nx);
        vi = expr('vi', integrator.ni);
        t0 = expr('t0');
        h = expr('h');
        
        % integration
        system_expr = phase.daefun(x,z,u,p);
        system_fun = casadi.Function('sys', {x,z,u,p}, {system_expr});
        
        systemcost_expr = phase.systemcostfun(x,z,u,p);
        systemcost_fun = casadi.Function('pcost', {x,z,u,p}, {systemcost_expr});

        integrator_expr = phase.integratorfun(x0, vi, u, t0, h, p, system_fun, systemcost_fun);
        integrator_fun = casadi.Function('sys', {x0,vi,u,t0,h,p}, {integrator_expr});
        
        % cost
        initialcost_expr = phase.initialcostfun(x0,p);
        initialcost_fun = casadi.Function('inicost', {x0,p}, {initialcost_expr});
        
        arrivalcost_expr = phase.arrivalcostfun(xF,p);
        arrivalcost_fun = casadi.Function('arrcost', {xF,p}, {arrivalcost_expr});
        
        pathcost_expr = phase.pathcostfun(x,p);
        pathcost_fun = casadi.Function('cost', {x,p}, {pathcost_expr});
        
        % constraints
        initialcon_expr = phase.initialconfun(x0,p);
        initialcon_fun = casadi.Function('inicon', {x0,p}, {initialcon_expr});
        
        arrivalcon_expr = phase.initialconfun(xF,p);
        arrivalcon_fun = casadi.Function('arrcon', {xF,p}, {arrivalcon_expr});
        
        pathcon_expr = phase.pathconfun(x,p);
        pathcon_fun = casadi.Function('pcon', {x,p}, {pathcon_expr});

        % stage function holds on all nodes except first and last (N-1 nodes)
        stage_fun = casadi.Function('stage', {x,p}, {pathcost_expr, pathcon_expr});
        
        integrator_map = integrator_fun.map(phase.N,'openmp');
        stage_map = stage_fun.map(phase.N-1,'openmp');
        
        [costs,constraints,constraints_LB,constraints_UB,~] = simultaneous( ...
            H_norm, T, ...
            xp, ni, nz, nu, np, integrator_map, stage_map, ...
            pathcost_fun, initialcost_fun, arrivalcost_fun, pathcon_fun, initialcon_fun, arrivalcon_fun);
        
      end
      
      
      
      % get struct with nlp for casadi
      casadiNLP = struct;
      casadiNLP.x = vars;
      casadiNLP.f = costs;
      casadiNLP.g = constraints;
      casadiNLP.p = [];
      
      opts = self.options.nlp.casadi;
      if isfield(self.options.nlp,self.options.nlp.solver)
        opts.(self.options.nlp.solver) = self.options.nlp.(self.options.nlp.solver);
      end
      
      constructSolverTic = tic;
      casadiSolver = casadi.nlpsol('my_solver', self.options.nlp.solver,... 
                                   casadiNLP, opts);

      constructSolverTime = toc(constructSolverTic);

      nlpData = struct;
      nlpData.casadiNLP = casadiNLP;
      nlpData.constraints_LB = constraints_LB;
      nlpData.constraints_UB = constraints_UB;
      nlpData.solver = casadiSolver;
      self.timeMeasures.constructTotal = toc(constructTotalTic);
      self.timeMeasures.constructSolver = constructSolverTime;
    end
    
    function [outVars,times,objective,constraints] = solve(self,initialGuess)
      % solve(initialGuess)
      
      solveTotalTic = tic;
      
      v0 = initialGuess.value;
      
      [lbv,ubv] = self.nlp.getNlpBounds();
 
      args = struct;
      args.lbg = self.nlpData.constraints_LB;
      args.ubg = self.nlpData.constraints_UB;
      args.p = [];
      args.lbx = lbv;
      args.ubx = ubv;
      args.x0 = v0;
      
      % execute solver
      solveCasadiTic = tic;
      sol = self.nlpData.solver.call(args);
      solveCasadiTime = toc(solveCasadiTic);
      
      if strcmp(self.options.nlp.solver,'ipopt') && strcmp(self.nlpData.solver.stats().return_status,'NonIpopt_Exception_Thrown')
        oclWarning('Solver was interrupted by user.');
      end
      
      solution = sol.x.full();
      
      nlpFunEvalTic = tic;
      if nargout > 1
        [objective,constraints,~,~,times] = self.nlp.nlpFun.evaluate(solution);
      end
      nlpFunEvalTime = toc(nlpFunEvalTic);
      
      times = Variable.createNumeric(self.nlp.timesStruct,full(times));

      initialGuess.set(solution);
      outVars = initialGuess;
      
      self.timeMeasures.solveTotal      = toc(solveTotalTic);
      self.timeMeasures.solveCasadi     = solveCasadiTime;
      self.timeMeasures.nlpFunEval      = nlpFunEvalTime;
      
      oclWarningNotice()
    end
  end
  
end
