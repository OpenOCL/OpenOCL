classdef OCP < handle
  %OCP Optimal Control Problem formulation
  %   Derive from this class to formulate an optimal control problem by
  %   implementing the abstract methods.
  
  properties(Access = protected)
    system
  end
  
  properties(Access = private)
    thisPathCosts
    thisArrivalCosts
    thisPathConstraints
    thisBoundaryConditions
    
    parametersStruct
    endTime
  end
  
  properties (Access = public)
    
  end
  
  methods(Access = public)
    function self = OCP(system)
      
      self.endTime = 'free';
      self.system = system;
      
      self.parametersStruct = system.parametersStruct;
      
    end
    
    %%% overridable methods
    function c = discreteCost(~,vars)
      % c = discreteCost(self,vars)
      c = Arithmetic.createExpression(vars,0);
    end
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
        
    function [val,lb,ub] = getPathConstraints(self,states,algVars,controls,time,parameters)
      self.thisPathConstraints = Constraint(states);
      self.pathConstraints(states,algVars,controls,time,parameters);
      val = self.thisPathConstraints.values;
      lb = self.thisPathConstraints.lowerBounds;
      ub = self.thisPathConstraints.upperBounds;
    end
    
    function [val,lb,ub] = getBoundaryConditions(self,initialStates,finalStates,parameters)
      self.thisBoundaryConditions = Constraint(initialStates);
      self.boundaryConditions(initialStates,finalStates,parameters);
      val = self.thisBoundaryConditions.values;
      lb = self.thisBoundaryConditions.lowerBounds;
      ub = self.thisBoundaryConditions.upperBounds;
    end

    function pc = getPathCosts(self,states,algVars,controls,time,endTime,parameters)
      self.thisPathCosts = Arithmetic.createExpression(states,0);
      self.pathCosts(states,algVars,controls,time,endTime,parameters);
      pc = self.thisPathCosts;
    end
    
    function tc = getArrivalCosts(self,states,endTime,parameters)
      self.thisArrivalCosts = Arithmetic.createExpression(states,0);
      self.arrivalCosts(states,endTime,parameters);
      tc = self.thisArrivalCosts;
    end
    
  end

  methods(Access = protected)
    
    function addParameter(self,id,size)
      self.parametersStruct.add(id,size);
    end
    
    function addPathConstraint(self,lhs, op, rhs)
      
      callers=dbstack(2);
      assert( strcmp(callers(1).name, 'OCP.getPathConstraints'), ...
              'This method must be called from OCP.pathConstraints().');
      
      self.thisPathConstraints.add(lhs,op,rhs);
    end
    
    function addBoundaryCondition(self,lhs, op, rhs)
      callers=dbstack(2);
      assert( strcmp(callers(1).name, 'OCP.getBoundaryConditions'), ...
              'This method must be called from OCP.boundaryConditions().');
            
      self.thisBoundaryConditions.add(lhs,op,rhs);
    end
    
    function addArrivalCost(self,expr)
      callers=dbstack(2);
      assert( strcmp(callers(1).name, 'OCP.getArrivalCosts'), ...
              'This method must be called from OCP.mayerTerms().');
            
      self.thisArrivalCosts = self.thisArrivalCosts + expr;
    end
    
    function addPathCost(self,expr)
      callers=dbstack(2);
      assert( strcmp(callers(1).name, 'OCP.getPathCosts'), ...
              'This method must be called from OCP.lagrangeTerms().');
      self.thisPathCosts = self.thisPathCosts + expr;
    end
    
  end
  
end

