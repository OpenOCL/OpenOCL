classdef Expression < Arithmetic
  %EXPRESSION Simple arithemtic expression
  %   
  
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

