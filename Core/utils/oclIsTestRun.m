function r = oclIsTestRun()
  global testRun
  r = ~isempty(testRun) && testRun;
end
