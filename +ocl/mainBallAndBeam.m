function varargout = mainBallAndBeam(varargin)
  ocl.checkStartup()
  varargout = cell(nargout,1);
  [varargout{:}] = mainBallAndBeam(varargin{:});
end