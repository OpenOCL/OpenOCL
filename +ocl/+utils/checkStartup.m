% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
function checkStartup()
  OCL_CASADI_SETUP = getenv('OCL_CASADI_SETUP');
  
  if strcmp(OCL_CASADI_SETUP, 'true')
    ocl_casadi_setup_completed = true;
  else
    ocl_casadi_setup_completed = false;
  end
  
  if isempty(ocl_casadi_setup_completed) || ~ocl_casadi_setup_completed
    disp('Running OpenOCL setup procedure. This may required your input, and may take a while at the first time.')
    ocl.utils.startup();
    setenv('OCL_CASADI_SETUP', 'true');
  end
end