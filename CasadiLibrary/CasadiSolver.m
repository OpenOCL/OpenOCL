classdef CasadiSolver < handle
  
  properties
    timeMeasures
    phaseList
    nlpData
    options
  end
  
  properties (Access = private)

  end
  
  methods
    
    function self = CasadiSolver(phaseList, transitionList, options)
      
      oclAssert(length(phaseList)==length(transitionList)+1, ...
                'You need to specify Np-1 transitions for Np phases.');
      
      constructTotalTic = tic;
      
      % create variables as casadi symbolics
      if options.nlp_casadi_mx
        expr = @casadi.MX.sym;
      else
        expr = @casadi.SX.sym;
      end
      
      vars = cell(length(phaseList), 1);
      costs = cell(length(phaseList), 1);
      constraints = cell(length(phaseList), 1);
      constraints_LB = cell(length(phaseList), 1);
      constraints_UB = cell(length(phaseList), 1);
      
      v_phase = [];
      
      for k=1:length(phaseList)
        phase = phaseList{k};
        
        x = expr('x', phase.nx);
        u = expr('z', phase.nu);
        p = expr('p', phase.np);
        vi = expr('vi', phase.integrator.ni);
        h = expr('h');
        
        [statesEnd, cost_integr, equations, rel_times] = phase.integrator.integratorfun(x, vi, u, h, p);
        integrator_fun = casadi.Function('sys', {x,vi,u,h,p}, {statesEnd, cost_integr, equations, rel_times});
        
        phase.integratormap = integrator_fun.map(phase.N,'openmp');
        
        nv_phase = Simultaneous.nvars(phase.H_norm, phase.nx, phase.integrator.ni, phase.nu, phase.np);
        v_last_phase = v_phase;
        v_phase = expr('v', nv_phase);
          
        [costs_phase,constraints_phase,constraints_LB_phase,constraints_UB_phase,~] = Simultaneous.simultaneous(phase, v_phase);
        
        transition_eq = [];
        transition_lb = [];
        transition_ub = [];
        if k >= 2
          x0s = Simultaneous.first_state(phaseList{k}, v_phase);
          xfs = Simultaneous.last_state(phaseList{k-1}, v_last_phase);
          transition_fun = transitionList{k-1};
          tansition_handler = OclConstraint();
          
          x0 = Variable.create(phaseList{k}.states, x0s);
          xf = Variable.create(phaseList{k-1}.states, xfs);
          
          transition_fun(tansition_handler,x0,xf);
          
          transition_eq = tansition_handler.values;
          transition_lb = tansition_handler.lowerBounds;
          transition_ub = tansition_handler.upperBounds;
        end
        
        vars{k} = v_phase;
        costs{k} = costs_phase;
        constraints{k} = vertcat(transition_eq,constraints_phase);
        constraints_LB{k} = vertcat(transition_lb,constraints_LB_phase);
        constraints_UB{k} = vertcat(transition_ub,constraints_UB_phase);
      end
      
      v = vertcat(vars{:});
      costs = sum([costs{:}]);
      constraints = vertcat(constraints{:});
      constraints_LB = vertcat(constraints_LB{:});
      constraints_UB = vertcat(constraints_UB{:});
      
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
    
    function [sol,times,objective,constraints] = solve(self,v0)
      % solve(initialGuess)
      
      solveTotalTic = tic;
      
      pl = self.phaseList;
      
      lbv = cell(length(pl),1);
      ubv = cell(length(pl),1);
      for k=1:length(pl)
        [lbv_phase,ubv_phase] = Simultaneous.getNlpBounds(pl{k});
        lbv{k} = lbv_phase;
        ubv{k} = ubv_phase;
      end
      
      v0 = vertcat(v0{:});
      lbv = vertcat(lbv{:});
      ubv = vertcat(ubv{:});
 
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
      
      sol_values = sol.x.full();
      
      sol = cell(length(pl),1);
      i = 1;
      for k=1:length(pl)
        phase = pl{k};
        nv_phase = Simultaneous.nvars(phase.H_norm, phase.nx, phase.integrator.ni, phase.nu, phase.np);
        sol{k} = sol_values(i:i+nv_phase-1);
        i = i + nv_phase;
      end
      
      nlpFunEvalTic = tic;
      times = cell(length(pl),1);
      objective = cell(length(pl),1);
      constraints = cell(length(pl),1);
      for k=1:length(pl)
        phase = pl{k};
        [objective{k},constraints{k},~,~,times{k}] = Simultaneous.simultaneous(phase, sol{k});
        objective{k} = full(objective{k});
        constraints{k} = full(constraints{k});
        times{k} = full(times{k});
      end
      nlpFunEvalTime = toc(nlpFunEvalTic);
      
      self.timeMeasures.solveTotal      = toc(solveTotalTic);
      self.timeMeasures.solveCasadi     = solveCasadiTime;
      self.timeMeasures.nlpFunEval      = nlpFunEvalTime;
    end
  end
  
end
