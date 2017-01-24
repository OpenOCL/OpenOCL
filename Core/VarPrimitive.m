classdef VarPrimitive < handle

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
      
      self.value      = [];
      self.lowerBound = [];
      self.upperBound = [];
      
      self.min      = [];
      self.max      = [];
      self.mean     = [];
      self.variance = [];
    end
  end
  
end

