classdef MatrixStructure < VarStructure
  %MATRIXSTRUCTURE Matrix valued variables
  %   
  
  properties
  end
  
  methods
    
    function self = MatrixStructure(s)
      self.thisSize = s;
    end
    
    function s = size(self,varargin)
      if nargin == 2
        if varargin{1} > 2
          s = 1;
        else
          s = self.thisSize(varargin{1});
        end
      else
        s = self.thisSize;
      end
    end
    
    function r = positions(self)
      r = {1:prod(self.size)};
    end
    
    function r = getChildPointers(~)
      r = struct;
    end
    
  end
  
end

