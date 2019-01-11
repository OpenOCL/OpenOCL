classdef NLPSolver < handle
% --- 
% name: OclSolver
% position: 3
% type: Function
% description: > 
%   "Creates a solver object that discretizes the given system and 
%   optimal control problem, and calls the underlying optimizer. 
%   Before solving set options, parameters, bounds, and the initial guess:"
% args: 
%   - content: "The system dynamics"
%     name: "system"
%     type: "[OclSystem](#apiocl_system)"
%   - content: "The optimal control problem"
%     name: "ocp"
%     type: "[OclOCP](#apiocl_ocp)"
%   - content: "Options struct, can be created with [OclOptions](#apiocl_options)()"
%     name: "options"
%     type: "struct"
% code_block:
%   title: Example
%   language: m
%   code: |- 
%     opt = OclOptions();
%     opt.nlp.controlIntervals = 30;
%     ocl = OclSolver(VanDerPolSystem,VanDerPolOCP,opt);
%     
%     ocl.setBounds('p', -0.25, inf);
%     ocl.setInitialBounds('p', 0);
%     ocl.setParameter('time', 5, 10);
%     
%     v0 = ocl.getInitialGuess();
%     v0.states.p = -0.2;
%     [v,t] = ocl.solve(v0);
%     
%     % initial guess, solution and times have
%     % the following structure:
%     v.states     % state trajectory
%     v.controls   % control trajectory
%     v.algVars    % algebraic variable trajectory
%     v.integrator % integrator variables
%     t.states     % time points of states
%     t.controls   % time points of controls
%     
%     % plotting of state p trajectory:
%     plot(t.states.value,v.states.p.value)
% returns: 
%   - content: A solver object.
%     type: OclSolver

  properties
    nlp
    timeMeasures

    bounds
    initialBounds
    endBounds
    parameters
  end
  
  methods
    
    function self = NLPSolver()
      self.timeMeasures = struct;
      
      self.initialBounds = struct;
      self.endBounds = struct;
      self.parameters = struct;
    end
    
    function solve(self,varargin)
      % -
      % name: solve
      % desc: Calls the solver and starts doing iterations.
      % args: 
      %   - name: initialGuess
      %     type: [OclVariable](#apiocl_variable)
      %     desc: Provide a good initial guess
      % returns: 
      %   - type: [OclVariable](#apiocl_variable)
      %     desc: The solution of the OCP
      %   - type: [OclVariable](#apiocl_variable)
      %     desc: Time points of the solution
      oclError('Not implemented. Call CasadiNLPSolver instead.');
    end
    
    function r = getInitialGuess(self)
      % -
      % name: getInitialGuess
      % desc: >
      %   Use this method to retrieve a first initial guess that is 
      %   generated from the bounds. You can further modify this 
      %   initial guess to improve the solver performance.
      % args: ~
      % returns: 
      %   - type: [OclVariable](#apiocl_variable)
      %     desc: Structured variable for setting the initial guess
      igTic = tic;
      r = self.nlp.getInitialGuess(varargin{:});
      self.timeMeasures.initialGuess = toc(igTic);
    end
    
    function setParameter(self,id,varargin)
      % setParameter(id,value)
      % setParameter(id,lower,upper)
      self.setBounds(id,varargin{:})
    end
    
    function setBounds(self,id,in3,in4)
      % --setBounds(id,value)
      % --setBounds(id,lower,upper)
      %  - name: "setBounds"
      %    content: "Sets a fixed bound on variable for the whole trajectory."
      %    parameters:
      %      - content: "The variable id"
      %        name: "id"
      %        type: "char"
      %      - content: "The fixed value for the bound"
      %        name: "value"
      %        type: "numeric"
      %  - name: "setBounds"
      %    content: "Sets a bound on variable for the whole trajectory."
      %    parameters:
      %      - content: "The variable id"
      %        name: "id"
      %        type: "char"
      %      - content: "The lower bound"
      %        name: "lower"
      %        type: "numeric"
      %      - content: "The upper bound"
      %        name: "upper"
      %        type: "numeric"
      self.bounds.(id) = struct;
      if nargin==3
        self.bounds.(id).lower = in3;
        self.bounds.(id).upper = in3;
      else
        self.bounds.(id).lower = in3;
        self.bounds.(id).upper = in4;
      end
    end
    
    function setInitialBounds(self,varargin)
      % setInitialBounds(id,value)
      % setInitialBounds(id,lower,upper)
      self.initialBounds.(id) = struct;
      if nargin==3
        self.initialBounds.(id).lower = in3;
        self.initialBounds.(id).upper = in3;
      else
        self.initialBounds.(id).lower = in3;
        self.initialBounds.(id).upper = in4;
      end
    end
    
    function setEndBounds(self,varargin)
      % setEndBounds(id,value)
      % setEndBounds(id,lower,upper)
      self.endBounds.(id) = struct;
      if nargin==3
        self.endBounds.(id).lower = in3;
        self.endBounds.(id).upper = in3;
      else
        self.endBounds.(id).lower = in3;
        self.endBounds.(id).upper = in4;
      end
    end    
    
    function getNlpBounds(self)
      
      boundsStruct = self.nlp.varsStruct.flat();
      
    end
    
    function solutionCallback(self,times,solution)
      self.nlp.system.solutionCallback(times,solution);
    end
    
    
  end
  
end