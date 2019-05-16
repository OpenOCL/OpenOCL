function StartupOCL(in)
  % StartupOCL(workingDirLocation)
  % StartupOCL(octaveClear)
  %
  % Startup script for OpenOCL
  % Adds required directories to the path. Sets up a folder for the results
  % of tests and a folder for autogenerated code.
  % 
  % inputs:
  %   workingDirLocation - path to location where the working directory 
  %                        should be created.

  oclPath  = fileparts(which('StartupOCL'));

  if isempty(oclPath)
    error('Can not find OpenOCL. Add root directory of OpenOCL to the path.')
  end

  workspaceLocation = fullfile(oclPath, 'Workspace');
  octaveClear = false;

  if nargin == 1 && (islogical(in)||isnumeric(in))
    octaveClear = in;
  elseif nargin == 1 && ischar(in)
    workspaceLocation = in;
  elseif nargin == 1
    oclError('Invalid argument.')
  end

  % add current directory to path
  addpath(pwd);

  % create folders for tests and autogenerated code
  testDir     = fullfile(workspaceLocation,'test');
  exportDir   = fullfile(workspaceLocation,'export');
  [~,~] = mkdir(testDir);
  [~,~] = mkdir(exportDir);

  % set environment variables for directories
  setenv('OPENOCL_PATH', oclPath)
  setenv('OPENOCL_TEST', testDir)
  setenv('OPENOCL_EXPORT', exportDir)
  setenv('OPENOCL_WORK', workspaceLocation)

  % setup directories
  addpath(oclPath)
  addpath(exportDir)
  addpath(fullfile(oclPath,'CasadiLibrary'))

  addpath(fullfile(oclPath,'Core'))
  addpath(fullfile(oclPath,'Core','Integrator'))
  addpath(fullfile(oclPath,'Core','Variables'))
  addpath(fullfile(oclPath,'Core','Variables','Variable'))
  addpath(fullfile(oclPath,'Core','utils'))

  addpath(fullfile(oclPath,'Examples'))
  addpath(fullfile(oclPath,'Examples','01VanDerPol'))
  addpath(fullfile(oclPath,'Examples','02BallAndBeam'))
  addpath(fullfile(oclPath,'Examples','03Pendulum'))
  addpath(fullfile(oclPath,'Examples','04RaceCar'))
  addpath(fullfile(oclPath,'Examples','05CartPole'))
  addpath(fullfile(oclPath,'Test'))

  % check if casadi is working
  casadiFound = checkCasadi();
  if casadiFound
    disp(['You have set-up an individual casadi installation. ', ...
          'We will use it, but we can not guarantee that it is ', ...
          ' comapttible with OpenOCL. In doubt remove all casadi ', ...
          'installations from your path'])
  elseif ~casadiFound && exist(fullfile(oclPath,'Lib'),'dir')
    % try binaries in Lib
    addpath(fullfile(oclPath,'Lib'))
    casadiFound = checkCasadi();
  end
  
  % install casadi into Lib folder 
  if ~casadiFound && ispc && ~verLessThan('matlab','9.0.1')
    % Windows, >Matlab 2016a
    fprintf(2,'\nUser input required! Please read below:\n')
    archive_destination = fullfile(oclPath, 'Workspace','casadi-win.zip');
    url = 'https://github.com/casadi/casadi/releases/download/3.4.5/casadi-windows-matlabR2016a-v3.4.5.zip';
    m=input(['\n', 'Dear User, if you continue, CasADi will be downloaded from \n', url, ' \n', ...
             'and saved to the Workspace folder. The archive will be extracted \n', ...
             'to the Lib folder. This will take a few minutes. \n', ...
             'Do you want to continue, press Y or y [enter] to continue: '],'s');
           
    if ~strcmp(m, 'y') && ~strcmp(m, 'Y')
      oclError('You did not agree to download CasADi. Either run StartupOCL again or set-up CasADi manually.');
    end
    
    if ~exist(archive_destination, 'file')
      websave(archive_destination, url);
    end
    unzip(archive_destination, fullfile(oclPath,'Lib'))
    addpath(fullfile(oclPath,'Lib'));
    
  elseif ~casadiFound && isunix&& ~verLessThan('matlab','9.0.1')
    % Linux, >Matlab 2016a
    fprintf(2,'\nUser input required! Please read below:\n')
    archive_destination = fullfile(oclPath, 'Workspace', 'casadi-linux.tar.gz');
    url = 'https://github.com/casadi/casadi/releases/download/3.4.5/casadi-linux-matlabR2014b-v3.4.5.tar.gz';
    m=input(['\n', 'Dear User, if you continue, CasADi will be downloaded from \n', url, ' \n', ...
             'and saved to the Workspace folder. The archive will be extracted \n', ...
             'to the Lib folder. This will take a few minutes. \n', ...
             'Do you want to continue, press Y or y [enter] to continue: '],'s');
           
    if ~strcmp(m, 'y') && ~strcmp(m, 'Y')
      oclError('You did not agree to download CasADi. Either run StartupOCL again or set-up CasADi manually.');
    end
    
    if ~exist(archive_destination, 'file')
      websave(archive_destination, url);
    end
    untar(archive_destination, fullfile(oclPath,'Lib'));
    addpath(fullfile(oclPath,'Lib'));
  elseif ~casadiFound
    oclError('Sorry could not install CasADi for you. Got to https://web.casadi.org/get/ and setup CasADi.');
  end
  
  casadiFound = checkCasadi();
  if casadiFound
    oclInfo('CasADi is up and running!');
  else
    oclError('Sorry could not install CasADi for you. Got to https://web.casadi.org/get/ and setup CasADi.');
  end
    

  % remove properties function in Variable.m for Octave which gives a
  % parse error
  if isOctave()
    variableDir = fullfile(oclPath,'Core','Variables','Variable');
    %rmpath(variableDir);
    
    vFilePath = fullfile(exportDir, 'Variable','Variable.m');
    if ~exist(vFilePath,'file') || octaveClear
      delete(fullfile(exportDir, 'Variable','V*.m'))
      status = copyfile(variableDir,exportDir);
      assert(status, 'Could not copy Variables folder');
    end
      
    vFileText = fileread(vFilePath);
    searchPattern = 'function n = properties(self)';
    replacePattern = 'function n = ppp(self)';
    pIndex = strfind(vFileText,searchPattern);
    
    if ~isempty(pIndex)
      assert(length(pIndex)==1, ['Found multiple occurences of properties ',...
                                 'function in Variable.m; Please reinstall ',...
                                 'OpenOCL.'])
      newText = strrep(vFileText,searchPattern,replacePattern);
      fid=fopen(vFilePath,'w');
      fwrite(fid, newText);
      fclose(fid);
    end
    addpath(fullfile(exportDir,'Variable'));
  end
  
  % travis-ci  
  
  if isOctave()
    args = argv();
    if length(args)>0 && args{1} == '1'
      nFails = runTests(1);
      if nFails > 0
        exit(nFails);
      end
    end
  end
  
end

function r = checkCasadi()
  r = true;  % found and working.
  try
    casadi.SX.sym('x');
  catch e
    if strcmp(e.identifier,'MATLAB:undefinedVarOrClass') || strcmp(e.identifier,'Octave:undefined-function')
      r = false;  % not found.
    else
      oclError(['Casadi installation in the path found but does not ', ...
                'work properly. Try restarting Matlab. Remove all ', ...
                'casadi installations from you path, OpenOCL will ', ...
                ' then install the correct casadi version for you.']);
    end
  end
end

