classdef OCPHandler < handle
  properties (Access = public)
    pathCostsFun
    arrivalCostsFun
    boundaryConditionsFun
    pathConstraintsFun
  end
  
  properties(Access = private)
    ocp    
    system
    nlpVarsStruct
  end

  methods
    
    function self = OCPHandler(ocp,system,nlpVarsStruct)
      self.ocp = ocp;
      self.system = system;
      self.nlpVarsStruct = nlpVarsStruct;
      
      % variable sizes
      sx = system.statesStruct.size();
      sz = system.algVarsStruct.size();
      su = system..controlsStruct.size();
      sp = system..parametersStruct.size();
      st = [1,1];
      sv = nlpVarsStruct.size;

      time = OclMatrix([1,1]);
      endTime = OclMatrix([1,1]);

      fhPC = @(self,varargin) self.getPathCosts(varargin{:});
      self.pathCostsFun = OclFunction(self, fhPC, {sx,sz,su,scalar,st,sp}, 1);
      
      fhAC = @(self,varargin) self.getArrivalCosts(varargin{:});
      self.arrivalCostsFun = OclFunction(self, fhAC, {sx,st,sp}, 1);
      
      fhBC = @(self,varargin)ocp.getBoundaryConditions(varargin{:});
      self.boundaryConditionsFun = OclFunction(self, fhBC, {sx,sx,sp}, 3);
      
      fhPConst = @(ocp,varargin)ocp.getPathConstraints(varargin{:});
      self.pathConstraintsFun = OclFunction(ocp, fhPConst, {sx,sz,su,st,sp}, 3);
      
      fhDC = @(ocp,varargin)ocp.discreteCosts(varargin{:});
      self.discreteCostsFun = OclFunction(ocp, fhDC, {sv}, 3);
      
    end
    
    function r = getPathCosts(self,states,algVars,controls,time,endTime,parameters)
      self.thisPathCosts = 0;
      x = Variable.create(self.system.statesStruct,statesIn);
      z = Variable.create(self.system.algVarsStruct,algVarsIn);
      u = Variable.create(self.system.controlsStruct,controlsIn);
      t = Variable.createMatrix(time);
      tF = Variable.createMatrix(time);
      p = Variable.create(self.system.parametersStruct,parametersIn);
      
      self.pathCosts(x,z,u,t,tF,p);
      r = self.thisPathCosts;
    end
    
    function r = getArrivalCosts(self,states,endTime,parameters)
      self.thisArrivalCosts = 0;
      x = Variable.create(self.system.statesStruct,states);
      tF = Variable.createMatrix(endTime);
      p = Variable.create(self.system.parametersStruct,parameters);
      
      self.arrivalCosts(x,tF,p);
      r = self.thisArrivalCosts;
    end
    
    function [val,lb,ub] = getPathConstraints(self,states,algVars,controls,time,parameters)
      self.thisPathConstraints = OclConstraint(states);
      x = Variable.create(self.system.statesStruct,states);
      z = Variable.create(self.system.algVarsStruct,algVars);
      u = Variable.create(self.system.controlsStruct,controls);
      t = Variable.createMatrix(time);
      p = Variable.create(self.system.parametersStruct,parameters);
      
      self.pathConstraints(x,z,u,t,p);
      val = self.thisPathConstraints.values;
      lb = self.thisPathConstraints.lowerBounds;
      ub = self.thisPathConstraints.upperBounds;
    end
    
    function [val,lb,ub] = getBoundaryConditions(self,initialStates,finalStates,parameters)
      self.thisBoundaryConditions = OclConstraint(initialStates);
      x0 = Variable.create(self.system.statesStruct,initialStates);
      xF = Variable.create(self.system.statesStruct,finalStates);
      p = Variable.create(self.system.parametersStruct,parameters);
      
      self.boundaryConditions(x0,xF,p);
      val = self.thisBoundaryConditions.values;
      lb = self.thisBoundaryConditions.lowerBounds;
      ub = self.thisBoundaryConditions.upperBounds;
    end
    
    function r = getDiscreteCosts(self,vars)
      self.discreteCosts = 0;
      v = Variable.create(self.nlpVarsStruct,vars);
      
      self.discreteCosts(v);
      r = self.discreteCosts;
    end

    function callbackFunction(self,nlpVars,variableValues)
      nlpVars.set(variableValues);
      self.ocp.iterationCallback(nlpVars);
    end

  end
  
end

