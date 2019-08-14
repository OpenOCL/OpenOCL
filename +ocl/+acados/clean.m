function clean()

clear all;

setenv('ACADOS_INSTALL_DIR', '');

ocl_path  = fileparts(which('ocl'));

% clean export
if exist(fullfile(ocl_path,'Workspace','export'), 'dir')
  addpath(fullfile(ocl_path,'Workspace','export'));
  rmpath(fullfile(ocl_path,'Workspace','export'));
  
  success = rmdir(fullfile(ocl_path,'Workspace','export'), 's');
  if ~success
    error('Could not remove export folder. Restart Matlab and run clean again.');
  end
end

% clean acados lib
if exist(fullfile(ocl_path,'Lib','acados'), 'dir')
  addpath(fullfile(ocl_path,'Lib','acados'));
  rmpath(fullfile(ocl_path,'Lib','acados'));

  success = rmdir(fullfile(ocl_path,'Lib','acados'), 's');
  if ~success
    error('Could not remove acados binaries folder. Restart Matlab and run clean again.');
  end
end

