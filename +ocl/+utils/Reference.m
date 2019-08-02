classdef Reference < handle
  
  properties
    data
  end
  
  methods 
    function self = Reference(value)
      self.set(value);
    end
    
    function set(self, value)
      self.data = value;
    end
    
    function r = get(self)
      r = self.data;
    end
  end
end