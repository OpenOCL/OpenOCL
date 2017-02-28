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
    end
    
    function controls = getControlsSeries(self,N)
      controls = Var('controls');
      controls.addRepeated({self.system.controls},N);
    end
    
    function [statesVec,algVarsVec,controlsSeries] = simulate(self,initialState,times,varargin)
      % [statesVec,algVarsVec,controlsVec] = simulate(self,initialState,times,parameters)
      % [statesVec,algVarsVec,controlsVec] = simulate(self,initialState,times,controlsSeries,parameters)
      % [statesVec,algVarsVec,controlsVec] = simulate(self,initialState,times,controlsSeries,parameters,callback)
      
      N = length(times)-1;
      
      if nargin == 4
        parameters      = varargin{1};
        controlsSeries  = Var('controls');
        controlsSeries.addRepeated({self.system.controls},N);
      elseif nargin == 5
        controlsSeries  = varargin{1};
        parameters      = varargin{2};
      elseif nargin == 6
        controlsSeries  = varargin{1};
        parameters      = varargin{2};
        callback        = varargin{3};
      end
      
      
      statesVec = Var('states');
      statesVec.addRepeated({self.system.state},N+1);
      algVarsVec = Var('algVars');
      algVarsVec.addRepeated({self.system.algVars},N);
      
      state = self.getConsistentIntitialCondition(initialState,parameters);
      algVars = self.system.algVars;
      algVars.set(0);
 
      statesVec.get('state',1).set(state.flat);
      
      % setup callback
      if callback
        self.system.simulationCallbackSetup;
      end
      
      for k=1:N
        timestep = times(k+1)-times(k);
        
        if nargin == 4
          controls = self.system.callIterationCallback(state,algVars,parameters);
        elseif nargin == 5 || nargin == 6
          if callback
            self.system.callIterationCallback(state,algVars,parameters);
          end
          controls = controlsSeries.get('controls',k);
        end
        
        [stateVal,algVarsVal] = self.integrator.evaluate(state.flat,algVars.flat,controls.flat,timestep,parameters.flat);
        stateVal = full(stateVal);
        algVarsVal = full(algVarsVal);
        
        statesVec.get('state',k+1).set(stateVal);
        
        if ~isempty(algVarsVal)
          algVarsVec.get('algVars',k).set(algVarsVal);
        end
        controlsSeries.get('controls',k).set(controls.flat);
        
        state.set(stateVal);
        algVars.set(algVarsVal);
      end  
    end
    
    function state = getState(self)
      state = self.system.state.copy;
      state.set(0);
    end
    
    function stateOut = getConsistentIntitialCondition(self,state,parameters)
      
      stateOut = state.copy;
      
      % check initial condition
      ic = self.system.getInitialCondition(state,parameters);
      
      if ~all(ic==0)
        warning('Initial state is not consistent, trying to find a consistent initial condition...');
        stateSym  = state.copy;
        CasadiLib.setSX(stateSym);
        ic = self.system.getInitialCondition(stateSym,parameters);
        
        nlp    = struct('x', stateSym.flat, 'f', 0, 'g', ic);
        solver = casadi.nlpsol('solver', 'ipopt', nlp);
        sol    = solver('x0', state.flat, 'lbx', -inf, 'ubx', inf,'lbg', 0, 'ubg', 0);
        
        consistentState  = full(sol.x);
        stateOut.set(consistentState);
      end
      
    end
    
  end
  
end
