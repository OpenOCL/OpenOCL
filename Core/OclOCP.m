classdef OclOCP < handle
  %OCLOCP Optimal Control Problem formulation
  %   Derive from this class to formulate an optimal control problem by
  %   implementing the abstract methods.
  
  properties(Access = protected)
  end
  
  properties(Access = private)
    thisPathCosts
    thisArrivalCosts
    thisPathConstraints
    thisBoundaryConditions
    discreteCosts
  end
  
  properties (Access = public)
    
  end
  
  methods(Access = public)
    function self = OclOCP()
    end
    
    %%% overridable methods
    function pathCosts(~,~,~,~,~,~,~)
      % pathCosts(self,states,algVars,controls,time,endTime,parameters);
    end
    function arrivalCosts(~,~,~,~)
      % arrivalCosts(self,states,endTime,parameters)
    end
    function pathConstraints(~,~,~,~,~,~)
      % pathConstraints(self,states,controls,time,parameters)
    end
    function boundaryConditions(~,~,~,~)
      % boundaryConditions(self,initialStates,finalStates,parameters)
    end
    function discreteCosts(~,~)
      % c = discreteCost(self,vars)
    end
        
    function [val,lb,ub] = getPathConstraints(self,states,algVars,controls,time,parameters)
      self.thisPathConstraints = OclConstraint(states);
      self.pathConstraints(states,algVars,controls,time,parameters);
      val = self.thisPathConstraints.values;
      lb = self.thisPathConstraints.lowerBounds;
      ub = self.thisPathConstraints.upperBounds;
    end
    
    function [val,lb,ub] = getBoundaryConditions(self,initialStates,finalStates,parameters)
      self.thisBoundaryConditions = OclConstraint(initialStates);
      self.boundaryConditions(initialStates,finalStates,parameters);
      val = self.thisBoundaryConditions.values;
      lb = self.thisBoundaryConditions.lowerBounds;
      ub = self.thisBoundaryConditions.upperBounds;
    end

    function r = getPathCosts(self,states,algVars,controls,time,endTime,parameters)
      self.thisPathCosts = 0;
      self.pathCosts(states,algVars,controls,time,endTime,parameters);
      r = self.thisPathCosts;
    end
    
    function r = getArrivalCosts(self,states,endTime,parameters)
      self.thisArrivalCosts = 0;
      self.arrivalCosts(states,endTime,parameters);
      r = self.thisArrivalCosts;
    end
    function r = getDiscreteCosts(self,vars)
      self.thisArrivalCosts = 0;
      self.arrivalCosts(vars);
      r = self.thisArrivalCosts;
    end
    
  end

  methods(Access = protected)
    
    function addPathConstraint(self,lhs, op, rhs)
      self.thisPathConstraints.add(lhs,op,rhs);
    end
    
    function addBoundaryCondition(self,lhs, op, rhs)
      self.thisBoundaryConditions.add(lhs,op,rhs);
    end
    
    function addArrivalCost(self,expr)
      self.thisArrivalCosts = self.thisArrivalCosts + expr;
    end
    
    function addPathCost(self,expr)
      self.thisPathCosts = self.thisPathCosts + expr;
    end
    
    function addDiscreteCost(self,expr)
      self.thisPathCosts = self.discreteCosts + expr;
    end
    
  end
  
end

