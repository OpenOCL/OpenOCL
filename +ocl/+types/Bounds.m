classdef Bounds < handle
  
  properties
    data
  end
  
  methods 
    function self = Bounds()
      self.data = struct;
    end
    
    function set(self, id, varargin)
      
      bv = boundValues(varargin{:});
      
      d = struct;
      d.id = id;
      d.lower = bv.lower;
      d.uppoer = bv.upper;
      self.data{end+1} = d;
    end
  end
  
  
end