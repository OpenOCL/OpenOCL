classdef CasadiNLPSolver < Solver
  
  properties (Access = private)
    nlp
    options
    initialGuess

    casadiSolver
    args
    paramIndizes
    varIndizes
    
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
      
      % initial guess
      self.args.x0 = initialGuess.flat;
      
      % scale initial guess
      if self.options.nlp.scaling
        self.args.x0 = self.scale(self.args.x0,self.scalingMin,self.scalingMax);
      end
      
      % remove parameters form initial guess
      if self.options.nlp.detectParameters
        self.args.x0(self.paramIndizes) = [];
      end


      % execute solver
      sol = self.casadiSolver.call(self.args);
      
      
      if strcmp(self.options.nlp.solver,'ipopt') && strcmp(self.casadiSolver.stats().return_status,'NonIpopt_Exception_Thrown')
        error('Solver was interrupted by user.');
      else
        
        xsol = sol.x.full();
        
        x = initialGuess.flat;
        x(self.varIndizes) = xsol;   
        
        %remove scaling from solution
        if self.options.nlp.scaling
          x = self.unscale(x,self.scalingMin,self.scalingMax);
        end
        
        % replace parameters
        if self.options.nlp.detectParameters
          x(self.paramIndizes) = self.args.p;
        end
        
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
      vsym = cell(1,nv);
      for k=1:nv
        vsym{k} = CasadiVar(['v' num2str(k)],[1 1]);
      end
      vsymMat = vertcat(vsym{:});
      
      % get bound for decision variables
      lbx = self.nlp.lowerBounds.flat;
      ubx = self.nlp.upperBounds.flat;
      
      
      % detect variables as parameters if they are constant
      self.paramIndizes = [];
      psym = {};
      params = [];
      self.varIndizes = 1:nv;
      if (self.options.nlp.detectParameters)
        
        % find parameters
        self.paramIndizes = find((lbx-ubx)==0);
        
        % get parameter values
        params = lbx(self.paramIndizes);
        
        % get indizes of variables (in constrast to parameters)
        self.varIndizes(self.paramIndizes) = [];
        
        % select parameters
        psym = vsym(self.paramIndizes);
      end
      
      
      % apply scaling
      if self.options.nlp.scaling
        
        self.scalingMin = self.nlp.scalingMin.flat;
        self.scalingMax = self.nlp.scalingMax.flat;
        
        % see if scaling information is available for all variables
        % either from bounds or setScaling
        self.nlp.checkScaling;
        
        % do not scale parameters and variables zero range scaling
        zeroRange = [self.paramIndizes;find((self.scalingMax-self.scalingMin)==0)];
        self.scalingMin(zeroRange) = 0;
        self.scalingMax(zeroRange) = 1;
        
        % get unscaled symbolic vars
        vsymMat = self.unscale(vsymMat,self.scalingMin,self.scalingMax);
        
        % apply scaling to bounds
        lbx = self.scale(lbx,self.scalingMin,self.scalingMax);
        ubx = self.scale(ubx,self.scalingMin,self.scalingMax);
      end
      

      % call nlp function
      casadiNLPFun = self.nlp.nlpFun;
      [costs,constraints,constraints_LB,constraints_UB] = casadiNLPFun.evaluate(vsymMat);
      costs = costs + self.nlp.getDiscreteCost(vsymMat);
      
      % remove parameters from list of decision variables and bounds
      vsym(self.paramIndizes) = [];
      lbx(self.paramIndizes) = [];
      ubx(self.paramIndizes) = [];
      

      % get struct with nlp for casadi
      casadiNLP = struct;
      casadiNLP.x = vertcat(vsym{:});
      casadiNLP.f = costs;
      casadiNLP.g = constraints;
      casadiNLP.p = vertcat(psym{:});
      
      % fix bug with 0x1 vs 0x0 parameter
      if isempty(psym)
        casadiNLP.p = casadi.MX.sym('p',[0,1]);
      end
      
      opts = self.options.nlp.casadi;
      
      if isfield(self.options.nlp,self.options.nlp.solver)
        opts.(self.options.nlp.solver) = self.options.nlp.(self.options.nlp.solver);
      end
      
      if self.options.iterationCallback == true
        callbackFun = IterationCallback('itCbFun', ...
                                        numel(vsym), numel(constraints), numel(psym), ...
                                        @(values)self.callBackHandle(values) );
        opts.iteration_callback = callbackFun;
      end
      
      
      self.casadiSolver = casadi.nlpsol('my_solver', self.options.nlp.solver, casadiNLP, opts);

      self.args = struct;

      % bounds for non-linear constraints function
      self.args.lbg = constraints_LB;
      self.args.ubg = constraints_UB;
      
      self.args.lbx = lbx;
      self.args.ubx = ubx;     
      
      self.args.p = params;

    end
    
    function callBackHandle(self,values)
      
      x = self.initialGuess.flat;
      x(self.varIndizes) = values; 
      
      %remove scaling from decision variables
      if self.options.nlp.scaling
        x = self.unscale(x,self.scalingMin,self.scalingMax);
      end
      % replace parameters
      if self.options.nlp.detectParameters
        x(self.paramIndizes) = self.args.p;
      end
      
%       here will evaluate the cost function and constraints and pass to
%       callback
%       casadiNLPFun = self.nlp.nlpFun;
%       [costs,constraints,constraints_LB,constraints_UB] = casadiNLPFun.evaluate(x);
      
      
      self.nlp.getCallback(self.initialGuess,x);
      
    end
      
    function xscaled = scale(self,x,xmin,xmax)
      xscaled = (x - xmin) ./ (xmax-xmin);
    end
    
    function x = unscale(self,xscaled,xmin,xmax)
      x = xscaled.*(xmax-xmin)+xmin;
    end
    
  end
  
end