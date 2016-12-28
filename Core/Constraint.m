classdef Constraint < matlab.mixin.Copyable
  %CONSTRAINTS Constraints 
  %   Create, store and access constraints with this class
  
  properties
    
    values
    lowerBounds
    upperBounds
    
  end
  
  methods
    
    function self = Constraint()
      
      self.clear;
      
    end

    function clear(self)
      self.values = [];
      self.lowerBounds = [];
      self.upperBounds = [];
    end
    
    function add(self,varargin)
      % add(lhs,op,rhs)
      if nargin==4
        self.addEntry(varargin{1},varargin{2},varargin{3})
      elseif nargin==2
        self.appendConstraint(varargin{1});
      else
        error('Wrong number of arguments');
      end
      
    end
    
    function addEntry(self, lhs, op, rhs)
      
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
      self.upperBounds = [self.lowerBounds;constraint.upperBounds];
    end
    
  end
  
end

