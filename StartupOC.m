function StartupOC
global testDir

% add current directory to path
addpath(pwd);

% change to main directory (where Startup.m is located)
startupDir  = fileparts(which('StartupOC'));
testDir      = fullfile(startupDir,'..','OCTests');
[~,~] = mkdir(testDir);

% setup directories
addpath(startupDir)
addpath(fullfile(startupDir,'CasadiLibrary'))
addpath(fullfile(startupDir,'CasadiLibrary','Test'))

addpath(fullfile(startupDir,'Core'))
addpath(fullfile(startupDir,'Core','Test'))
addpath(fullfile(startupDir,'Core','Simultaneous'))
addpath(fullfile(startupDir,'Core','Experimental'))
addpath(fullfile(startupDir,'Core','Integrator'))

% addpath('Interfaces')
addpath(fullfile(startupDir,'Example'))

