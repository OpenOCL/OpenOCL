function assertSetEqual(A,B)
  A = cell2mat(A);
  B = cell2mat(B);
  assert(length(A)==length(B))
  assert(length(intersect(A,B))==length(A))
  
  