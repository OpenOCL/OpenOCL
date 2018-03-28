classdef MatrixStructure < VarStructure
  %MATRIXSTRUCTURE Matrix valued variables
  %   
  
  properties
  end
  
  methods
    
    function self = MatrixStructure(s)
      self.thisSize = s;
    end
    
    function s = size(self)
      s = self.thisSize;
    end
    
    function r = positions(self)
      r = {1:prod(self.size)};
    end
    
    function r = getChildPointers(~)
      r = struct;
    end
    
  end
  
end

