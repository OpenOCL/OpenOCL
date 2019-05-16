function varargout = System(varargin)
  ocl.checkStartup()
  varargout = cell(nargout,1);
  [varargout{:}] = OclSystem(varargin{:});
end