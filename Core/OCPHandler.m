classdef OCPHandler < handle
  %OCPHANDLER 
  
  properties (Access = public)
    
    pathCostsFun
    arrivalCostsFun
    boundaryConditionsFun
    pathConstraintsFun
    
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
      
      state = self.model.state.copy;
      stateF = self.model.state.copy;
      controls = self.model.controls.copy;
      algVars = self.model.algVars.copy;
      params = self.getParameters.copy;
      time = nlpVars.get('time');

      self.pathCostsFun = UserFunction(@self.getPathCosts,{state,algVars,controls,time,params},1);
      self.arrivalCostsFun = UserFunction(@self.getArrivalCosts,{state,time,params},1);
      self.boundaryConditionsFun = UserFunction(@self.getBoundaryConditions,{state,stateF,params},3);
      self.pathConstraintsFun = UserFunction(@self.getPathConstraints,{state,algVars,controls,time,params},3);
      
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
      nz = prod(self.model.algVars.size);
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
    function [val,lb,ub] = getPathConstraints(self,state,algVars,controls,time,params)
      constraint = self.ocp.getPathConstraints(state,algVars,controls,time,params);   
      val = constraint.values;
      lb  = constraint.lowerBounds;
      ub  = constraint.upperBounds;
    end
    
    function [val,lb,ub] = getBoundaryConditions(self,initialState,finalState,params)
      constraint = self.ocp.getBoundaryConditions(initialState,finalState,params);
      val = constraint.values;
      lb  = constraint.lowerBounds;
      ub  = constraint.upperBounds;
    end

    function pathCosts = getPathCosts(self,state,algVars,controls,time,params)
      pathCosts = self.ocp.getPathCosts(state,algVars,controls,time,params);
    end
    
    function arrivalCosts = getArrivalCosts(self,state,time,params)
      arrivalCosts = self.ocp.getArrivalCosts(state,time,params);
    end  
    
  end
  
end

