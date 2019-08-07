% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
function assertSetEqual(A,B)
  if iscell(A);A=cell2mat(A);end
  if iscell(B);B=cell2mat(B);end
  ocl.utils.assertEqual(numel(A), numel(B))
  ocl.utils.assertEqual(numel(intersect(A,B)), numel(A))
  
  