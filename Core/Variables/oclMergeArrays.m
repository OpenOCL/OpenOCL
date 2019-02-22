function aOut = oclMergeArrays(a1,a2)
  % merge(a1,a2)
  % Combine arrays of indizes
  % a2 are relative to a1
  % Returns: absolute a2
  s1 = length(a1);
  s2 = length(a2);

  aOut = cell(1,s1*s2);
  for k=1:s1
   ap1 =  a1{k};
   for l=1:s2
     aOut{l+(k-1)*s2} = ap1(a2{l});
   end
  end
end