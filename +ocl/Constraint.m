% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
classdef Constraint < handle
  %CONSTRAINT ocl.Constraint
  %   Create, store and access constraints with this class
  
  properties
    values
    lowerBounds
    upperBounds
    userdata_p
  end
  
  methods
    
    function self = Constraint(userdata)
      self.values = [];
      self.lowerBounds = [];
      self.upperBounds = [];
      
      self.userdata_p = userdata;
    end
    
    function r = userdata(self)
      r = self.userdata_p;
    end
    
    function setInitialCondition(self,varargin)
      ocl.utils.deprecation('Using of setInitialCondition is deprecated. Just use add instead.');
      self.add(varargin{:});
    end
    
    function addPathConstraint(self,varargin)
      ocl.utils.deprecation('Using of addPathConstraint is deprecated. Just use add instead.');
      self.add(varargin{:});
    end
    
    function addBoundaryCondition(self,varargin)
      ocl.utils.deprecation('Using of addBoundaryCondition is deprecated. Just use add instead.');
      self.add(varargin{:});
    end
    
    function add(self,varargin)
      % add(self,lhs,op,rhs)
      % add(self,lb,expr,ub)
      % add(self,val)
      
      if nargin==4
        if ischar(varargin{2})
          self.addWithOperator(varargin{1},varargin{2},varargin{3})
        else
          self.addWithBounds(varargin{1},varargin{2},varargin{3})
        end
        
      elseif nargin==2
        self.addWithOperator(varargin{1},'==',0);
      else
        error('Wrong number of arguments');
      end
      
    end
    
    function addWithBounds(self,lb,expr,ub)
      
      lb = ocl.Variable.getValueAsColumn(lb);
      expr = ocl.Variable.getValueAsColumn(expr);
      ub = ocl.Variable.getValueAsColumn(ub);
      
      self.lowerBounds  = [self.lowerBounds;lb];
      self.values       = [self.values;expr];
      self.upperBounds  = [self.upperBounds;ub];
    end
    
    function addWithOperator(self, lhs, op, rhs)
      
      lhs = ocl.Variable.getValueAsColumn(lhs);
      rhs = ocl.Variable.getValueAsColumn(rhs);
      
      % Create new constraint entry
      if strcmp(op,'==')
        expr = lhs-rhs;
        bound = zeros(size(expr));
        self.values = [self.values;expr];
        self.lowerBounds = [self.lowerBounds;bound];
        self.upperBounds = [self.upperBounds;bound];
        
      elseif strcmp(op,'<=')
        expr = lhs-rhs;
        lb = -inf*ones(size(expr));
        ub = zeros(size(expr));
        self.values = [self.values;expr];
        self.lowerBounds = [self.lowerBounds;lb];
        self.upperBounds = [self.upperBounds;ub];
      elseif strcmp(op,'>=')
        expr = rhs-lhs;
        lb = -inf*ones(size(expr));
        ub = zeros(size(expr));
        self.values = [self.values;expr];
        self.lowerBounds = [self.lowerBounds;lb];
        self.upperBounds = [self.upperBounds;ub];
      else
        error('Operator not supported.');
      end
    end
    
    function appendConstraint(self, constraint)
      self.values = [self.values;constraint.values];
      self.lowerBounds = [self.lowerBounds;constraint.lowerBounds];
      self.upperBounds = [self.upperBounds;constraint.upperBounds];
    end
    
  end
  
end

