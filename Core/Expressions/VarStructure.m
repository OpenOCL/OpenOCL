classdef VarStructure < handle
  
  properties
    thisSize
  end
  
  methods (Abstract)
    positions(self)
    size(self)
    getChildPointers(self)
  end
  
  methods
    function get(self,id)
      error('Not Implemented.');
    end
  end
  
end

