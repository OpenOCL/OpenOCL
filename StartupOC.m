function StartupOC
global testDir
global exportDir

% add current directory to path
addpath(pwd);

% change to main directory (where Startup.m is located)
startupDir  = fileparts(which('StartupOC'));
testDir     = fullfile(startupDir,'..','OcWorkingDir','test');
exportDir   = fullfile(startupDir,'..','OcWorkingDir','export');
[~,~] = mkdir(testDir);
[~,~] = mkdir(exportDir);

% setup directories
addpath(startupDir)
addpath(exportDir)
addpath(fullfile(startupDir,'CasadiLibrary'))
addpath(fullfile(startupDir,'CasadiLibrary','Test'))

addpath(fullfile(startupDir,'Core'))
addpath(fullfile(startupDir,'Core','Test'))
addpath(fullfile(startupDir,'Core','Simultaneous'))
addpath(fullfile(startupDir,'Core','Integrator'))

% addpath('Interfaces')
addpath(fullfile(startupDir,'Example'))

