function clean
  
setenv('OCL_CASADI_SETUP', 'false');

oclPath  = fileparts(which('ocl'));
addpath(fullfile(oclPath,'Lib','casadi'));
rmpath(fullfile(oclPath,'Lib','casadi'));
success = rmdir(fullfile(oclPath,'Lib','casadi'), 's');
if ~success
  error('Could not remove casadi binaries folder. Restart Matlab and run clean again.');
end

ocl.acados.clean

ocl.utils.startup