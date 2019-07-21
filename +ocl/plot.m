% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
function plot(x,y,varargin)
  ocl.utils.checkStartup()
  
  x = Variable.getValue(x);
  y = Variable.getValue(y);
  
  plot(x,y,'LineWidth', 3, varargin{:})
  
end