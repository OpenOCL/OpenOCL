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
    
    parameters
    endTime
  end
  
  methods(Abstract)
    pathCosts(self,state,algVar,controls,time,parameters)
    arrivalCosts(self,state,time,parameters)
    pathConstraints(self,state,controls,time,parameters)
    boundaryConditions(self,initialState,finalState,parameters)
  end
  
  methods(Access = public)
    function self = OCP(system)
      
      self.endTime = 'free';
      self.system = system;
      
      self.thisPathConstraints = Constraint;
      self.thisBoundaryConditions = Constraint;
      self.thisArrivalCosts = Var(0,'pathCost');
      self.thisPathCosts = Var(0,'pathCost');
      
      self.parameters = system.parameters;
      
    end
    
    function c = discreteCost(self,vars)
      c = 0;
    end
        
    function system = getSystem(self)
      system = self.system;
    end
    
    function p = getParameters(self)
      p = self.parameters;
    end

    function pc = getPathConstraints(self,state,algVars,controls,time,parameters)
      self.thisPathConstraints.clear;
      self.pathConstraints(state,algVars,controls,time,parameters);
      pc = self.thisPathConstraints;
    end
    
    function tc = getBoundaryConditions(self,initialState,finalState,parameters)
      self.thisBoundaryConditions.clear;
      self.boundaryConditions(initialState,finalState,parameters);
      tc = self.thisBoundaryConditions;
    end

    function pc = getPathCosts(self,state,algVars,controls,time,parameters)
      self.thisPathCosts = Var(0,'pathCost');
      self.pathCosts(state,algVars,controls,time,parameters);
      pc = self.thisPathCosts;
    end
    
    function tc = getArrivalCosts(self,state,time,parameters)
      self.thisArrivalCosts = Var(0,'arrivalCost');
      self.arrivalCosts(state,time,parameters);
      tc = self.thisArrivalCosts;
    end
    
  end

  methods(Access = protected)
    
    function addParameter(self,id,size)
      self.parameters.add(id,size);
    end
    
    function parameter = getParameter(self,id)
      parameter = self.parameters.get(id);
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

