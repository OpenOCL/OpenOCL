classdef OclCost < handle
  properties
    value
  end
  
  methods
    
    function self = OclCost()
      self.value = 0;
    end
    
    function add(self,val)
      % add(self,val)
      self.value = self.value + Variable.getValueAsColumn(val);
    end
  end
end

