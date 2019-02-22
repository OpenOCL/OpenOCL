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
  
    function addDiscreteCost(self,varargin)
      oclDeprecation('Using of addDiscreteCost is deprecated. Just use ch.add(val) instead.');
      self.add(varargin{:});
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
      self.value = self.value + OclTensor.getValueAsColumn(val);
    end
  end
end

