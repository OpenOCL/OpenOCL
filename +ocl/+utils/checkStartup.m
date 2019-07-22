% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
function checkStartup()
  global ocl_casadi_setup_completed
  if isempty(ocl_casadi_setup_completed) || ~ocl_casadi_setup_completed
    disp('Running OpenOCL setup procedure. This may required your input, and may take a while at the first time.')
    ocl.utils.StartupOCL();
    ocl_casadi_setup_completed = true;
  end
end