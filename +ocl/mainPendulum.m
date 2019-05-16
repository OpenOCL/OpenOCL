function varargout = mainPendulum(varargin)
  ocl.checkStartup()
  varargout = cell(nargout,1);
  [varargout{:}] = mainPendulum(varargin{:});
end