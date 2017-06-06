classdef Simulator < handle
  
  properties
    integrator
    system
  end
  
  methods (Static)
    function options = getOptions()
      options = struct;
    end
  end
  
  methods
    
    function self = Simulator(system,options)
      self.integrator = CasadiIntegrator(system);
      self.system = system;
      
      self.system.systemFun = CasadiFunction(self.system.systemFun);
    end
    
    function controls = getControlsSeries(self,N)
      controls = Var('controls');
      controls.addRepeated({self.system.controls},N);
    end
    
    function [statesVec,algVarsVec,controlsSeries] = simulate(self,initialStates,times,varargin)
      % [statesVec,algVarsVec,controlsVec] = simulate(self,initialState,times,parameters)
      % [statesVec,algVarsVec,controlsVec] = simulate(self,initialState,times,controlsSeries,parameters)
      % [statesVec,algVarsVec,controlsVec] = simulate(self,initialState,times,controlsSeries,parameters,callback)
      
      N = length(times)-1;
      callback = true;
      
      if nargin == 4
        parameters      = varargin{1};
        controlsSeries  = TreeNode('controls');
        controlsSeries.addRepeated({self.system.controls},N);
      elseif nargin == 5
        controlsSeries  = varargin{1};
        parameters      = varargin{2};
      elseif nargin == 6
        controlsSeries  = varargin{1};
        parameters      = varargin{2};
        callback        = varargin{3};
      end
      
      
      statesVec = TreeNode('states');
      statesVec.addRepeated({self.system.states},N+1);
      algVarsVec = TreeNode('algVars');
      algVarsVec.addRepeated({self.system.algVars},N);
      
      algVars = self.system.algVars.copy;
      algVars.set(0);
      
      if nargin == 4
        controls = self.system.callIterationCallback(initialStates,algVars,parameters);
      elseif nargin == 5 || nargin == 6
        controls = controlsSeries.get('controls',1);
      end
      
      [states,algVars] = self.getConsistentIntitialCondition(initialStates,algVars,controls,parameters);
      
 
      statesVec.get('states',1).set(states.flat);
      
      % setup callback
      if callback
        self.system.simulationCallbackSetup;
      end
      
      for k=1:N
        timestep = times(k+1)-times(k);
        
        if nargin == 4
          controls = self.system.callIterationCallback(states,algVars,parameters);
        elseif nargin == 5 || nargin == 6
          if callback
            self.system.callIterationCallback(states,algVars,parameters);
          end
          controls = controlsSeries.get('controls',k);
        end
        
        [statesVal,algVarsVal] = self.integrator.evaluate(states.flat,algVars.flat,controls.flat,timestep,parameters.flat);
        statesVal = full(statesVal);
        algVarsVal = full(algVarsVal);
        
        statesVec.get('states',k+1).set(statesVal);
        
        if ~isempty(algVarsVal)
          algVarsVec.get('algVars',k).set(algVarsVal);
        end
        controlsSeries.get('controls',k).set(controls.flat);
        
        states.set(statesVal);
        algVars.set(algVarsVal);
      end  
    end
    
    function states = getStates(self)
      states = Arithmetic(self.system.statesStruct,0);
    end
    
    function [statesOut,algVarsOut] = getConsistentIntitialCondition(self,states,algVars,controls,parameters)
      
      varsOut = Var('varsOut');
      varsOut.add(states);
      varsOut.add(algVars);
            
      % check initial condition
      constraints = self.system.getInitialCondition(states,parameters);
      
      % append algebraic equation
      [ode,alg] = self.system.systemFun.evaluate(states.flat,algVars.flat,controls.flat,parameters.flat);
      
      constraints = [constraints;full(alg)];
      
      if ~all(constraints==0)
        warning('Initial state is not consistent, trying to find a consistent initial condition...');
        stateSym  = states.copy;
        CasadiLib.setSX(stateSym);
        algVarsSym  = algVars.copy;
        CasadiLib.setSX(algVarsSym);
        
        constraints = self.system.getInitialCondition(stateSym,parameters);
        [ode,alg] = self.system.systemFun.evaluate(stateSym.flat,algVarsSym.flat,controls.flat,parameters.flat);
        constraints = [constraints;alg];
        
        optVars = [stateSym.flat;algVarsSym.flat];
        x0      = [states.flat;algVars.flat];
        
        statesErr = (stateSym.flat-states.flat);
        cost = statesErr'*statesErr;
        
        nlp    = struct('x', optVars, 'f', cost, 'g', constraints);
        solver = casadi.nlpsol('solver', 'ipopt', nlp);
        sol    = solver('x0', x0, 'lbx', -inf, 'ubx', inf,'lbg', 0, 'ubg', 0);
        
        consistentVars  = full(sol.x);
        varsOut.set(consistentVars);
        
      end
      
      statesOut = varsOut.get('states');
      algVarsOut = varsOut.get('algVars');
      
    end
    
  end
  
end
