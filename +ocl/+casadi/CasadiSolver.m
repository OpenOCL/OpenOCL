classdef CasadiSolver < handle
  
  properties
    timeMeasures
    stageList
    collocationList
    nlpData
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
      
      v_stage = [];
      
      collocationList = cell(length(stageList), 1);
      
      for k=1:length(stageList)
        stage = stageList{k};
        
        x_struct = stage.x_struct;
        z_struct = stage.z_struct;
        u_struct = stage.u_struct;
        p_struct = stage.p_struct;
        x_order = stage.x_order;
        
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
        
        collocation = ocl.Collocation(x_struct, z_struct, u_struct, p_struct, x_order, daefh, pathcostsfh, d);
        
        ni = collocation.num_i;
        collocationfun = @(x0,vars,u,h,p) ocl.collocation.equations(collocation, x0, vars, u, h, p);
        
        x = expr(['x','_s',mat2str(k)], nx);
        vi = expr(['vi','_s',mat2str(k)], ni);
        u = expr(['u','_s',mat2str(k)], nu);
        h = expr(['h','_s',mat2str(k)]);
        p = expr(['p','_s',mat2str(k)], np);
        
        [xF, cost_integr, equations] = collocationfun(x, vi, u, h, p);
        integrator_fun = casadi.Function('sys', {x,vi,u,h,p}, {xF, cost_integr, equations});
        
        integratormap = integrator_fun.map(stage.N, 'serial');
        
        nv_stage = ocl.simultaneous.nvars(H_norm, nx, ni, nu, np);
        v_last_stage = v_stage;
        v_stage = expr(['v','_s',mat2str(k)], nv_stage);
        
        gridcostfun = @(k,K,x,p) ocl.model.gridcosts(gridcostsfh, x_struct, p_struct, k, K, x, p);
        gridconstraintfun = @(k,K,x,p) ocl.model.gridconstraints(gridconstraintsfh, x_struct, p_struct, k, K, x, p);
          
        [costs_stage, constraints_stage, ...
         constraints_LB_stage, constraints_UB_stage] = ...
            ocl.simultaneous.equations(H_norm, T, nx, ni, nu, np, ...
                                       gridcostfun, gridconstraintfun, ...
                                       integratormap, v_stage, ...
                                       controls_regularization, controls_regularization_value);
        
        collocationList{k} = collocation;
                                     
        transition_eq = [];
        transition_lb = [];
        transition_ub = [];
        if k >= 2
          x0s = ocl.simultaneous.getFirstState(stageList{k}, collocationList{k}, v_stage);
          xfs = ocl.simultaneous.getLastState(stageList{k-1}, collocationList{k-1}, v_last_stage);
          transition_fun = transitionList{k-1};
          
          tansition_handler = OclConstraint();
          
          x0 = Variable.create(stageList{k}.x_struct, x0s);
          xf = Variable.create(stageList{k-1}.x_struct, xfs);
          
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
      self.collocationList = collocationList;
    end
    
    function igList = getInitialGuess(self)
      stage_list = self.stageList;

      igList = cell(length(stage_list),1);
      for k=1:length(stage_list)
        stage = stage_list{k};
        
        colloc = self.collocationList{k};
        
        N = stage.N;
        x_struct = stage.x_struct;
        z_struct = stage.z_struct;
        u_struct = stage.u_struct;
        p_struct = stage.p_struct;
        
        nx = stage.nx;
        nu = stage.nu;
        np = stage.np;
        H_norm = stage.H_norm;
        T = stage.T;
        
        vi_struct = colloc.vars;
        ni = colloc.num_i;
        
        x_bounds = stage.x_bounds;
        x0_bounds = stage.x0_bounds;
        xF_bounds = stage.xF_bounds;
        z_bounds = stage.z_bounds;
        u_bounds = stage.u_bounds;
        p_bounds = stage.p_bounds;
        
        [x_lb, x_ub] = ocl.model.bounds(x_struct, x_bounds);
        [x0_lb, x0_ub] = ocl.model.bounds(x_struct, x0_bounds);
        [xF_lb, xF_ub] = ocl.model.bounds(x_struct, xF_bounds);
        
        [z_lb, z_ub] = ocl.model.bounds(z_struct, z_bounds);
        [u_lb, u_ub] = ocl.model.bounds(u_struct, u_bounds);
        [p_lb, p_ub] = ocl.model.bounds(p_struct, p_bounds);
        
        varsStruct = ocl.simultaneous.variablesStruct(N, x_struct, vi_struct, u_struct, p_struct);
        
        ig = ocl.simultaneous.getInitialGuess(H_norm, T, nx, ni, nu, np, ...
                                    x0_lb, x0_ub, xF_lb, xF_ub, x_lb, x_ub, ...
                                    z_lb, z_ub, u_lb, u_ub, p_lb, p_ub, ...
                                    vi_struct);
                                  
        igList{k} = Variable.create(varsStruct, ig);
      end
    end
    
    function [sol,times,objective,constraints] = solve(self,v0)
      % solve(initialGuess)
      
      solveTotalTic = tic;
      
      stage_list = self.stageList;
      collocation_list = self.collocationList;
      
      lbv = cell(length(stage_list),1);
      ubv = cell(length(stage_list),1);
      for k=1:length(stage_list)
        
        stage = stage_list{k};
        colloc = collocation_list{k};
        
        nx = stage.nx;
        nu = stage.nu;
        np = stage.np;
        H_norm = stage.H_norm;
        T = stage.T;
        
        x_struct = stage.x_struct;
        z_struct = stage.z_struct;
        u_struct = stage.u_struct;
        p_struct = stage.p_struct;
        
        x_bounds = stage.x_bounds;
        x0_bounds = stage.x0_bounds;
        xF_bounds = stage.xF_bounds;
        z_bounds = stage.z_bounds;
        u_bounds = stage.u_bounds;
        p_bounds = stage.p_bounds;
        
        vi_struct = colloc.vars;
        ni = colloc.num_i;
        
        [x_lb, x_ub] = ocl.model.bounds(x_struct, x_bounds);
        [x0_lb, x0_ub] = ocl.model.bounds(x_struct, x0_bounds);
        [xF_lb, xF_ub] = ocl.model.bounds(x_struct, xF_bounds);
        
        [z_lb, z_ub] = ocl.model.bounds(z_struct, z_bounds);
        [u_lb, u_ub] = ocl.model.bounds(u_struct, u_bounds);
        [p_lb, p_ub] = ocl.model.bounds(p_struct, p_bounds);
        
        [vi_lb, vi_ub] = ocl.collocation.bounds(vi_struct, x_lb, x_ub, z_lb, z_ub);
        
        [lbv_stage,ubv_stage] = ocl.simultaneous.bounds(H_norm, T, nx, ni, nu, np, ...
                                      x_lb, x_ub, x0_lb, x0_ub, xF_lb, xF_ub, ...
                                      vi_lb, vi_ub, u_lb, u_ub, p_lb, p_ub);
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
      
      sol = cell(length(stage_list),1);
      times = cell(length(stage_list),1);
      objective = cell(length(stage_list),1);
      constraints = cell(length(stage_list),1);
      i = 1;
      nlpFunEvalTic = tic;
      for k=1:length(stage_list)
        
        stage = stage_list{k};
        colloc = collocation_list{k};
        
        nx = stage.nx;
        nu = stage.nu;
        np = stage.np;
        H_norm = stage.H_norm;
        N = stage.N;
        
        x_struct = stage.x_struct;
        u_struct = stage.u_struct;
        p_struct = stage.p_struct;
        
        ni = colloc.num_i;
        vi_struct = colloc.vars;

        nv_stage = ocl.simultaneous.nvars(H_norm, nx, ni, nu, np);
        v_struct = ocl.simultaneous.variablesStruct(N, x_struct, vi_struct, u_struct, p_struct);
        t_struct = ocl.simultaneous.timesStruct(stage, colloc);
        
        sol{k} = Variable.create(v_struct, sol_values(i:i+nv_stage-1));
        H = sol{k}.h.value;
        
        t_out = ocl.simultaneous.times(H.', colloc);
        
        times{k} = Variable.create(t_struct, t_out);
        i = i + nv_stage;
        
        objective{k} = 0;
        constraints{k} = 0;
      end
      nlpFunEvalTime = toc(nlpFunEvalTic);
      
      self.timeMeasures.solveTotal      = toc(solveTotalTic);
      self.timeMeasures.solveCasadi     = solveCasadiTime;
      self.timeMeasures.nlpFunEval      = nlpFunEvalTime;
    end
  end
  
end
