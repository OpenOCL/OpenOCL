function assertEqual(a,b,msg)

if nargin == 2
  assert(isequal(a,b))
else
  assert(isequal(a,b),msg)
end
  
end
