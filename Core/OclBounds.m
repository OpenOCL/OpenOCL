function b = OclBounds(varargin)
  b = struct;
  b.lower = -inf;
  b.upper = inf;
  
  if nargin >= 1
    b.lower = varargin{1};
    b.upper = varargin{1};
  end
  
  if nargin >= 2
    b.upper = varargin{2};
  end
end

