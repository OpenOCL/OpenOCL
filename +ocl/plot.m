function varargout = plot(varargin)
  ocl.checkStartup()
  varargout = cell(nargout,1);
  [varargout{:}] = OclPlot(varargin{:});
end