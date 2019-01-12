function assertSqueezeEqual(a,b,varargin)

if iscell(a)
  a = cell2mat(a);
end

if iscell(b)
  b = cell2mat(b);
end

a = squeeze(a);
b = squeeze(b);

a = a(:);
b = b(:);

assertEqual(a,b,varargin{:})
  
end
