classdef Expression < ExpressionBase
  %EXPRESSION Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    thisValue
  end
  
  methods
    
    function self = Expression(treeVar,value)
      self = self@ExpressionBase(treeVar);
      self.set(value);
    end
    
    function c = copy(self)
      c = Expression(self.treeVar,self.value');
    end
    
    function set(self,valueIn,sliceIn)
      
      if isscalar(valueIn)
        valueIn = valueIn * ones(1,prod(self.size));
      end
      
      if nargin == 2
        self.thisValue = valueIn;
      else
        for k=1:length(sliceIn)
          slice = sliceIn{k};
          self.thisValue(sliceIn{k}) = valueIn(slice-slice(1)+1);
        end
      end
      
    end
    
    function v = value(self,sliceIn,varIn)
      
      if nargin == 1
        v = self.thisValue';
      else
        v = [];
        sizeIn = varIn.size;
        for k=1:length(sliceIn)
          val = reshape( self.thisValue(sliceIn{k}) , sizeIn );
          v = [v,val];
        end
      end
      
    end
    
  end
  
end

