classdef CasadiNLPSolver < Solver
  
  properties (Access = private)
    nlp
    options

    casadiSolver
    args
    paramIndizes
    varIndizes
    
    
    xScaleMin
    xScaleMax
    
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


    function outVars = solve(self,initialGuess)
      % solve(self,initialGuess)
      
      % initial guess
      self.args.x0 = initialGuess.flat;
      
      % scale inital guess
      self.args.x0 = (self.args.x0 - self.xScaleMin) ./ (self.xScaleMax-self.xScaleMin);
      
      % remove parameters form initial guess
      self.args.x0(self.paramIndizes) = [];
      
      
      

      % execute solver
      sol = self.casadiSolver.call(self.args);
      
      
      if strcmp(self.options.nlp.solver,'ipopt') && strcmp(self.casadiSolver.stats().return_status,'NonIpopt_Exception_Thrown')
        error('Solver was interrupted by user.');
      else
        
        xsol = sol.x.full();
        psol = self.args.p;
        
        x = initialGuess.flat;
        x(self.paramIndizes) = psol;
        x(self.varIndizes) = xsol;   
        
        xUnscaled = x.*(self.xScaleMax-self.xScaleMin)+self.xScaleMin;
        
        initialGuess.set(xUnscaled);
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

      scalingMin = self.nlp.scalingMin.flat;
      scalingMax = self.nlp.scalingMax.flat;

      
      nv = prod(size(vars));
      vsym = cell(1,nv);
      for k=1:nv
        vsym{k} = casadi.MX.sym(['v' num2str(k)]);
      end
      vsymMat = vertcat(vsym{:});
      
      
      % setting bounds on decision variables
      lbx = self.nlp.lowerBounds.flat;
      ubx = self.nlp.upperBounds.flat;
      
      % apply scaling
      
      % do not rescale parameters
      eqInd = find((scalingMin-scalingMax)==0);
      scalingMin(eqInd) = 0;
      scalingMax(eqInd) = 1;
      
      vsymMatUnscaled = vsymMat.*(scalingMax-scalingMin)+scalingMin;
      lbxScaled = (lbx - scalingMin) ./ (scalingMax-scalingMin);
      ubxScaled = (ubx - scalingMin) ./ (scalingMax-scalingMin);
      

      % turn nlp function into casadi function and call
      casadiNLPFun = self.nlp.nlpFun;
      [costs,constraints,constraints_LB,constraints_UB] = casadiNLPFun.evaluate(vsymMatUnscaled);
      costs = costs + self.nlp.getDiscreteCost(vsymMatUnscaled);
      
      
      
      % check which bounds on x are equal
      self.paramIndizes = find((lbx-ubx)==0);
      params = lbx(self.paramIndizes);
      
      self.varIndizes = 1:nv;
      self.varIndizes(self.paramIndizes) = [];
      
      psym = vsym(self.paramIndizes);
      vsym(self.paramIndizes) = [];
      lbxScaled(self.paramIndizes) = [];
      ubxScaled(self.paramIndizes) = [];
      
      
      self.xScaleMin = scalingMin;
      self.xScaleMax = scalingMax;
      


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
        initialGuess = self.nlp.getInitialGuess;
        callbackFun = IterationCallback('itCbFun', ...
                                        numel(vsym), numel(constraints), numel(psym), ...
                                        @(values)self.nlp.getCallback(initialGuess,values) );
        opts.iteration_callback = callbackFun;
      end
      
      
      self.casadiSolver = casadi.nlpsol('my_solver', self.options.nlp.solver, casadiNLP, opts);


      self.args = struct;

      % bounds for non-linear constraints function
      self.args.lbg = constraints_LB;
      self.args.ubg = constraints_UB;
      
      self.args.lbx = lbxScaled;
      self.args.ubx = ubxScaled;     
      
      self.args.p = params;

      
      
      
    end
    
  end
  
end