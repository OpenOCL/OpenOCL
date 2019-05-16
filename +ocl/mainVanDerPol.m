function varargout = mainVanDerPol(varargin)
  ocl.checkStartup()
  varargout = cell(nargout,1);
  [varargout{:}] = mainVanDerPol(varargin{:});
end