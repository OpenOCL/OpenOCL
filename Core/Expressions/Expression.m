classdef Expression < Arithmetic
  %EXPRESSION Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
  end
  
  methods
    
    function self = Expression(value)
      
      if nargin == 0
        value = [];
      end
      
      self = self@Arithmetic(MatrixStructure(size(value)),value);
    end
    
  end
  
end

