classdef CasadiVariable < Variable
  
  properties
  end
  
  methods (Static)
    
    function obj = Matrix(sizeIn)
      obj = CasadiVariable(MatrixStructure(sizeIn));
    end
    
  end
  
  methods
    
    function self = CasadiVariable(varStructure,value)
      
      self = self@Variable(varStructure);

      if nargin == 1
        if isa(varStructure,'MatrixStructure')
          value = casadi.SX.sym('v',prod(varStructure.size),1);
        else
          value = casadi.SX.sym(varStructure.id,prod(varStructure.size),1);
        end
      end
      
      if isa(value,'Value')
        self.thisValue = value;
      else
        self.thisValue.set(value);
      end
      
    end
    
    
  end
  

  
end

