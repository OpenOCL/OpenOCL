classdef OclCost < handle
  properties
    value
    obj
  end
  
  methods
    
    function self = OclCost(obj)
      self.value = 0;
      self.obj = obj;
    end
    
    function add(self,val)
      % add(self,val)
      self.value = self.value + Variable.getValueAsColumn(val);
    end
  end
end

