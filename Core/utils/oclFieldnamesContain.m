function r = oclFieldnamesContain(names, id)
  idx = find(strcmp([names{:}], id), 1);
  r = ~isempty(idx);
end