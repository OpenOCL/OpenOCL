classdef OCPHandler < handle
  %OCPHANDLER 
  
  properties (Access = public)
    
    pathCostsFun
    terminalCostsFun
    boundaryConditionsFun
    pathConstraintsFun
%     leastSquaresCostsFun
    
  end
  
  properties(Access = private)
    ocp    
  end
  
  properties(Access = protected)
    model
  end
  
  methods
    
    function self = OCPHandler(ocp,nlpVars)
      self.ocp = ocp;
      self.model = ocp.getModel();
      
      nx = getStatesSize(self);
      nu = getControlsSize(self);
      nz = getAlgVarsSize(self);
      np = getParametersSize(self);

      self.pathCostsFun = Function(@self.getPathCosts,{[nx 1],[nz 1],[nu 1],[1 1],[np 1]},1);
      self.terminalCostsFun = Function(@self.getTerminalCosts,{[nx 1],[1 1],[np 1]},1);
      self.boundaryConditionsFun = Function(@self.getBoundaryConditions,{[nx 1],[nx 1],[np 1]},3);
      self.pathConstraintsFun = Function(@self.getPathConstraints,{[nx 1],[nz 1],[nu 1],[1 1],[np 1]},3);
      
      
%       states = nlpVars.get('state');
%       controls = nlpVars.get('controls');
%       self.leastSquaresCostsFun = Function(@self.getLeastSquaresCosts,{states,controls},1);
      
    end
 
    function cost = getDiscreteCost(self,nlpVars)
      cost = self.ocp.discreteCost(nlpVars);
    end
    
    function nx = getStatesSize(self)
      nx = prod(self.model.state.size);
    end
    function nu = getControlsSize(self)
      nu = prod(self.model.controls.size);
    end
    function nz = getAlgVarsSize(self)
      nz = prod(self.model.algState.size);
    end
    function np = getParametersSize(self)
      np = prod(self.getParameters.size);
    end
    
    function endTime = getEndTime(self)
      endTime = self.ocp.getEndTime;
    end
    
    function parameters = getParameters(self)
      parameters = self.ocp.getParameters();
    end
      
    function callbackFunction(self,nlpVars,variableValues)
      nlpVars.set(variableValues);
      self.ocp.iterationCallback(nlpVars);
    end

    
  end
  
  methods(Access = protected)
    function [val,lb,ub] = getPathConstraints(self,state,algState,controls,time,params)
      p = self.getParameters;
      p.set(params);
      self.model.state.set(state);
      self.model.algState.set(algState);
      self.model.controls.set(controls);
      constraint = self.ocp.getPathConstraints( self.model.state,...
                                                self.model.algState,...
                                                self.model.controls,time,p);   
      val = constraint.values;
      lb  = constraint.lowerBounds;
      ub  = constraint.upperBounds;
    end
    
    function [val,lb,ub] = getBoundaryConditions(self,initialState,finalState,params)
      p = self.getParameters;
      p.set(params);
      initialStateStruct = self.model.state.copy;
      finalStateStruct = self.model.state.copy;
      initialStateStruct.set(initialState);
      finalStateStruct.set(finalState);
      constraint = self.ocp.getBoundaryConditions(initialStateStruct,finalStateStruct,p);
      val = constraint.values;
      lb  = constraint.lowerBounds;
      ub  = constraint.upperBounds;
    end

    function pathCosts = getPathCosts(self,state,algState,controls,time,params)
      p = self.getParameters;
      p.set(params);
      self.model.state.set(state);
      self.model.algState.set(algState);
      self.model.controls.set(controls);
      
      pathCosts = self.ocp.getPathCosts(self.model.state,...
                                        self.model.algState,...
                                        self.model.controls,time,p);
    end
    
    function terminalCosts = getTerminalCosts(self,state,time,params)
      p = self.getParameters;
      p.set(params);
      self.model.state.set(state);
      terminalCosts = self.ocp.getTerminalCosts(self.model.state,time,p);
    end
    
    function cost = getLeastSquaresCosts(self,stateVars,controlVars)
      N = controlVars.getNumberOfVars;
      costTermList = self.ocp.getLeastSquaresCost();
      cost = 0;
      for k = 1:length(costTermList)
        costTerm = costTermList{k};
        
        if strcmp(costTerm.type,'state')
          % find id in states
          stateTraj = stateVars.get(costTerm.id).value;
          trackingError = stateTraj-costTerm.reference';
          % repeat weighting for whole trajectory
          W = repmat({costTerm.weighting},N+1,1);
          W = sparse(blkdiag(W{:}));
          
        else strcmp(costTerm.type,'controls')
          % find id in controls
          controlsTraj = controlVars.get(costTerm.id).value;
          trackingError = controlsTraj-costTerm.reference';
          % repeat weighting for whole trajectory
          W = repmat({costTerm.weighting},N,1);
          W = sparse(blkdiag(W{:}));
        end
        trackingError = reshape(trackingError,numel(trackingError),1);
        cost = cost + trackingError'* W * trackingError;
      end
      
  end
    
  end
  
end

