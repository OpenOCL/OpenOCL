function setup()

oclPath  = fileparts(which('ocl'));

addpath(fullfile(oclPath, 'Lib', 'casadi'));
rmpath(fullfile(oclPath, 'Lib', 'casadi'));

acados_dir = getenv('ACADOS_INSTALL_DIR');

if isempty(acados_dir)
    ocl.utils.error('Please run the acados_setup.sh script in the main directory of OpenOCL. Close Matlab and run it from the command prompt. Only Linux is supported with the acados interface.'); 
end

% addpath(fullfile(acados_dir, 'external', 'casadi-matlab'))
addpath(fullfile(acados_dir, 'interfaces', 'acados_matlab'))

setenv('ENV_RUN','true')

