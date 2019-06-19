% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
function varargout = Simulator(varargin)
  ocl.utils.checkStartup()
  varargout = cell(nargout,1);
  [varargout{:}] = OclSimulator(varargin{:});
end