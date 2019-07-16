classdef Bounds < handle

  properties
    data_p
  end

  methods
    function self = Bounds()
      self.data_p = {};
    end
    
    function r = data(self)
      r = self.data_p;
    end

    function set(self, id, varargin)

      bv = ocl.types.boundValues(varargin{:});

      d = struct;
      d.id = id;
      d.lower = bv.lower;
      d.upper = bv.upper;
      self.data_p{end+1} = d;
    end
  end
end
