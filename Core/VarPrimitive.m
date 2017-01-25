classdef VarPrimitive < Var

  properties (Access = private)
    value
    lowerBound
    upperBound
    
    % scaling properties
    min
    max
    mean
    variance
  end
  
  methods
    function self = VarPrimitive()
      self=self@Var;
      
      self.value      = [];
      self.lowerBound = [];
      self.upperBound = [];
      
      self.min      = [];
      self.max      = [];
      self.mean     = [];
      self.variance = [];
    end
    
    function out = Var(self)
      out = Var;
      out.id = self.id;
      out.subVars = self.subVars;
      out.thisValue = self.thisValue;
      out.thisSize = self.thisSize;
    
      out.compiled = self.compiled;
      out.isUniform = self.isUniform;
      out.varIds = self.varIds;
    end
    
  end
end

