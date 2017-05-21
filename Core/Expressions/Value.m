classdef Value < handle
  
  properties
    thisValue
  end
  
  methods

    function self = Value(v)
      if nargin == 1
        assert(iscolumn(v))
        self.set(v);
      end
    end
    
    function set(self,val,ind)
      if nargin==3
        self.thisValue(ind) = val;
      else
        self.thisValue = val;
      end
    end
    
    function v = value(self,ind)
      if nargin == 2
        v = self.thisValue(ind);
      else
        v = self.thisValue;
      end
    end
  end
end

