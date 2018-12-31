function assertSqueezeEqual(a,b,varargin)
a = squeeze(a);
b = squeeze(b);
assertSetEqual(a,b,varargin{:})
  
end
