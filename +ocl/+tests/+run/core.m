% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%

function [nFails] = core(testExamples,saveLog,suffix)
  % runTests()
  % runTests(testExamples)
  % runTests(1,1,'computername')
  ocl.utils.checkStartup()
  
  if nargin < 1
    testExamples = false;
  end
  if nargin <=1
    saveLog = false;
    suffix = '';
  else
    suffix = ['_',suffix];
  end
  
  testDir = getenv('OPENOCL_TEST');
  oclDir = getenv('OPENOCL_PATH');
  
  % go to main dir and get current git hash
  cd(oclDir);
  [status,version] = system('git rev-parse HEAD');
  if status~=0
    ocl.utils.info('Could not get git hash, log filename will not include the hash. This is not a problem.')
    version='nogithash';  
  end
  
  if isempty(testDir)
    ocl.utils.error('Test directory not set. Run StartupOCL again.')
  end
  
  ocl.utils.setTestRun(true)
  
  tests{1}.name = 'Variable';         tests{end}.file = 'ocl.tests.variable';
  tests{end+1}.name = 'TreeVariable'; tests{end}.file = 'ocl.tests.treeVariable';
  tests{end+1}.name = 'VarStructure'; tests{end}.file = 'ocl.tests.structure';
  tests{end+1}.name = 'ocl.Model';    tests{end}.file = 'ocl.tests.model';
  tests{end+1}.name = 'ocl.Stage';       tests{end}.file = 'ocl.tests.stage';
  tests{end+1}.name = 'ocl.Integrator';   tests{end}.file = 'ocl.tests.integrator';
  
  if testExamples
    tests{end+1}.name = 'Examples';      tests{end}.file = 'ocl.tests.examples';
    tests{end+1}.name = 'Features';      tests{end}.file = 'ocl.tests.features';
  end
  
  NTests = length(tests);
  
  % turn off figures for testing examples
  if testExamples
    close all
    set(0,'DefaultFigureVisible','off');
  end
  
  %% run all tests
  testResults = cell(1,NTests);
  for k=1:NTests
    test = tests{k};
    testResults{k} = runTest(test.name,str2func(test.file));
  end
  
  nFails = 0;
  for k=1:NTests
    if testResults{k}.passed == false
      nFails = nFails + 1;
    end
  end

  %% save results
  fileName = [datestr(now,'yyyy-mm-dd_HHMMSS'), '_', version(1:7), suffix,  '.txt'];
  filePath = fullfile(testDir,fileName);
  resultsFile = fopen(filePath,'w');
  fprintf(resultsFile,'Test on %s\nVersion: %s\n\n',datestr(now),version);
  
  for k=1:NTests
    printResults(testResults{k});
  end
  
  if nFails >0
    outputString = sprintf('%i Tests failed.\n\n',nFails);
    fprintf(resultsFile,outputString);fprintf(2,outputString);
  else
    outputString = 'All tests passed!\n\n';
    fprintf(resultsFile,outputString);fprintf(outputString);
  end
  
  fclose(resultsFile);
  
  if saveLog
    copyfile(filePath,'Log');
  end
  
  if testExamples
    set(0,'DefaultFigureVisible','on');
  end

  ocl.utils.setTestRun(false);
  
  function testResult = runTest(testName,scriptHandle)
    testResult = struct;
    testResult.name = testName;
    testResult.passed = true;
    testResult.runtime = 0;
    testResult.exception = '';
    try
      testTic = tic;
      testResult.outputs = cell(nargout(scriptHandle),1);
      [testResult.outputs{:}] = scriptHandle();
      testResult.runtime = toc(testTic);
    catch exception
      testResult.passed = false;
      testResult.exception = exception;
    end
  end

  function printResults(testResult)
    if testResult.passed
    	outputString = sprintf('%s Tests passed\n',testResult.name);
      fprintf(resultsFile,outputString);fprintf(outputString);
      outputString = sprintf('It took %.4f seconds.\n\n',testResult.runtime);
      fprintf(resultsFile,outputString);fprintf(outputString);
      
      for i=1:length(testResult.outputs)
        out = testResult.outputs{i};
        names = fieldnames(out);
        sum = 0;
        for j=1:length(names)
          val = out.(names{j});
          sum = sum+val;
          outputString = sprintf('Test %i, %s: %.4f seconds.\n', i, names{j}, val);
          fprintf(resultsFile,outputString);fprintf(outputString);
        end
        outputString = sprintf('Test %i, sum: %.4f seconds.\n\n', i, sum);
        fprintf(resultsFile,outputString);fprintf(outputString);
      end
      
    else
      outputString = sprintf('%s Tests failed\n',testResult.name);
      fprintf(resultsFile,outputString);fprintf(outputString);
      
      if ocl.utils.isOctave()
        disp(getReportOctave(testResult.exception))  %% OCTAVE
      else
        disp(getReport(testResult.exception))  %% MATLAB
      end
    end
  end
end