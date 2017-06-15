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
    
    function self = OCPHandler(ocp,system,nlpVars)
      self.ocp = ocp;
      self.system = system;
      
      states = self.system.statesStruct;
      controls = self.system.controlsStruct;
      algVars = self.system.algVarsStruct;
      params = self.system.parametersStruct;
      time = MatrixStructure([1,1]);

      self.pathCostsFun = Function(@ocp.getPathCosts,{states,algVars,controls,time,params},1);
      self.arrivalCostsFun = Function(@ocp.getArrivalCosts,{states,time,params},1);
      self.boundaryConditionsFun = Function(@ocp.getBoundaryConditions,{states,states,params},3);
      self.pathConstraintsFun = Function(@ocp.getPathConstraints,{states,algVars,controls,time,params},3);
      
    end
 
    function cost = getDiscreteCost(self,nlpVars)
      cost = self.ocp.discreteCost(nlpVars);
    end

      
    function callbackFunction(self,nlpVars,variableValues)
      nlpVars.set(variableValues);
      self.ocp.iterationCallback(nlpVars);
    end

  end
  
end

