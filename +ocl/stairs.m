function varargout = stairs(varargin)
  ocl.checkStartup()
  varargout = cell(nargout,1);
  [varargout{:}] = OclStairs(varargin{:});
end