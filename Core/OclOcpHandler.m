
classdef OclOcpHandler < handle
  properties (Access = public)
    pathCostsFun
    arrivalCostsFun
    boundaryConditionsFun
    pathConstraintsFun
    discreteCostsFun
  end
  
  properties(Access = private)
    ocp    
    system
    nlpVarsStruct
    options
  end

  methods
    
    function self = OclOcpHandler(ocp,system,nlpVarsStruct,options)
      self.ocp = ocp;
      self.system = system;
      self.nlpVarsStruct = nlpVarsStruct;
      self.options = options;
      
      % variable sizes
      sx = system.statesStruct.size();
      sz = system.algVarsStruct.size();
      su = system.controlsStruct.size();
      sp = system.parametersStruct.size();
      st = [1,1];
      sv = nlpVarsStruct.size;

      fhPC = @(self,varargin) self.getPathCosts(varargin{:});
      self.pathCostsFun = OclFunction(self, fhPC, {sx,sz,su,st,st,sp}, 1);
      
      fhAC = @(self,varargin) self.getArrivalCosts(varargin{:});
      self.arrivalCostsFun = OclFunction(self, fhAC, {sx,st,sp}, 1);
      
      fhBC = @(self,varargin)self.getBoundaryConditions(varargin{:});
      self.boundaryConditionsFun = OclFunction(self, fhBC, {sx,sx,sp}, 3);
      
      fhPConst = @(self,varargin)self.getPathConstraints(varargin{:});
      self.pathConstraintsFun = OclFunction(self, fhPConst, {sx,st,sp}, 3);
      
      fhDC = @(self,varargin)self.getDiscreteCosts(varargin{:});
      self.discreteCostsFun = OclFunction(self, fhDC, {sv}, 1);
      
    end
    
    function r = getPathCosts(self,states,algVars,controls,time,endTime,parameters)
      pcHandler = OclCost(self.ocp);
      
      if self.options.controls_regularization
        pcHandler.add(self.options.controls_regularization_value*(controls.'*controls));
      end
      
      x = Variable.create(self.system.statesStruct,states);
      z = Variable.create(self.system.algVarsStruct,algVars);
      u = Variable.create(self.system.controlsStruct,controls);
      p = Variable.create(self.system.parametersStruct,parameters);
      t = Variable.Matrix(endTime);
      
      self.ocp.fh.pcH(pcHandler,x,z,u,time,t,p);
      r = pcHandler.value;
    end
    
    function r = getArrivalCosts(self,states,endTime,parameters)
      acHandler = OclCost(self.ocp);
      x = Variable.create(self.system.statesStruct,states);
      p = Variable.create(self.system.parametersStruct,parameters);
      t = Variable.Matrix(endTime);
      
      self.ocp.fh.acH(acHandler,x,t,p);
      r = acHandler.value;
    end
    
    function [val,lb,ub] = getPathConstraints(self,states,time,parameters)
      pathConstraintHandler = OclConstraint(self.ocp);
      x = Variable.create(self.system.statesStruct,states);
      p = Variable.create(self.system.parametersStruct,parameters);
      t = Variable.Matrix(time);
      
      self.ocp.fh.pconH(pathConstraintHandler,x,t,p);
      val = pathConstraintHandler.values;
      lb = pathConstraintHandler.lowerBounds;
      ub = pathConstraintHandler.upperBounds;
    end
    
    function [val,lb,ub] = getBoundaryConditions(self,initialStates,finalStates,parameters)
      bcHandler = OclConstraint(self.ocp);
      x0 = Variable.create(self.system.statesStruct,initialStates);
      xF = Variable.create(self.system.statesStruct,finalStates);
      p = Variable.create(self.system.parametersStruct,parameters);
      
      self.ocp.fh.bcH(bcHandler,x0,xF,p);
      val = bcHandler.values;
      lb = bcHandler.lowerBounds;
      ub = bcHandler.upperBounds;
    end
    
    function r = getDiscreteCosts(self,varsValue)
      dcHandler = OclCost(self.ocp);
      v = Variable.create(self.nlpVarsStruct,varsValue);
      self.ocp.fh.dcH(dcHandler,v);
      r = dcHandler.value;
    end

  end
end

