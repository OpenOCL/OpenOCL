function testOclSystem

s = OclSystem(@emptyVars,@emptyEq);
s.setup();
assertEqual(s.nx,0);
assertEqual(s.nu,0);
assertEqual(s.np,0);
assertEqual(s.nz,0);
assertEqual(s.systemFun.evaluate([],[],[],[]),[]);

s = OclSystem(@validVars, @validEq);
s.setup();
assertEqual(s.nx,32);
assertEqual(s.nu,31);
assertEqual(s.np,31);
assertEqual(s.nz,31);
[dx,alg] = s.systemFun.evaluate(ones(s.nx,1),ones(s.nz,1),ones(s.nu,1),ones(s.np,1));
assertEqual(dx,[1,1,1,1,1,1,1,1,1,3,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,1].')
assertEqual(alg,[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,5,6,7,2,2,2,11,12,13,1,1,1].')

s = OclSystem(@missOdeVars,@missOdeEq);
s.setup();
fh = @(x,z,u,p) s.systemFun.evaluate(x,z,u,p);
assertException('ode', fh, zeros(s.nx,1), zeros(s.nz,1), zeros(s.nu,1), zeros(s.np,1));

s = OclSystem(@doubleOdeVars,@doubleOdeEq);
s.setup();
fh = @(x,z,u,p) s.systemFun.evaluate(x,z,u,p);
assertException('ode', fh, zeros(s.nx,1), zeros(s.nz,1), zeros(s.nu,1), zeros(s.np,1));

s = OclSystem(@wrongOdeVars,@wrongOdeEq);
s.setup();
fh = @(x,z,u,p) s.systemFun.evaluate(x,z,u,p);
assertException('exist', fh, zeros(s.nx,1), zeros(s.nz,1), zeros(s.nu,1), zeros(s.np,1));

s = OclSystem(@missDaeVars,@missDaeEq);
s.setup();
fh = @(x,z,u,p) s.systemFun.evaluate(x,z,u,p);
assertException('algebraic equations', fh, zeros(s.nx,1), zeros(s.nz,1), zeros(s.nu,1), zeros(s.np,1));

s = OclSystem(@manyDaeVars,@manyDaeEq);
s.setup();
fh = @(x,z,u,p) s.systemFun.evaluate(x,z,u,p);
assertException('algebraic equations', fh, zeros(s.nx,1), zeros(s.nz,1), zeros(s.nu,1), zeros(s.np,1));

end

function doubleOdeVars(self)    
  self.addState('x');
end
function doubleOdeEq(self,x,z,u,p)   
  self.setODE('x',x);
  self.setODE('x',x+x);
end

function emptyVars(self)    
end
function emptyEq(self,x,z,u,p)     
end

function manyDaeVars(self)    
  self.addState('x');
  self.addAlgVar('z');
end
function manyDaeEq(self,x,z,u,p)   
  self.setODE('x',x);
  self.setAlgEquation(z);
  self.setAlgEquation(z);
end

function missDaeVars(self)    
  self.addState('x');
  self.addAlgVar('z');
end
function missDaeEq(self,x,z,u,p)   
  self.setODE('x',x);
end

function missOdeVars(self)    
  self.addState('x')
end
function missOdeEq(self,x,z,u,p)     
end

function validVars(self)
  self.addState('a');
  self.addState('b',1);
  self.addState('c',7);
  self.addState('d',[1,1]);
  self.addState('e',[1,4]);
  self.addState('f',[5,1]);
  self.addState('g',[3,4]);

  self.addState('ttt')

  self.addControl('a'); % same as state!? (conflict bounds in Simultaneous)
  self.addControl('h',1);
  self.addControl('i',7);
  self.addControl('j',[1,1]);
  self.addControl('k',[1,4]);
  self.addControl('l',[5,1]);
  self.addControl('m',[3,4]);

  self.addAlgVar('n');
  self.addAlgVar('o',1);
  self.addAlgVar('p',7);
  self.addAlgVar('q',[1,1]);
  self.addAlgVar('r',[1,4]);
  self.addAlgVar('s',[5,1]);
  self.addAlgVar('t',[3,4]);

  self.addParameter('u');
  self.addParameter('v',1);
  self.addParameter('w',7);
  self.addParameter('x',[1,1]);
  self.addParameter('y',[1,4]);
  self.addParameter('z',[5,1]);
  self.addParameter('aa',[3,4]);
end
function validEq(self,x,z,u,p)

  self.setODE('g',p.aa+z.t);
  self.setODE('b',z.n);
  self.setODE('a',p.u);
  self.setODE('d',x.a+x.b*z.o+p.u*p.x);
  self.setODE('c',z.p);
  self.setODE('f',z.s);
  self.setODE('e',u.k);

  self.setODE('ttt',1);

  % 31x1
  self.setAlgEquation(reshape(p.y,4,1));
  self.setAlgEquation(reshape(z.t,12,1));
  self.setAlgEquation(reshape(x.g,12,1)+[u.a,u.h,u.j,4,5,6,z.n,z.q,p.u,10,11,12].');
  self.setAlgEquation(p.y(:,1:3,:));
end

function wrongOdeVars(self)    
  self.addState('x');
end
function wrongOdeEq(self,x,z,u,p)   
  self.setODE('x',x);
  self.setODE('y',x+x);
end