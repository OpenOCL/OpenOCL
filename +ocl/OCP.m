function varargout = OCP(varargin)
  ocl.checkStartup()
  varargout = cell(nargout,1);
  [varargout{:}] = OclOCP(varargin{:});
end