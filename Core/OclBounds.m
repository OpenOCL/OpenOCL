function b = OclBounds(id, varargin)
  b = struct;
  b.id = id;
  b.lower = -inf;
  b.upper = inf;
  
  if nargin >= 2
    b.lower = varargin{1};
    b.upper = varargin{1};
  end
  
  if nargin >= 3
    b.upper = varargin{2};
  end
end

