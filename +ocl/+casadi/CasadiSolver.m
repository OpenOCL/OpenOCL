classdef CasadiSolver < handle
  
  properties
    timeMeasures
    stageList
    nlpData
    gridpoints
    gridpoints_integrator
  end
  
  properties (Access = private)
    controls_regularization
    controls_regularization_value
  end
  
  methods
    
    function self = CasadiSolver(stageList, transitionList, ...
                                 nlp_casadi_mx, ...
                                 controls_regularization, controls_regularization_value, ...
                                 casadi_options)
      
      oclAssert(length(stageList)==length(transitionList)+1, ...
                'You need to specify Ns-1 transitions for Ns stages.');
              
      self.controls_regularization = controls_regularization;
      self.controls_regularization_value = controls_regularization_value;
      
      constructTotalTic = tic;
      
      % create variables as casadi symbolics
      if nlp_casadi_mx
        expr = @casadi.MX.sym;
      else
        expr = @casadi.SX.sym;
      end
      
      vars = cell(length(stageList), 1);
      costs = cell(length(stageList), 1);
      constraints = cell(length(stageList), 1);
      constraints_LB = cell(length(stageList), 1);
      constraints_UB = cell(length(stageList), 1);
      
      gridpoints = cell(length(stageList), 1);
      gridpoints_integrator = cell(length(stageList), 1);
      
      v_stage = [];
      
      for k=1:length(stageList)
        stage = stageList{k};
        
        states = stage.states;
        algvars = stage.algvars;
        controls = stage.controls;
        parameters = stage.parameters;
        statesOrder = stage.statesOrder;
        
        daefh = stage.daefh;
        pathcostsfh = stage.pathcostsfh;
        gridcostsfh = stage.gridcostsfh;
        gridconstraintsfh = stage.gridconstraintsfh;
        
        nx = stage.nx;
        nu = stage.nu;
        np = stage.np;
        d = stage.d;
        H_norm = stage.H_norm;
        T = stage.T;
        
        collocation = ocl.Collocation(states, algvars, controls, parameters, statesOrder, daefh, pathcostsfh, d);
        
        ni = collocation.num_i;
        nt = collocation.num_t;
        collocationfun = @(x0,vars,u,h,p) ocl.collocation.equations(collocation, x0, vars, u, h, p);
        
        x = expr(['x','_s',mat2str(k)], nx);
        vi = expr(['vi','_s',mat2str(k)], ni);
        u = expr(['u','_s',mat2str(k)], nu);
        h = expr(['h','_s',mat2str(k)]);
        p = expr(['p','_s',mat2str(k)], np);
        
        [xF, cost_integr, equations, rel_times] = collocationfun(x, vi, u, h, p);
        integrator_fun = casadi.Function('sys', {x,vi,u,h,p}, {xF, cost_integr, equations, rel_times});
        
        integratormap = integrator_fun.map(stage.N, 'serial');
        
        nv_stage = ocl.simultaneous.nvars(H_norm, nx, ni, nu, np);
        v_last_stage = v_stage;
        v_stage = expr(['v','_s',mat2str(k)], nv_stage);
        
        gridcostfun = @(k,K,x,p) ocl.model.gridcosts(gridcostsfh, states, parameters, k, K, x, p);
        gridconstraintfun = @(k,K,x,p) ocl.model.gridconstraints(gridconstraintsfh, states, parameters, k, K, x, p);
          
        [costs_stage, constraints_stage, ...
         constraints_LB_stage, constraints_UB_stage] = ...
            ocl.simultaneous.equations(H_norm, T, nx, ni, nu, np, ...
                                       gridcostfun, gridconstraintfun, ...
                                       integratormap, v_stage, ...
                                       controls_regularization, controls_regularization_value);
        
        transition_eq = [];
        transition_lb = [];
        transition_ub = [];
        if k >= 2
          x0s = ocl.simultaneous.getFirstState(stageList{k}, v_stage);
          xfs = ocl.simultaneous.getLastState(stageList{k-1}, v_last_stage);
          transition_fun = transitionList{k-1};
          
          tansition_handler = OclConstraint();
          
          x0 = Variable.create(stageList{k}.states, x0s);
          xf = Variable.create(stageList{k-1}.states, xfs);
          
          transition_fun(tansition_handler,x0,xf);
          
          transition_eq = tansition_handler.values;
          transition_lb = tansition_handler.lowerBounds;
          transition_ub = tansition_handler.upperBounds;
        end
        
        vars{k} = v_stage;
        costs{k} = costs_stage;
        constraints{k} = vertcat(transition_eq, constraints_stage);
        constraints_LB{k} = vertcat(transition_lb, constraints_LB_stage);
        constraints_UB{k} = vertcat(transition_ub, constraints_UB_stage);
        
        gridpoints_integrator{k} = ocl.simultaneous.normalizedIntegratorTimes(H_norm, nt, d);
        gridpoints{k} = ocl.simultaneous.normalizedStateTimes(H_norm);
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
      
      constructSolverTic = tic;
      casadiSolver = casadi.nlpsol('my_solver', 'ipopt', casadiNLP, casadi_options);
      constructSolverTime = toc(constructSolverTic);

      nlpData = struct;
      nlpData.casadiNLP = casadiNLP;
      nlpData.constraints_LB = constraints_LB;
      nlpData.constraints_UB = constraints_UB;
      nlpData.solver = casadiSolver;
      
      timeMeasures.constructTotal = toc(constructTotalTic);
      timeMeasures.constructSolver = constructSolverTime;
      
      self.stageList = stageList;
      self.nlpData = nlpData;
      self.timeMeasures = timeMeasures;
      self.gridpoints = gridpoints;
      self.gridpoints_integrator = gridpoints_integrator;
    end
    
    function getInitialGuess(self)
      stage_list = self.stageList;

      igList = cell(length(stage_list),1);
      for k=1:length(stage_list)
        stage = stage_list{k};
        
        colloc = self.collocationList{k};
        
        N = stage.N;
        states = stage.states;
        integrator_vars = colloc.vars;
        controls = stage.controls;
        parameters = stage.parameters;
        
        varsStruct = ocl.simultaneous.variables(N, states, integrator_vars, controls, parameters);
        ig = ocl.simultaneous.getInitialGuess(stage);
        igList{k} = Variable.create(varsStruct, ig);
      end
    end
    
    function [sol,times,objective,constraints] = solve(self,v0)
      % solve(initialGuess)
      
      solveTotalTic = tic;
      
      pl = self.stageList;
      uregu = self.controls_regularization;
      uregu_value = self.controls_regularization_value;
      
      lbv = cell(length(pl),1);
      ubv = cell(length(pl),1);
      for k=1:length(pl)
        [lbv_stage,ubv_stage] = ocl.simultaneous.getBounds(pl{k});
        lbv{k} = lbv_stage;
        ubv{k} = ubv_stage;
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
      
      if strcmp(self.nlpData.solver.stats().return_status, 'NonIpopt_Exception_Thrown')
        oclWarning('Solver was interrupted by user.');
      end
      
      sol_values = sol.x.full();
      
      sol = cell(length(pl),1);
      i = 1;
      for k=1:length(pl)
        stage = pl{k};
        nv_stage = ocl.simultaneous.nvars(stage.H_norm, stage.nx, stage.integrator.num_i, stage.nu, stage.np);
        sol{k} = sol_values(i:i+nv_stage-1);
        i = i + nv_stage;
      end
      
      nlpFunEvalTic = tic;
      times = cell(length(pl),1);
      objective = cell(length(pl),1);
      constraints = cell(length(pl),1);
      for k=1:length(pl)
        stage = pl{k};
        [objective{k},constraints{k},~,~,times{k}] = ocl.simultaneous.equations(stage, sol{k}, ...
                                                                                uregu, ...
                                                                                uregu_value);
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
