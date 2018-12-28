function assertException(expr)
  thrown = false;
  try
    eval(expr)
  catch e
    thrown = true;
  end
  if ~thrown
    error('Exception not raised');
  end
end
 
    