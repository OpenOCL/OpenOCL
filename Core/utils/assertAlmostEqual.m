function assertAlmostEqual(a,b,msg,eps)
  
  if nargin<=2
    msg = '';
  end

  if nargin<=3
    eps = 1e-4;
  end
  
  a = a(:);
  b = b(:);
  assert(all(abs(a-b)<=eps), msg);

end