function assertAlmostEqual(a,b,eps,varargin)
  
  if nargin<=2
    eps = 1e-4;
  end
  
  a = a(:);
  b = b(:);
  assert(all(abs(a-b)<=eps), varargin{:});

end