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
    fh
  end
  
  methods(Access = public)
    function self = OclOCP(pcH,acH,pconH,bcH,dcH)
      if nargin==1 && (isa(pcH,'OclSystem') || isa(pcH,'System'))
        oclDeprecation('Passing a system to the constructor of OclOCP is deprecated.');
      end
      
      self.fh.pcH   = @(varargin)pathCosts(varargin{:});
      self.fh.acH   = @(varargin)arrivalCosts(varargin{:});
      self.fh.pconH = @(varargin)pathConstraints(varargin{:});
      self.fh.bcH   = @(varargin)boundaryConditions(varargin{:});
      self.fh.dcH   = @(varargin)discreteCosts(varargin{:});
      if nargin>=1
        self.fh.pcH   = pcH;
      end
      if nargin>=2
        self.fh.acH   = acH;
      end
      if nargin>=3
        self.fh.pconH = pconH;
      end
      if nargin>=4
        self.fh.bcH   = bcH;
      end
      if nargin>=5
        self.fh.dcH   = dcH;
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

