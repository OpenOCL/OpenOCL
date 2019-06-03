% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
function checkStartup()
  persistent been_here
  if isempty(been_here) || ~been_here
    disp('Running OpenOCL setup procedure. This may required your input, and may take a while at the first time.')
    StartupOCL
    been_here = true;
  end
end