function varargout = mainRaceCar(varargin)
  ocl.checkStartup()
  varargout = cell(nargout,1);
  [varargout{:}] = mainRaceCar(varargin{:});
end