function testOclSystem
  
oclDir = getenv('OPENOCL_PATH');
addpath(fullfile(oclDir,'Test','Classes'));


s = OclTestSystemEmpty;
assertEqual(s.nx,0);
assertEqual(s.nu,0);
assertEqual(s.np,0);
assertEqual(s.nz,0);
assertEqual(s.systemFun.evaluate([],[],[],[]),[]);

testStr = 's=OclTestSystemMissODE;s.systemFun.evaluate(zeros(s.nx,1),zeros(s.nz,1),zeros(s.nu,1),zeros(s.np,1))';
assertException(testStr,'ode');

testStr = 's=OclTestSystemDoubleODE;s.systemFun.evaluate(zeros(s.nx,1),zeros(s.nz,1),zeros(s.nu,1),zeros(s.np,1))';
assertException(testStr,'ode');

testStr = 's = OclTestSystemWrongODE;s.systemFun.evaluate(zeros(s.nx,1),zeros(s.nz,1),zeros(s.nu,1),zeros(s.np,1))';
assertException(testStr,'exist');

testStr = 's = OclTestSystemMissDAE;s.systemFun.evaluate(zeros(s.nx,1),zeros(s.nz,1),zeros(s.nu,1),zeros(s.np,1))';
assertException(testStr,'algebraic equations');

testStr = 's = OclTestSystemManyDAE;s.systemFun.evaluate(zeros(s.nx,1),zeros(s.nz,1),zeros(s.nu,1),zeros(s.np,1))';
assertException(testStr,'algebraic equations');


rmpath(fullfile(oclDir,'Test','Classes'));
  