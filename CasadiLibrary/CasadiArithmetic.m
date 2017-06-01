classdef CasadiArithmetic < Arithmetic
  
  properties
  end
  
  methods (Static)
    
    function obj = Matrix(sizeIn)
      obj = CasadiArithmetic(MatrixStructure(sizeIn));
    end
    
  end
  
  methods
    
    function self = CasadiArithmetic(varStructure,value)
      
      self = self@Arithmetic(varStructure);

      if nargin == 1
        value = casadi.SX.sym('v',prod(varStructure.size),1);
      end
      
      if isa(value,'Value')
        self.thisValue = value;
      else
        self.thisValue.set(value);
      end
      
    end
    
    function y = linspace(d1,d2,n)
      n1 = n-1;
      y = d1 + (0:n1).*(d2 - d1)/n1;
    end
    
    
  end
  

  
end

