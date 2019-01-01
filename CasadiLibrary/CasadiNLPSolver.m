classdef CasadiNLPSolver < Solver
  
  properties (Access = private)
    nlp
    options
    initialGuess
    
    casadiSolver
    nlpData
    
    scalingMin
    scalingMax
    
    timeMeasures = struct;
  end
  
  methods
    
    function self = CasadiNLPSolver(nlp,options)
      
      self.nlp = nlp;
      self.options = options;
      self.construct;
    end
    
    function construct(self)
      
      constructTotalTic = tic;
      
      casadiNLPFun = self.nlp.nlpFun;
      nv = self.nlp.nlpFun.inputSizes{1};
      
      % get bound for decision variables
      lbv = self.nlp.lowerBounds.value;
      ubv = self.nlp.upperBounds.value;
      
      % detect variables as parameters if they are constant
      paramIndizes = [];
      psym = [];
      params = [];
      varIndizes = 1:nv;
      if (self.options.nlp.detectParameters)
        
        % find parameters
        paramIndizes = find((lbv-ubv)==0);
        
        % get parameter values
        params = lbv(paramIndizes);
        
        % get indizes of variables (in constrast to parameters)
        varIndizes(paramIndizes) = [];
      end
      
      
      % create variables and parameter symbolics
      varsStruct = self.nlp.getStructure();
      vars = cell(length(varsStruct),1);
      for k=1:length(varsStruct);
        vars = casadi.MX.sym('v',varsStruct{k}.size)
      end
      vars = vertcat(vars{:});
      
      lbx = lbx(varIndizes);
      ubx = ubx(varIndizes);
      
      % apply scaling
      if self.options.nlp.scaling
        
        self.scalingMin = self.nlp.scalingMin.value;
        self.scalingMax = self.nlp.scalingMax.value;
        
        % see if scaling information is available for all variables
        % either from bounds or setScaling
        self.nlp.checkScaling;
        
        % do not scale parameters and variables zero range scaling
        zeroRange = [find((self.scalingMax-self.scalingMin)==0)];
        self.scalingMin(zeroRange) = 0;
        self.scalingMax(zeroRange) = 1;
        
        % get unscaled symbolic vars
        vars = self.unscale(vars',self.scalingMin,self.scalingMax);
      end
      
      % call nlp function with scaled variables
      [costs,constraints,constraints_LB,constraints_UB] = self.nlpData.casadiNLPFun.evaluate(vars);
      
      % get struct with nlp for casadi
      casadiNLP = struct;
      casadiNLP.x = vars;
      casadiNLP.f = costs;
      casadiNLP.g = constraints;
      casadiNLP.p = psym;
      
      opts = self.options.nlp.casadi;
      
      if isfield(self.options.nlp,self.options.nlp.solver)
        opts.(self.options.nlp.solver) = self.options.nlp.(self.options.nlp.solver);
      end
      
      if self.options.iterationCallback == true
        callbackFun = IterationCallback('itCbFun', ...
          numel(casadiNLP.x), numel(casadiNLP.g), numel(casadiNLP.p), ...
          @(values)self.callBackHandle(values,initialGuess,varIndizes,paramIndizes,params) );
        opts.iteration_callback = callbackFun;
      end


      self.nlpData = struct;
      self.nlpData.casadiNLP = casadiNLP;
      self.nlpData.constraints_LB = constraints_LB;
      self.nlpData.constraints_UB = constraints_UB;
      self.nlpData.parameters = params;
      
      self.timeMeasures.constructTotal = toc(constructTotalTic);
    end
    
    function [outVars,times,objective,constraints] = solve(self,initialGuess)
      % solve(self,initialGuess)
      
      solveTotalTic = tic;
      v0 = initialGuess.value;
      
      if self.options.nlp.scaling
        scalingMinVars = self.scalingMin(varIndizes);
        scalingMaxVars = self.scalingMax(varIndizes);
        scalingMinParams = self.scalingMin(paramIndizes);
        scalingMaxParams = self.scalingMax(paramIndizes);
        
        v0 = self.scale(v0,scalingMinVars,scalingMaxVars);
        lbx = self.scale(lbx,scalingMinVars,scalingMaxVars);
        ubx = self.scale(ubx,scalingMinVars,scalingMaxVars);
        params = self.scale(params,scalingMinParams,scalingMaxParams);
      end
      
      constructSolverTic = tic;
      self.casadiSolver = casadi.nlpsol('my_solver', self.options.nlp.solver,... 
                                        self.nlpData.casadiNLP, opts);
      constructSolverTime = toc(constructSolverTic);
      
      args = struct;
      args.lbg = self.nlpData.constraints_LB;
      args.ubg = self.nlpData.constraints_UB;
      args.p = self.nlpData.parameters;
      args.lbx = lbx;
      args.ubx = ubx;
      args.x0 = v0;
      
      % execute solver
      solveCasadiTic = tic;
      sol = self.casadiSolver.call(args);
      solveCasadiTime = toc(solveCasadiTic);
      
      if strcmp(self.options.nlp.solver,'ipopt') && strcmp(self.casadiSolver.stats().return_status,'NonIpopt_Exception_Thrown')
        error('Solver was interrupted by user.');
      end
      
      solution = sol.x.full();
      
      %remove scaling from solution
      if self.options.nlp.scaling
        solution = self.unscale(solution,scalingMinVars,scalingMaxVars);
      end
      
      initialGuess(varIndizes) = solution;
      initialGuess(paramIndizes) = self.nlpData.parameters;
      
      nlpFunEvalTic = tic;
      if nargout > 1
        [objective,constraints,~,~,times] = self.nlp.nlpFun.evaluate(initialGuess);
      end
      nlpFunEvalTime = toc(nlpFunEvalTic);

      outVars = initialGuess;
      
      self.timeMeasures.solveTotal      = toc(solveTotalTic);
      self.timeMeasures.solveCasadi     = solveCasadiTime;
      self.timeMeasures.constructSolver = constructSolverTime;
      self.timeMeasures.nlpFunEval      = nlpFunEvalTime;
      
    end
    
  end
  
  methods(Access = private)
    
    function callBackHandle(self,values,vars,varIndizes,paramIndizes,params)
      
      v = vars.value;
      v(varIndizes) = values;
      
      %remove scaling from decision variables
      if self.options.nlp.scaling
        v = self.unscale(v,self.scalingMin,self.scalingMax);
      end
      % replace parameters
      if self.options.nlp.detectParameters
        v(paramIndizes) = params;
      end
      
      %       here will evaluate the cost function and constraints and pass to
      %       callback
      %       casadiNLPFun = self.nlp.nlpFun;
      %       [costs,constraints,constraints_LB,constraints_UB] = casadiNLPFun.evaluate(x);
      
      
      self.nlp.getCallback(vars,v);
      
    end
    
    function xscaled = scale(~,x,xmin,xmax)
      xscaled = (x - xmin) ./ (xmax-xmin);
    end
    
    function x = unscale(~,xscaled,xmin,xmax)
      x = xscaled.*(xmax-xmin)+xmin;
    end
    
  end
  
end
