function r = workspacePath()

oclPath  = fileparts(which('ocl'));
r = fullfile(oclPath, 'Workspace');