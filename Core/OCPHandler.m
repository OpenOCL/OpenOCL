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
    system
  end
  
  methods
    
    function self = OCPHandler(ocp,nlpVars)
      self.ocp = ocp;
      self.system = ocp.getSystem();
      
      states = self.system.states.copy;
      statesF = self.system.states.copy;
      controls = self.system.controls.copy;
      algVars = self.system.algVars.copy;
      params = self.getParameters.copy;
      time = nlpVars.get('time');

      self.pathCostsFun = UserFunction(@self.getPathCosts,{states,algVars,controls,time,params},1);
      self.arrivalCostsFun = UserFunction(@self.getArrivalCosts,{states,time,params},1);
      self.boundaryConditionsFun = UserFunction(@self.getBoundaryConditions,{states,statesF,params},3);
      self.pathConstraintsFun = UserFunction(@self.getPathConstraints,{states,algVars,controls,time,params},3);
      
    end
 
    function cost = getDiscreteCost(self,nlpVars)
      cost = self.ocp.discreteCost(nlpVars);
    end
    
    function nx = getStatesSize(self)
      nx = prod(self.system.states.size);
    end
    function nu = getControlsSize(self)
      nu = prod(self.system.controls.size);
    end
    function nz = getAlgVarsSize(self)
      nz = prod(self.system.algVars.size);
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
    function [val,lb,ub] = getPathConstraints(self,states,algVars,controls,time,params)
      constraint = self.ocp.getPathConstraints(states,algVars,controls,time,params);   
      val = constraint.values;
      lb  = constraint.lowerBounds;
      ub  = constraint.upperBounds;
    end
    
    function [val,lb,ub] = getBoundaryConditions(self,initialStates,finalStates,params)
      constraint = self.ocp.getBoundaryConditions(initialStates,finalStates,params);
      val = constraint.values;
      lb  = constraint.lowerBounds;
      ub  = constraint.upperBounds;
    end

    function pathCosts = getPathCosts(self,states,algVars,controls,time,params)
      pathCosts = self.ocp.getPathCosts(states,algVars,controls,time,params);
    end
    
    function arrivalCosts = getArrivalCosts(self,states,time,params)
      arrivalCosts = self.ocp.getArrivalCosts(states,time,params);
    end  
    
  end
  
end

