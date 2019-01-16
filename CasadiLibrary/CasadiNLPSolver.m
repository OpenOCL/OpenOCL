classdef CasadiNLPSolver < NLPSolver
  
  properties (Access = private)
    nlpData
    options
  end
  
  methods
    
    function self = CasadiNLPSolver(nlp,options)
      
      self.nlpData = self.construct(nlp,options);
      
      self.nlp = nlp;
      self.options = options;
    end
    
    function nlpData = construct(self,nlp,options)
      
      constructTotalTic = tic;
      
      % create variables as casadi symbolics
      vStruct = nlp.varsStruct.flat.children;
      vars = cell(nlp.nv,1);
      names = fieldnames(vStruct);
      for i=1:length(names)
        id = names{i};
        el = vStruct.(id);
        for j=1:size(el.positions,3)
          name = [id,'_',num2str(j)];
          pos = el.positions(:,:,j);
          var = casadi.MX.sym(name,numel(pos));
          vars{pos(1)}=var;
        end
      end
      vars = vertcat(vars{:});

      % call nlp function
      [costs,constraints,constraints_LB,constraints_UB,~] = nlp.nlpFun.evaluate(vars);
      
      % get struct with nlp for casadi
      casadiNLP = struct;
      casadiNLP.x = vars;
      casadiNLP.f = costs;
      casadiNLP.g = constraints;
      casadiNLP.p = casadi.MX.sym('p',[0,1]);

      nlpData = struct;
      nlpData.casadiNLP = casadiNLP;
      nlpData.constraints_LB = constraints_LB;
      nlpData.constraints_UB = constraints_UB;
      self.timeMeasures.constructTotal = toc(constructTotalTic);
    end
    
    function [outVars,times,objective,constraints] = solve(self,initialGuess)
      % solve(initialGuess)
      
      solveTotalTic = tic;
      
      % interpolate initial guess
      self.nlp.interpolateGuess(initialGuess);
      v0 = initialGuess.value;
      
      % detect variables as parameters if they are constant (lb==ub)
      nv = self.nlp.nlpFun.inputSizes{1};
      [lbv,ubv] = self.getNlpBounds();
 
      opts = self.options.nlp.casadi;
      if isfield(self.options.nlp,self.options.nlp.solver)
        opts.(self.options.nlp.solver) = self.options.nlp.(self.options.nlp.solver);
      end
      
      constructSolverTic = tic;
      casadiSolver = casadi.nlpsol('my_solver', self.options.nlp.solver,... 
                                   self.nlpData.casadiNLP, opts);
      constructSolverTime = toc(constructSolverTic);
      
      args = struct;
      args.lbg = self.nlpData.constraints_LB;
      args.ubg = self.nlpData.constraints_UB;
      args.p = [];
      args.lbx = lbv;
      args.ubx = ubv;
      args.x0 = v0;
      
      % execute solver
      solveCasadiTic = tic;
      sol = casadiSolver.call(args);
      solveCasadiTime = toc(solveCasadiTic);
      
      if strcmp(self.options.nlp.solver,'ipopt') && strcmp(casadiSolver.stats().return_status,'NonIpopt_Exception_Thrown')
        error('Solver was interrupted by user.');
      end
      
      solution = sol.x.full();
      
      nlpFunEvalTic = tic;
      if nargout > 1
        [objective,constraints,~,~,times] = self.nlp.nlpFun.evaluate(solution);
      end
      nlpFunEvalTime = toc(nlpFunEvalTic);
      
      times = Variable.createNumeric(self.nlp.timesStruct,times);

      initialGuess.set(solution);
      outVars = initialGuess;
      
      self.timeMeasures.solveTotal      = toc(solveTotalTic);
      self.timeMeasures.solveCasadi     = solveCasadiTime;
      self.timeMeasures.constructSolver = constructSolverTime;
      self.timeMeasures.nlpFunEval      = nlpFunEvalTime;
    end
  end
  
end
