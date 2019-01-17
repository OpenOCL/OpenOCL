classdef OclOCP < handle
  %OCLOCP Optimal Control Problem formulation
  %   Derive from this class to formulate an optimal control problem by
  %   implementing the abstract methods.

  properties (Access = public)
    thisPathCosts
    thisArrivalCosts
    thisPathConstraints
    thisBoundaryConditions
    thisDiscreteCosts
  end
  
  methods(Access = public)
    function self = OclOCP(~)
      if nargin==1
        oclDeprecation('Passing a system to the constructor of OclOCP is deprecated.');
      end
    end
    
    %%% overridable methods
    function pathCosts(~,~,~,~,~,~,~)
      % pathCosts(self,states,algVars,controls,time,endTime,parameters)
    end
    function arrivalCosts(~,~,~,~)
      % arrivalCosts(self,states,endTime,parameters)
    end
    function pathConstraints(~,~,~,~)
      % pathConstraints(self,states,time,parameters)
    end
    function boundaryConditions(~,~,~,~)
      % boundaryConditions(self,initialStates,finalStates,parameters)
    end
    function discreteCosts(~,~)
      % discreteCost(self,vars)
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
      self.thisArrivalCosts = self.thisArrivalCosts + Variable.getValueAsColumn(expr);
    end
    
    function addPathCost(self,expr)
      self.thisPathCosts = self.thisPathCosts + Variable.getValueAsColumn(expr);
    end
    
    function addDiscreteCost(self,expr)
      self.thisDiscreteCosts = self.thisDiscreteCosts + Variable.getValueAsColumn(expr);
    end
    
  end
  
end

