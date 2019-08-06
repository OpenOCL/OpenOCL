function setup()

ocl.utils.checkStartup;

latest_acados_version = '41d8e7_v4';

% check if MinGW compiler is setup
c_compiler = mex.getCompilerConfigurations('C','Selected').ShortName;
ocl.utils.assert(strcmp(c_compiler, 'mingw64') || strcmp(c_compiler, 'gcc'), ...
  'Please setup gcc (Linux) or MinGW (Windows) as your c compiler using `mex -setup C`.');

acados_dir = getenv('ACADOS_INSTALL_DIR');

ocl_dir  = fileparts(which('ocl'));

if isempty(acados_dir) 
  
  % install acados if not on the system
  if ~acados_installed(ocl_dir, latest_acados_version)
    install_acados(ocl_dir, latest_acados_version)
  end
  
  setenv('ACADOS_INSTALL_DIR', fullfile(ocl_dir,'Lib','acados'));
  acados_dir = fullfile(ocl_dir,'Lib','acados');
end

addpath(fullfile(acados_dir, 'interfaces', 'acados_matlab'));

setenv('ENV_RUN','true')

ocl.utils.info('Acados setup procedure finished. ')

end

function r = acados_installed(ocl_dir, version)
r = exist(fullfile(ocl_dir,'Lib','acados','ACADOS_INSTALLED'), 'file');

if r
  
  fid = fopen(fullfile(ocl_dir,'Lib','acados','ACADOS_INSTALLED'), 'r' );
  installed_version = fscanf(fid, '%s');
  fclose(fid);
  
  if ~strcmp(installed_version, version)
    [~] = input("Deleting old acados version. Press [enter] to proceed.",'s');
    
    acados_dir = fullfile(ocl_dir,'Lib','acados');
    addpath(fullfile(acados_dir, 'interfaces', 'acados_matlab'));
    rmpath(fullfile(acados_dir, 'interfaces', 'acados_matlab'));
    s = rmdir(acados_dir, 's');
    if ~s
      ocl.utils.error(['Could not remove acados. Restart Matlab and try ', ...
        'again or remove the Lib/acados directory manually.']);
    end
    r = false;
  end
end

end

function install_acados(ocl_dir, latest_acados_version)

ocl.utils.info(['We are now downloading binaries of acados for you. ', ...
  'This takes a while! If you ', ...
  'would like to setup an individual acados installation, set the ', ...
  'ACADOS_INSTALL_DIR environment variable. ']);

if ispc
  download_url = 'https://github.com/jkoendev/acados-deployment/releases/download/41d8e7_v4/acados-41d8e7_win.zip';
elseif isunix && ~ismac
  download_url = 'https://github.com/jkoendev/acados-deployment/releases/download/41d8e7_v4/acados-41d8e7_linux.zip';
else
  ocl.utils.error(['Your system is not supported to setup acados automatically. ', ...
    'Please tell us if you want your configuration to be supported. You can also ', ...
    'download and compile acados yourself, and set the ACADOS_INSTALL_DIR ', ...
    'environment variable.']);
end

% download and unzip acados
downlad_destination = fullfile(ocl_dir, 'Workspace', 'acados-download.zip');
ocl.utils.info('Downloading acados (~32MB) ...');
websave(downlad_destination, download_url);
ocl.utils.info('Unpacking acados ...');
unzip(downlad_destination, fullfile(ocl_dir,'Lib','acados'))

% copy binaries to Workspace/export
export_dir = fullfile(ocl_dir, 'Workspace', 'export');
copyfile(fullfile(ocl_dir,'Lib','acados','lib','*'), export_dir);

fid = fopen(fullfile(ocl_dir,'Lib','acados','ACADOS_INSTALLED'), 'wt' );
fprintf(fid,'%s\n', latest_acados_version);
fclose(fid);

end




