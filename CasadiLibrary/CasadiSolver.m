classdef CasadiSolver < handle
  
  properties (Access = private)
    phaseList
    nlpData
    options
    timeMeasures
  end
  
  methods
    
    function self = CasadiSolver(phaseList, options)
      
      constructTotalTic = tic;
      
      % create variables as casadi symbolics
      if options.nlp_casadi_mx
        expr = @casadi.MX.sym;
      else
        expr = @casadi.SX.sym;
      end
      
      for k=1:length(phaseList)
        phase = phaseList{k};
        
%         if k >= 2
%           xf = expr('x', system.nx);
%           x0 = expr('x', system.nx);
%           connection_fun = connectionList{k-1};
%           conection_eq = connection_fun(xf,x0);
%         end
        
        x = expr('x', phase.nx);
        u = expr('z', phase.nu);
        p = expr('p', phase.np);
        vi = expr('vi', phase.integrator.ni);
        h = expr('h');
        
        % integration
%         dae_expr = phase.daefun(x,z,u,p);
%         dae_fun = casadi.Function('sys', {x,z,u,p}, {dae_expr});
%         
%         lagrangecost_expr = phase.lagrangecostfun(x,z,u,p);
%         lagrangecost_fun = casadi.Function('pcost', {x,z,u,p}, {lagrangecost_expr});

        [statesEnd, costs, equations, rel_times] = phase.integrator.integratorfun(x, vi, u, h, p);
        integrator_fun = casadi.Function('sys', {x,vi,u,h,p}, {statesEnd, costs, equations, rel_times});
        
        phase.integratormap = integrator_fun.map(phase.N,'openmp');
        
        nv_phase = Simultaneous.nvars(phase.H_norm, phase.nx, phase.integrator.ni, phase.nu, phase.np);
        v = expr('v', nv_phase);
          
        [costs,constraints,constraints_LB,constraints_UB,~] = Simultaneous.simultaneous(phase, v);
        
      end
      
      % get struct with nlp for casadi
      casadiNLP = struct;
      casadiNLP.x = v;
      casadiNLP.f = costs;
      casadiNLP.g = constraints;
      casadiNLP.p = [];
      
      opts = options.nlp.casadi;
      if isfield(options.nlp,options.nlp.solver)
        opts.(options.nlp.solver) = options.nlp.(options.nlp.solver);
      end
      
      constructSolverTic = tic;
      casadiSolver = casadi.nlpsol('my_solver', options.nlp.solver,... 
                                   casadiNLP, opts);

      constructSolverTime = toc(constructSolverTic);

      nlpData = struct;
      nlpData.casadiNLP = casadiNLP;
      nlpData.constraints_LB = constraints_LB;
      nlpData.constraints_UB = constraints_UB;
      nlpData.solver = casadiSolver;
      
      timeMeasures.constructTotal = toc(constructTotalTic);
      timeMeasures.constructSolver = constructSolverTime;
      
      self.phaseList = phaseList;
      self.nlpData = nlpData;
      self.options = options;
      self.timeMeasures = timeMeasures;
    end
    
    function [outVars,times,objective,constraints] = solve(self,v0)
      % solve(initialGuess)
      
      solveTotalTic = tic;
      
      [lbv,ubv] = Simultaneous.getNlpBounds(self.phaseList);
 
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
      
      outVars = sol.x.full();
      
      
      nlpFunEvalTic = tic;
      if nargout > 1
        [objective,constraints,~,~,times] =Simultaneous.simultaneous(self.phaseList{1}, outVars);
      end
      nlpFunEvalTime = toc(nlpFunEvalTic);

      times = times.full();
      
      self.timeMeasures.solveTotal      = toc(solveTotalTic);
      self.timeMeasures.solveCasadi     = solveCasadiTime;
      self.timeMeasures.nlpFunEval      = nlpFunEvalTime;
      
      oclWarningNotice()
    end
  end
  
end
