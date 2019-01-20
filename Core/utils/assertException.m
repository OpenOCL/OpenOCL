function assertException(expr,compStr)
  thrown = false;
  try
    eval(expr)
  catch e
    thrown = true;
    if nargin==2
      assert(contains(e.message,'oclException'),'Not a oclException!');
      assert(contains(e.message,compStr),'Wrong exception raised');
    end
  end
  if ~thrown
    error('Exception not raised');
  end
end
 
function r = contains(str1,str2)
  r = ~isempty(strfind(lower(str1),lower(str2)));
end
