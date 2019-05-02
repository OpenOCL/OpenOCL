classdef OclOCP < handle
  %OCLOCP Class for defining Optimal Control Problems

  properties (Access = public)
    lagrangecostsfh
    pathcostsfh
    pathconfh
  end
  
  methods(Access = public)
    function self = OclOCP(varargin)
      % OclOCP(pathCostsFH,arrivalCostsFH,pathConstraintsFH,discreteCostsFH)
      
      emptyfh = @(varargin)[];
      
      p = inputParser;
      p.addOptional('lagrangecostsOpt',[],@oclIsFunHandleOrEmpty);
      p.addOptional('pathcostsOpt',[],@oclIsFunHandleOrEmpty);
      p.addOptional('pathconstraintsOpt',[],@oclIsFunHandleOrEmpty);
      
      p.addParameter('lagrangecosts',emptyfh,@oclIsFunHandle);
      p.addParameter('pathcosts',emptyfh,@oclIsFunHandle);
      p.addParameter('pathconstraints',emptyfh,@oclIsFunHandle);
      p.parse(varargin{:});
      
      lagrangecostsfh = p.Results.lagrangecostsOpt;
      if isempty(lagrangecostsfh)
        lagrangecostsfh = p.Results.lagrangecosts;
      end
      
      pathcostsfh = p.Results.pathcostsOpt;
      if isempty(pathcostsfh)
        pathcostsfh = p.Results.pathcosts;
      end
      
      pathconfh = p.Results.pathconstraintsOpt;
      if isempty(pathconfh)
        pathconfh = p.Results.pathconstraints;
      end

      self.lagrangecostsfh = lagrangecostsfh;
      self.pathcostsfh = pathcostsfh;
      self.pathconfh = pathconfh;
    end
    
    function r = lagrangecostfun(self,x,z,u,p)
      pcHandler = OclCost();
      
      x = Variable.create(self.states,x);
      z = Variable.create(self.algvars,z);
      u = Variable.create(self.controls,u);
      p = Variable.create(self.parameters,p);
      
      self.pathcostfh(pcHandler,x,z,u,p);
      
      r = pcHandler.value;
    end
    
    function r = pathcostsfun(self,k,N,x,p)
      pcHandler = OclCost();
      
      x = Variable.create(self.states,x);
      p = Variable.create(self.parameters,p);
      
      self.pathcostsfh(pcHandler,k,N,x,p);
      
      r = pcHandler.value;
    end
    
    function [val,lb,ub] = pathconfun(self,k,N,x,p)
      pathConstraintHandler = OclConstraint();
      x = Variable.create(self.states,x);
      p = Variable.create(self.parameters,p);
      
      self.pathconfh(pathConstraintHandler,k,N,x,p);
      
      val = pathConstraintHandler.values;
      lb = pathConstraintHandler.lowerBounds;
      ub = pathConstraintHandler.upperBounds;
    end
  end
end

