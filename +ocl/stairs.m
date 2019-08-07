% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
function stairs(x, y, varargin)
  ocl.utils.checkStartup()
  
  x = ocl.Variable.getValue(x);
  y = ocl.Variable.getValue(y);
  
  stairs(x,y,'LineWidth', 3, varargin{:})
end