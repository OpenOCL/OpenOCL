function assertSetEqual(A,B)
  if iscell(A);A=cell2mat(A);end
  if iscell(B);B=cell2mat(B);end
  assertEqual(numel(A), numel(B))
  assertEqual(numel(intersect(A,B)), numel(A))
  
  