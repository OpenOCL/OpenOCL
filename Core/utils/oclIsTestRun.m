function r = oclIsTestRun()
  global testRun
  return isempty(testRun) || (testRun==false)
end
