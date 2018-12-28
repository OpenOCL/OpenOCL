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
    
    function t = getTimeMeasures(self)
      t = self.timeMeasures;
    end
    
    function parameters = getParameters(self)
      parameters = self.nlp.getParameters;
    end
    
    
    function [outVars,times,objective,constraints] = solve(self,initialGuess)
      % solve(self,initialGuess)
      
      solveTotalTic = tic;
      
      self.initialGuess = initialGuess;
      
      nv = prod(initialGuess.size);
      
      % get bound for decision variables
      lbx = self.nlp.lowerBounds.value;
      ubx = self.nlp.upperBounds.value;
      x0 = initialGuess.value;
      
      
      % detect variables as parameters if they are constant
      paramIndizes = [];
      psym = [];
      params = [];
      varIndizes = 1:nv;
      if (self.options.nlp.detectParameters)
        
        % find parameters
        paramIndizes = find((lbx-ubx)==0);
        
        % get parameter values
        params = lbx(paramIndizes);
        
        % get indizes of variables (in constrast to parameters)
        varIndizes(paramIndizes) = [];
      end
      
      
      % create variables and parameter symbolics
      vars = CasadiVariable(initialGuess.thisStructure,true);
      
      x0 = x0(varIndizes);
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
      
      
      if self.options.nlp.scaling
        scalingMinVars = self.scalingMin(varIndizes);
        scalingMaxVars = self.scalingMax(varIndizes);
        scalingMinParams = self.scalingMin(paramIndizes);
        scalingMaxParams = self.scalingMax(paramIndizes);
        
        x0 = self.scale(x0,scalingMinVars,scalingMaxVars);
        lbx = self.scale(lbx,scalingMinVars,scalingMaxVars);
        ubx = self.scale(ubx,scalingMinVars,scalingMaxVars);
        params = self.scale(params,scalingMinParams,scalingMaxParams);
      end
      
      
      
      % get struct with nlp for casadi
      casadiNLP = struct;
      casadiNLP.x = vars.value;
      casadiNLP.f = costs.value;
      casadiNLP.g = constraints.value;
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
      
      % fix bug with 0x1 vs 0x0 parameter
      if isempty(psym)
        casadiNLP.p = casadi.MX.sym('p',[0,1]);
      end
      
      constructSolverTic = tic;
      self.casadiSolver = casadi.nlpsol('my_solver', self.options.nlp.solver, casadiNLP, opts);
      constructSolverTime = toc(constructSolverTic);
      
      args = struct;
      % bounds for non-linear constraints function
      args.lbg = constraints_LB.value;
      args.ubg = constraints_UB.value;
      args.p = params;
      args.lbx = lbx;
      args.ubx = ubx;
      
      % initial guess
      args.x0 = x0;
      
      % execute solver
      solveCasadiTic = tic;
      sol = self.casadiSolver.call(args);
      solveCasadiTime = toc(solveCasadiTic);
      
      if strcmp(self.options.nlp.solver,'ipopt') && strcmp(self.casadiSolver.stats().return_status,'NonIpopt_Exception_Thrown')
        error('Solver was interrupted by user.');
      else
        
        xsol = sol.x.full();
        
        %remove scaling from solution
        if self.options.nlp.scaling
          xsol = self.unscale(xsol,scalingMinVars,scalingMaxVars);
        end
        
        initialGuess(varIndizes) = xsol;
        initialGuess(paramIndizes) = params;
        
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
    
  end
  
  methods(Access = private)
    
    function construct(self)
      
      constructTotalTic = tic;
      
      % create nlp function
%       casadiNLPFun = CasadiFunction(self.nlp.nlpFun, false, true);
      casadiNLPFun = self.nlp.nlpFun;

      self.nlpData = struct;
      self.nlpData.casadiNLPFun = casadiNLPFun;
      
      self.timeMeasures.constructTotal = toc(constructTotalTic);
    end
    
    function callBackHandle(self,values,vars,varIndizes,paramIndizes,params)
      
      x = vars.value;
      x(varIndizes) = values;
      
      %remove scaling from decision variables
      if self.options.nlp.scaling
        x = self.unscale(x,self.scalingMin,self.scalingMax);
      end
      % replace parameters
      if self.options.nlp.detectParameters
        x(paramIndizes) = params;
      end
      
      %       here will evaluate the cost function and constraints and pass to
      %       callback
      %       casadiNLPFun = self.nlp.nlpFun;
      %       [costs,constraints,constraints_LB,constraints_UB] = casadiNLPFun.evaluate(x);
      
      
      self.nlp.getCallback(vars,x);
      
    end
    
    function xscaled = scale(self,x,xmin,xmax)
      xscaled = (x - xmin) ./ (xmax-xmin);
    end
    
    function x = unscale(self,xscaled,xmin,xmax)
      x = xscaled.*(xmax-xmin)+xmin;
    end
    
  end
  
end
