function runTests(testExamples,version,changeMessage)
  % runTests(version,changeMessage)
  % Run all tests with version (e.g. 1.01a) and a message that describes
  % the changes of this test with respect to the previous version.
  % Indicate wether examples or tests were added because than the runtime
  % of test will differ from preious versions.
  
  if nargin < 1
    testExamples  = false;
  end
  if nargin < 2
    version       = 'undefined';   
  end
  if nargin < 3
    changeMessage = 'undefined';   
  end
  
  global testDir
  
  tests{1}.name = 'Arithmetic';   tests{1}.file = 'testArithmetic';
  tests{2}.name = 'Var';          tests{2}.file = 'testVar';
  tests{3}.name = 'VarStructure'; tests{3}.file = 'testVarStructure';
  
  if testExamples
    tests{4}.name = 'Example';      tests{4}.file = 'testExamples';
  end
  
  NTests = length(tests);
 

  close all
  set(0,'DefaultFigureVisible','off');
  
  %% run all tests
  testResults = cell(1,NTests);
  for k=1:NTests
    test = tests{k};
    testResults{k} = runTest(test.name,str2func(test.file));
  end

  %% save results
  fileName = [datestr(now,'yyyy-mm-dd_HHMMSS') '.txt'];
  filePath = fullfile(testDir,fileName);
  resultsFile = fopen(filePath,'w');
  fprintf(resultsFile,'Test on %s\nVersion: %s\nChange message: %s\n\n',datestr(now),version,changeMessage);
  
  for k=1:NTests
    printResults(testResults{k});
  end
  fclose(resultsFile);
  
  set(0,'DefaultFigureVisible','on');
  
  
  function testResult = runTest(testName,scriptHandle)
    testResult = struct;
    testResult.name = testName;
    testResult.passed = true;
    testResult.runtime = 0;
    testResult.exception = '';
    try
      tic;
      scriptHandle();
      testResult.runtime = toc;
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
    else
      outputString = sprintf('%s Tests failed\n',testResult.name);
      fprintf(resultsFile,outputString);fprintf(outputString);
      disp(getReport(testResult.exception))
    end
  end
end




