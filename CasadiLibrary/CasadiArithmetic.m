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
      self.thisValue.set(value);
      
    end
    
  end
end

