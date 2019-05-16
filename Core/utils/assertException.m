% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
function assertException(compStr,fh, varargin)
  thrown = false;
  try
    fh(varargin{:});
  catch e
    thrown = true;
    assert(contains(e.message,'oclException'),'Wrong exception raised.Not an oclException!');
    assert(contains(e.message,compStr),'Wrong exception raised.');
  end
  if ~thrown
    error('Exception not raised');
  end
end
 
function r = contains(str1,str2)
  r = ~isempty(strfind(lower(str1),lower(str2)));
end
