classdef CasadiArithmetic < Arithmetic
  
  properties
  end
  
  methods (Static)
    
    function obj = Matrix(sizeIn)
      obj = CasadiArithmetic(MatrixStructure(sizeIn));
    end
    
  end
  
  methods
    
    function self = CasadiArithmetic(varStructure)
      
      self = self@Arithmetic(varStructure);
      value = casadi.SX.sym('v',prod(varStructure.size),1);
      self.thisValue.set(value);
      
    end
    
  end
end

