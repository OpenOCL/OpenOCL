function varargout = mainCartPole(varargin)
  ocl.checkStartup()
  varargout = cell(nargout,1);
  [varargout{:}] = mainCartPole(varargin{:});
end