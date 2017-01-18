classdef OCP < handle
  %OCP Optimal Control Problem formulation
  %   Derive from this class to formulate an optimal control problem by
  %   implementing the abstract methods.
  
  properties(Access = protected)
    model
  end
  
  properties(Access = private)
    thisPathCosts
    thisTerminalCosts
    thisPathConstraints
    thisBoundaryConditions
    thisLeastSquaresCosts
    
    parameters
    endTime
  end
  
  methods(Abstract)
%     leastSquaresCost(self);
    lagrangeTerms(self,state,algState,controls,time,parameters)
    mayerTerms(self,state,time,parameters)
    pathConstraints(self,state,controls,time,parameters)
    boundaryConditions(self,initialState,finalState,parameters)
  end
  
  methods(Access = public)
    function self = OCP(model)
      
      self.endTime = 'free';
      self.model = model;
      
      self.thisPathConstraints = Constraint;
      self.thisBoundaryConditions = Constraint;
      self.thisTerminalCosts = 0;
      self.thisPathCosts = 0;
      self.thisLeastSquaresCosts = {};
      
      self.parameters = model.parameters;
      
    end
    
    function c = discreteCost(self,vars)
      c = 0;
    end
        
    function model = getModel(self)
      model = self.model;
    end
    
    function p = getParameters(self)
      p = self.parameters;
    end

    function pc = getPathConstraints(self,state,algState,controls,time,parameters)
      self.thisPathConstraints.clear;
      self.pathConstraints(state,algState,controls,time,parameters);
      pc = self.thisPathConstraints;
    end
    
    function tc = getBoundaryConditions(self,initialState,finalState,parameters)
      self.thisBoundaryConditions.clear;
      self.boundaryConditions(initialState,finalState,parameters);
      tc = self.thisBoundaryConditions;
    end

    function pc = getPathCosts(self,state,algState,controls,time,parameters)
      self.thisPathCosts = 0;
      self.lagrangeTerms(state,algState,controls,time,parameters);
      pc = self.thisPathCosts;
    end
    
    function tc = getTerminalCosts(self,state,time,parameters)
      self.thisTerminalCosts = 0;
      self.mayerTerms(state,time,parameters);
      tc = self.thisTerminalCosts;
    end
    
    function c = getLeastSquaresCost(self)
      self.thisLeastSquaresCosts = {};
      self.leastSquaresCost;
      c = self.thisLeastSquaresCosts;
    end
    
  end
  

  methods(Access = protected)
   function setEndTime(self,endTime)
      self.endTime = endTime;
    end
    
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
    
    function addMayerTerm(self,expr)
      callers=dbstack(2);
      assert( strcmp(callers(1).name, 'OCP.getTerminalCosts'), ...
              'This method must be called from OCP.mayerTerms().');
            
      self.thisTerminalCosts = self.thisTerminalCosts + expr;
    end
    
    function addLagrangeTerm(self,expr)
      callers=dbstack(2);
      assert( strcmp(callers(1).name, 'OCP.getPathCosts'), ...
              'This method must be called from OCP.lagrangeTerms().');
      self.thisPathCosts = self.thisPathCosts + expr;
    end
    
    function addLeastSquaresStateCost(self,id,reference,weighting)
      callers=dbstack(2);
      assert( strcmp(callers(1).name, 'OCP.getLeastSquaresCost'), ...
              'This method must be called from OCP.leastSquaresCost().');
      
      leastSquaresCostTerm = struct;
      leastSquaresCostTerm.type = 'state';
      leastSquaresCostTerm.id = id;
      leastSquaresCostTerm.reference = reference;
      leastSquaresCostTerm.weighting = weighting;
      self.thisLeastSquaresCosts = [self.thisLeastSquaresCosts,leastSquaresCostTerm];
    end
    
    function addLeastSquaresControlCost(self,id,reference,weighting)
      callers=dbstack(2);
      assert( strcmp(callers(1).name, 'OCP.getLeastSquaresCost'), ...
              'This method must be called from OCP.leastSquaresCost().');
      
      leastSquaresCostTerm = struct;
      leastSquaresCostTerm.type = 'controls';
      leastSquaresCostTerm.id = id;
      leastSquaresCostTerm.reference = reference;
      leastSquaresCostTerm.weighting = weighting;
      self.thisLeastSquaresCosts = [self.thisLeastSquaresCosts,leastSquaresCostTerm];
    end
    
  end
  
end

