function testOclSystem
  
oclDir = getenv('OPENOCL_PATH');
addpath(fullfile(oclDir,'Test','Classes'));


s = OclTestSystemEmpty;
s.setup();
assertEqual(s.nx,0);
assertEqual(s.nu,0);
assertEqual(s.np,0);
assertEqual(s.nz,0);
assertEqual(s.systemFun.evaluate([],[],[],[]),[]);

s = OclTestSystemValid;
s.setup();
assertEqual(s.nx,31);
assertEqual(s.nu,31);
assertEqual(s.np,31);
assertEqual(s.nz,31);
[dx,alg] = s.systemFun.evaluate(ones(s.nx,1),ones(s.nz,1),ones(s.nu,1),ones(s.np,1));
assertEqual(dx,[1,1,1,1,1,1,1,1,1,3,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2].')
assertEqual(alg,[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,5,6,7,2,2,2,11,12,13,1,1,1].')

testStr = 's=OclTestSystemMissODE;s.setup();s.systemFun.evaluate(zeros(s.nx,1),zeros(s.nz,1),zeros(s.nu,1),zeros(s.np,1))';
assertException(testStr,'ode');

testStr = 's=OclTestSystemDoubleODE;s.setup();s.systemFun.evaluate(zeros(s.nx,1),zeros(s.nz,1),zeros(s.nu,1),zeros(s.np,1))';
assertException(testStr,'ode');

testStr = 's = OclTestSystemWrongODE;s.setup();s.systemFun.evaluate(zeros(s.nx,1),zeros(s.nz,1),zeros(s.nu,1),zeros(s.np,1))';
assertException(testStr,'exist');

testStr = 's = OclTestSystemMissDAE;s.setup();s.systemFun.evaluate(zeros(s.nx,1),zeros(s.nz,1),zeros(s.nu,1),zeros(s.np,1))';
assertException(testStr,'algebraic equations');

testStr = 's = OclTestSystemManyDAE;s.setup();s.systemFun.evaluate(zeros(s.nx,1),zeros(s.nz,1),zeros(s.nu,1),zeros(s.np,1))';
assertException(testStr,'algebraic equations');


rmpath(fullfile(oclDir,'Test','Classes'));
  