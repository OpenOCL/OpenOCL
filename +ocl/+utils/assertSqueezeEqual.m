% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
function assertSqueezeEqual(a,b,varargin)

if iscell(a)
  a = cell2mat(a);
end

if iscell(b)
  b = cell2mat(b);
end

a = squeeze(a);
b = squeeze(b);

a = a(:);
b = b(:);

ocl.utils.assertEqual(a,b,varargin{:})
  
end
