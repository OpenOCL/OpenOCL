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

      lower = -inf;
      upper = inf;

      if nargin >= 3
        lower = varargin{1};
        upper = varargin{1};
      end
      if nargin >= 4
        upper = varargin{2};
      end

      d = struct;
      d.id = id;
      d.lower = lower;
      d.upper = upper;
      self.data_p{end+1} = d;
    end
  end
end
