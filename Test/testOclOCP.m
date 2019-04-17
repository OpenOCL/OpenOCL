function testOclOCP

% ocp empty test
ocp = OclOCP();
s = OclSystem(@emptyVars,@emptyEq);
s.setup();
opt = OclOptions;
opt.controls_regularization = false;
h = OclOcpHandler(1,s,ocp,opt);
h.setup();
assertEqual(h.pathCostsFun.evaluate([],[],[],[]),0);
assertEqual(h.arrivalCostsFun.evaluate([],[]),0);

[val,lb,ub] = h.pathConstraintsFun.evaluate([],[]);
assertEqual(val,[]);
assertEqual(lb,[]);
assertEqual(ub,[]);
[val,lb,ub] = h.boundaryConditionsFun.evaluate([],[],[]);
assertEqual(val,[]);
assertEqual(lb,[]);
assertEqual(ub,[]);

% ocp valid test
ocp = OclOCP(@validPathCosts, @validArrivalCosts, @validPathConstraints, ...
             @validBoundaryConditions, @validDiscreteCosts);
s = OclSystem(@validVars,@validEq);
N = 2;
nv = (N+1)*s.nx+N*s.nu;
h = OclOcpHandler(1,s,ocp,opt);
h.setup();
h.setNlpVarsStruct(OclMatrix([nv,1]));

c = h.pathCostsFun.evaluate(ones(s.nx,1),ones(s.nz,1),ones(s.nu,1),ones(s.np,1));
assertEqual(c,26+1e-3*12);

c = h.arrivalCostsFun.evaluate(ones(s.nx,1),ones(s.np,1));
assertEqual(c, -1);

% path constraints in the form of : -inf <= val <= 0 or 0 <= val <= 0
[val,lb,ub] = h.pathConstraintsFun.evaluate(ones(s.nx,1),ones(s.np,1));
% ub all zero
assertEqual(ub,zeros(36,1));
% lb either zero for eq or -inf for ineq
assertEqual(lb,[-inf,-inf,0,0,-inf,-inf,-inf*ones(1,5),0,-inf*ones(1,12),-inf*ones(1,12)].');
% val = low - high
assertEqual(val,[0,0,0,0,0,-1,2,2,2,2,2,0,-3*ones(1,12),zeros(1,12)].');

% bc
[val,lb,ub] = h.boundaryConditionsFun.evaluate(2*ones(s.nx,1),3*ones(s.nx,1),ones(s.np,1));
assertEqual(ub,zeros(3,1));
assertEqual(lb,[0,-inf,-inf].');
assertEqual(val,[-1,1,-4].');

c = h.discreteCostsFun.evaluate(ones(nv,1));
assertEqual(c, nv);
  
end

function emptyVars(self)    
end

function emptyEq(self,x,z,u,p)     
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

function validPathCosts(self,x,z,u,p)
  self.add(x.a); % 1
  self.add(x.c.'*x.c); % 7
  self.add(1e-3*sum(sum(u.m))+sum(sum(p.z))+sum(sum(z.t))+x.ttt+1); % 1e-3*12+26
  self.add(0); % 0 ([]) or () ? invalid!
  self.add(-1); % -1
end

function validArrivalCosts(self,xf,p)
  self.add(xf.d);
  self.add(0);
  self.add(-1);
  self.add(-1*p.v*1);
end

function validPathConstraints(self,x,p)

  % scalar with constant
  self.add(x.a,'<=',1);
  self.add(x.a,'>=',1);
  self.add(x.a,'==',1);
  self.add(1,'==',x.a);
  self.add(1,'>=',x.a);
  self.add(1,'<=',x.ttt+p.aa(1,1,1));

  % vector with vector
  self.add(x.f,'>=',2+ones(5,1));

  % scalar with scalar
  self.add(x.d,'==',x.b);

  % matrix 3x4 with scalar
  self.add(x.g,'<=',4);

  % matrix with matrix 3x4
  self.add(x.g,'<=',p.aa);
end

function validBoundaryConditions(self,x0,xf,p)
  self.add(x0.a,'==',xf.a);
  self.add(x0.a,'>=',xf.a*p.x);
  self.add(x0.b,'<=',xf.a+xf.a);
end

function validDiscreteCosts(self,vars)
  self.add(sum(vars));
end