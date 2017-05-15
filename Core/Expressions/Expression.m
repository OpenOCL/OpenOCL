classdef Expression < Arithmetic
  %EXPRESSION Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    thisValue
  end
  
  methods

    function self = Expression(v)
      
      if nargin == 1
        self.setValue(v);
      end
      
    end
    
    function v = value(self,sliceOp)
      if nargin==2
        v = self.thisValue(sliceOp{1},sliceOp{2});
      else
        v = self.thisValue;
      end
    end
    
    function setValue(self,v,sliceOp)
      if nargin==3
        self.thisValue(sliceOp{1},sliceOp{2}) = v;
      else
        self.thisValue = v;
      end
    end

  end
  
end

