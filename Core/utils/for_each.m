function r = for_each(arr, fh)

  if iscell(arr)
    r = cellfun(fh, arr, 'UniformOutput', false);
  else
    r = arrayfun(fh, arr, 'UniformOutput', false);
  end

end