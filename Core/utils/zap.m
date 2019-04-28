function r = zap(a,b)
  assert(length(a)==length(b), 'Zipping/zapping failed, first and second input have to have the same length.');
  r = struct;
  r.first = a;
  r.second = b;
end