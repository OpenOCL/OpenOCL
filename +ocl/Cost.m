% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
classdef Cost < handle
  properties
    value
    userdata_p
  end
  
  methods
    
    function self = Cost(userdata)
      self.value = 0;
      self.userdata_p = userdata;
    end
    
    function r = userdata(self)
      r = self.userdata_p;
    end
    
    function add(self,val)
      % add(self,val)
      self.value = self.value + ocl.Variable.getValueAsColumn(val);
    end
  end
end

