function varargout = Solver(varargin)
  ocl.checkStartup()
  varargout = cell(nargout,1);
  [varargout{:}] = OclSolver(varargin{:});
end