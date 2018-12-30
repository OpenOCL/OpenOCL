classdef Value < handle
  % VALUE Class for storing values
  properties
    val
  end
  methods
    function self = Value(v)
      narginchk(1,1);
      self.val = v;
    end
    function set(self,val,varargin)
      if nargin == 2
        self.val = val;
      else
        self.val(varargin{:}) = val;
      end
    end
    function v = get(self,varargin)
      if nargin == 1
        v = self.val;
      else
        v = self.val(varargin{:});
      end
    end
  end
end

