classdef Bounds < handle

  properties
    data_p
  end

  methods
    function self = Bounds()
      self.data_p = struct;
    end
    
    function r = data(self)
      d = self.data_p;
      
      names = fieldnames(d);
      r = cell(length(names), 1);
      
      for k=1:length(names)
        id = names{k};
        r{k} = d.(id);
      end
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
      
      self.data_p.(id) = d;
    end
  end
end
