function argumentParser

  % valid tests
  p = ocl.ArgumentParser;
  
  p.addRequired('AA', @isnumeric);
  
  p.addOptional('a', 1, @isnumeric);
  p.addOptional('b', 'z', @isstr);
  
  p.addKeyword('c', 2, @isnumeric);
  p.addKeyword('d', 'y', @isstr);
  
  p.addParameter('e', 3, @(el) isnumeric(el));
  p.addParameter('f', 'x', @(el) ischar(el) || isnumeric(el));
  
  inputs = {100, 10, 'aaa', 11, 'bbb', 'f', 'ddd', 'e', 12};
  results = p.parse(inputs{:});
  assertEqual(results.AA, 100);
  assertEqual(results.a, 10);
  assertEqual(results.b, 'aaa');
  assertEqual(results.c, 11);
  assertEqual(results.d, 'bbb');
  assertEqual(results.e, 12);
  assertEqual(results.f, 'ddd');
  
  inputs = {100, 'c', 4, 'd', 'aaa', 'f', 3, };
  results = p.parse(inputs{:});
  assertEqual(results.AA, 100);
  assertEqual(results.a, 1);
  assertEqual(results.b, 'z');
  assertEqual(results.c, 4);
  assertEqual(results.d, 'aaa');
  assertEqual(results.e, 3);
  assertEqual(results.f, 3);

end