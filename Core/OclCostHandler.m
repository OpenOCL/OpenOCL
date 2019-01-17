classdef OclCostHandler < handle
  properties
    value
  end
  
  methods
    
    function self = OclCostHandler()
      self.value = 0;
    end
  
    function addPathCost(self,varargin)
      oclDeprecation('Using of addPathCost is deprecated. Just use ch.add(val) instead.');
      self.add(varargin{:});
    end
    
    function addArrivalCost(self,varargin)
      oclDeprecation('Using of addArrivalCost is deprecated. Just use ch.add(val) instead.');
      self.add(varargin{:});
    end
    
    function add(self,val)
      % add(self,val)
      self.value = self.value + Variable.getValueAsColumn(val);
    end
  end
end

