function r = for_each(arr, fh)

  if iscell(arr)
    r = cellfun(fh, arr, 'UniformOutput', false);
  elseif isnumeric(arr)
    r = arrayfun(fh, arr, 'UniformOutput', false);
  elseif isstruct(arr)
    mod_fh = @(el) fh(el.first,el.second);
    r = arrayfun(mod_fh, arr, 'UniformOutput', false);
  end

end