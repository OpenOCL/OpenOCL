function assertAlmostEqual(a,b,varargin)
  
  eps = 1e-4;
  a = a(:);
  b = b(:);
  assert(all(abs(a-b)<=eps), varargin{:});

end