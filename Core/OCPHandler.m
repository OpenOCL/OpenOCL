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
      time = OclMatrix([1,1]);
      endTime = OclMatrix([1,1]);

      self.pathCostsFun = Function(ocp,@(ocp,varargin) ocp.getPathCosts(varargin{:}),...
                                   {states,algVars,controls,time,endTime,params},1);
      self.arrivalCostsFun = Function(ocp,@(ocp,varargin) ocp.getArrivalCosts(varargin{:}),...
                                      {states,endTime,params},1);
      self.boundaryConditionsFun = Function(ocp,@(ocp,varargin)ocp.getBoundaryConditions(varargin{:}),...
                                            {states,states,params},3);
      self.pathConstraintsFun = Function(ocp,@(ocp,varargin)ocp.getPathConstraints(varargin{:}),...
                                         {states,algVars,controls,time,params},3);
      
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

