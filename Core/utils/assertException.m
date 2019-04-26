function assertException(compStr,fh, varargin)
  thrown = false;
  try
    fh(varargin{:});
  catch e
    thrown = true;
    assert(contains(e.message,'oclException'),['Wrong exception raised. Not an oclException! ', e.message]);
    assert(contains(e.message,compStr), ['Wrong exception raised.', e.message]);
  end
  if ~thrown
    error('Exception not raised');
  end
end
 
function r = contains(str1,str2)
  r = ~isempty(strfind(lower(str1),lower(str2)));
end
