classdef CasadiNLPSolver < Solver
  
  properties (Access = private)
    nlp
    options
    initialGuess
    
    casadiSolver
    nlpData
    
    scalingMin
    scalingMax
  end
  
  methods
    
    function self = CasadiNLPSolver(nlp,options)
      
      self.nlp = nlp;
      self.options = options;
      self.construct;
      
    end
    
    function parameters = getParameters(self)
      parameters = self.nlp.getParameters;
    end
    
    
    function [outVars,times,objective,constraints] = solve(self,initialGuess)
      % solve(self,initialGuess)
      
      self.initialGuess = initialGuess;
      
      
      % get bound for decision variables
      lbx = self.nlp.lowerBounds.flat;
      ubx = self.nlp.upperBounds.flat;
      
      vsym = self.nlpData.vsym;
      costs = self.nlpData.costs;
      constraints = self.nlpData.constraint;
      constraints_LB = self.nlpData.constraints_LB;
      constraints_UB = self.nlpData.constraints_UB;
      x0 = initialGuess.flat;
      
      nv = numel(vsym);
      
      % detect variables as parameters if they are constant
      paramIndizes = [];
      psym = {};
      params = [];
      varIndizes = 1:nv;
      if (self.options.nlp.detectParameters)
        
        % find parameters
        paramIndizes = find((lbx-ubx)==0);
        
        % get parameter values
        params = lbx(paramIndizes);
        
        % get indizes of variables (in constrast to parameters)
        varIndizes(paramIndizes) = [];
        
        % select parameters and variables
        psym = vsym(paramIndizes);
        vsym = vsym(varIndizes);
        lbx = lbx(varIndizes);
        ubx = ubx(varIndizes);
        x0 = x0(varIndizes);
      end
      
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
      casadiNLP.x = vertcat(vsym{:});
      casadiNLP.f = costs;
      casadiNLP.g = constraints;
      casadiNLP.p = vertcat(psym{:});
      
      
      
      opts = self.options.nlp.casadi;
      
      if isfield(self.options.nlp,self.options.nlp.solver)
        opts.(self.options.nlp.solver) = self.options.nlp.(self.options.nlp.solver);
      end
      
      if self.options.iterationCallback == true
        callbackFun = IterationCallback('itCbFun', ...
          numel(vsym), numel(constraints), numel(psym), ...
          @(values)self.callBackHandle(values,initialGuess,varIndizes,paramIndizes,params) );
        opts.iteration_callback = callbackFun;
      end
      
      % fix bug with 0x1 vs 0x0 parameter
      if isempty(psym)
        casadiNLP.p = casadi.MX.sym('p',[0,1]);
      end
      
      
      self.casadiSolver = casadi.nlpsol('my_solver', self.options.nlp.solver, casadiNLP, opts);
      
      args = struct;
      % bounds for non-linear constraints function
      args.lbg = constraints_LB;
      args.ubg = constraints_UB;
      args.p = params;
      args.lbx = lbx;
      args.ubx = ubx;
      
      % initial guess
      args.x0 = x0;
      
      % execute solver
      sol = self.casadiSolver.call(args);
      
      if strcmp(self.options.nlp.solver,'ipopt') && strcmp(self.casadiSolver.stats().return_status,'NonIpopt_Exception_Thrown')
        error('Solver was interrupted by user.');
      else
        
        xsol = sol.x.full();
        
        %remove scaling from solution
        if self.options.nlp.scaling
          xsol = self.unscale(xsol,scalingMinVars,scalingMaxVars);
        end
        
        x = initialGuess.flat;
        x(varIndizes) = xsol;
        x(paramIndizes) = params;
        
        [objective,constraints,~,~,times] = self.nlp.nlpFun.evaluate(x);
        objective = full(objective);
        constraints = full(constraints);
        
        initialGuess.set(x);
        outVars = initialGuess;
      end
      
    end
    
  end
  
  methods(Access = private)
    
    function construct(self)
      
      vars = self.nlp.nlpVars;
      %       CasadiLib.setMX(vars);
      %       vsym = vars.flat;
      %       vsym = casadi.MX.sym('vars',self.nlp.getNumberOfVars);
      
      
      % create symbolic casadi variables for all decision variables
      nv = prod(size(vars));
%       vsym = cell(1,nv);
%       for k=1:nv
%         vsym{k} = casadi.MX.sym(['v' num2str(k)],[1 1]);
%       end
%       vsymMat = vertcat(vsym{:});

      vsym = casadi.MX.sym('v',[nv 1]);
      vsymMat = vsym;
      
      
      % apply scaling
      if self.options.nlp.scaling
        
        self.scalingMin = self.nlp.scalingMin.flat;
        self.scalingMax = self.nlp.scalingMax.flat;
        
        % see if scaling information is available for all variables
        % either from bounds or setScaling
        self.nlp.checkScaling;
        
        % do not scale parameters and variables zero range scaling
        zeroRange = [find((self.scalingMax-self.scalingMin)==0)];
        self.scalingMin(zeroRange) = 0;
        self.scalingMax(zeroRange) = 1;
        
        % get unscaled symbolic vars
        vsymMat = self.unscale(vsymMat,self.scalingMin,self.scalingMax);
      end
      
      
      % call nlp function
      casadiNLPFun = self.nlp.nlpFun;
      [costs,constraints,constraints_LB,constraints_UB] = casadiNLPFun.evaluate(vsymMat);
      costs = costs + self.nlp.getDiscreteCost(vsymMat);
      
      
      self.nlpData = struct;
      self.nlpData.vsym = vsym;
      self.nlpData.costs = costs;
      self.nlpData.constraint = constraints;
      self.nlpData.constraints_LB = constraints_LB;
      self.nlpData.constraints_UB = constraints_UB;
      
      
      
    end
    
    function callBackHandle(self,values,vars,varIndizes,paramIndizes,params)
      
      x = vars.flat;
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