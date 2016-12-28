classdef CasadiNLPSolver < Solver
  
  properties (Access = private)
    nlp
    options

    casadiSolver
    args
  end
  
  methods
    
    function self = CasadiNLPSolver(nlp,options)
      
      self.nlp = nlp;
      self.options = options;
      self.construct;
      
    end
    
    function initialGuess = getInitialGuess(self)
      initialGuess = self.nlp.getInitialGuess;
    end
    
    function parameters = getParameters(self)
      parameters = self.nlp.getParameters;
    end

    function outVars = solve(self,initialGuess,varargin)
      % solve(self,initialGuess)
      % solve(self,initialGuess,parameters)
      
      narginchk(2,3);
      if nargin == 3
        self.args.p = varargin{1}.flat;
      end
      
      [lowerBounds,upperBounds] = self.nlp.getBounds;
      
      % initial guess
      self.args.x0 = initialGuess.flat;

      % setting bounds on decision variables
      self.args.lbx = lowerBounds.flat;
      self.args.ubx = upperBounds.flat;
      
      % execute solver
      sol = self.casadiSolver.call(self.args);
      
      initialGuess.set(sol.x.full());
      outVars = initialGuess;
      
    end

  end

  methods(Access = private)
    
    function construct(self)

      nv = self.nlp.getNumberOfVars;
      np = self.nlp.getNumberOfParameters;
      
      vsym = casadi.MX.sym('v',nv,1);
      psym = casadi.MX.sym('p',np,1);
      
%       vars = self.nlp.getVars;
%       CasadiLib.setMX(vars);
%       vsym = vars.flat;
      

      % turn nlp function into casadi function and call
      casadiNLPFun = self.nlp.nlpFun;
      [costs,constraints,constraints_LB,constraints_UB] = casadiNLPFun.evaluate(vsym,psym);

      casadiNLP = struct;
      casadiNLP.x = vsym;
      casadiNLP.f = costs;
      casadiNLP.g = constraints;
      casadiNLP.p = psym;
      
      opts = self.options.nlp.casadi;
      opts.(self.options.nlp.solver) = self.options.nlp.(self.options.nlp.solver);
      
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
      
      
    end
    
  end
  
end