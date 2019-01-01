classdef OclConstraint < handle
  %CONSTRAINTS Constraints 
  %   Create, store and access constraints with this class
  
  properties
    values
    lowerBounds
    upperBounds
  end
  
  methods
    
    function self = OclConstraint()
      self.clear();
    end

    function clear(self)
      self.values = [];
      self.lowerBounds = [];
      self.upperBounds = [];
    end
    
    function c = copy(self)
      c = Constraint();
      c.values = self.values.copy;
      c.lowerBounds = self.lowerBounds.copy;
      c.upperBounds = self.upperBounds.copy;
    end
    
    function add(self,varargin)
      % add(self,lhs,op,rhs)
      % add(self,lb,expr,ub)
      % add(self,constraint)
      if nargin==4
        if ischar(varargin{2})
          self.addWithBounds(varargin{1},varargin{2},varargin{3})
        else
          self.addWithOperator(varargin{1},varargin{2},varargin{3})
        end
        
      elseif nargin==2
        self.appendConstraint(varargin{1});
      else
        error('Wrong number of arguments');
      end
      
    end
    
    function addWithBounds(self,lb,expr,ub)
      self.lowerBounds  = [self.lowerBounds;lb];
      self.values       = [self.values;expr];
      self.upperBounds  = [self.upperBounds;ub];
    end
    
    function addWithOperator(self, lhs, op, rhs)
      
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

