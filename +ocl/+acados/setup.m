function setup()

ocl.utils.checkStartup;

% check if MinGW compiler is setup
c_compiler = mex.getCompilerConfigurations('C','Selected').ShortName;
ocl.utils.assert(strcmp(c_compiler, 'mingw64') || strcmp(c_compiler, 'gcc'), ...
  'Please setup gcc or MinGW as your c compiler using `mex -setup C`.');

acados_dir = getenv('ACADOS_INSTALL_DIR');

ocl_dir  = fileparts(which('ocl'));

if isempty(acados_dir)
  % download acados
  download_url = 'https://github.com/OpenOCL/ocl-deployment/releases/download/acds_bin_eeb810f/acados-bin-eeb810f.zip';
  downlad_destination = fullfile(ocl_dir, 'Workspace', 'acados-bin.zip');
  websave(downlad_destination, download_url);
  unzip(downlad_destination, fullfile(ocl_dir,'Lib','acados'))
  
  % copy binaries to Workspace/export
  export_dir = fullfile(ocl_dir, 'Workspace', 'export');
  
  acados_dir = '';
end

addpath(fullfile(acados_dir, 'interfaces', 'acados_matlab'));

setenv('ENV_RUN','true')

