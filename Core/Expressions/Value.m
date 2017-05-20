classdef Value < handle
  
  properties
    thisValue
  end
  
  methods

    function self = Value(v)
      if nargin == 1
        self.set(v);
      end
    end
    
    function set(self,val,ind)
      if nargin==3
        self.thisValue(ind,1) = val(:);
      else
        self.thisValue(:,1) = val(:);
      end
    end
    
    function v = value(self,ind)
      if nargin == 2
        v = self.thisValue(ind,1);
      else
        v = self.thisValue(:,1);
      end
    end
  end
end

