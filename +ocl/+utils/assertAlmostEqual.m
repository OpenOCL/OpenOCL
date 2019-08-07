% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
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