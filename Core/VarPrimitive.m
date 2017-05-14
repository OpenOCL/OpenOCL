classdef VarPrimitive < Arithmetic

  properties (Access = public)
    
    id
    thisSize
    
    thisSlice
    
  end
  
  methods
    
    function self = VarPrimitive(idIn,sizeIn,valueIn)
      self.id = idIn;
      self.thisSize = sizeIn;
      self.thisSlice = {':',':'};
      
      if nargin == 3
        self.set(valueIn);
      end
    end
    
    function v = copy(self)
      v = VarPrimitive(self.id,self.thisSize);
      v.thisValue = self.thisValue;
    end
    
    function s = size(self)
      s = self.thisSize;
    end
    
    function v = slice(self,sliceOp)
      self.thisSlice = sliceOp;
      v = self;
    end
    
    function v = value(self)
      v = value@Arithmetic(self,self.thisSlice);
    end
    
    function v = flat(self)
      v = reshape(self.value,prod(self.size),1);
    end
    
    function set(self,valueIn)
      self.setValue(valueIn);
    end
    
  end
end

