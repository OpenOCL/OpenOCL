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
      time = TreeNode('time',[1,1]);

      self.pathCostsFun = Function(@ocp.getPathCosts,{states,algVars,controls,time,params},{Arithmetic.Matrix([])});
      self.arrivalCostsFun = Function(@ocp.getArrivalCosts,{states,time,params},{Arithmetic.Matrix([])});
      self.boundaryConditionsFun = Function(@ocp.getBoundaryConditions,{states,states,params},{Arithmetic.Matrix([]),Arithmetic.Matrix([]),Arithmetic.Matrix([])});
      self.pathConstraintsFun = Function(@ocp.getPathConstraints,{states,algVars,controls,time,params},{Arithmetic.Matrix([]),Arithmetic.Matrix([]),Arithmetic.Matrix([])});
      
    end
 
    function cost = getDiscreteCost(self,nlpVars)
      cost = self.ocp.discreteCost(nlpVars);
    end
    
    function nx = getStatesSize(self)
      nx = prod(self.system.statesStruct.size);
    end
    function nu = getControlsSize(self)
      nu = prod(self.system.controlsStruct.size);
    end
    function nz = getAlgVarsSize(self)
      nz = prod(self.system.algVarsStruct.size);
    end
    function np = getParametersSize(self)
      np = prod(self.system.parametersStruct.size);
    end
    
    function endTime = getEndTime(self)
      endTime = self.ocp.getEndTime;
    end
      
    function callbackFunction(self,nlpVars,variableValues)
      nlpVars.set(variableValues);
      self.ocp.iterationCallback(nlpVars);
    end

  end
  
end

