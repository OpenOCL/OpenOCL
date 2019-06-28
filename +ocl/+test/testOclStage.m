function testOclStage

% stage empty test
stage = OclStage(1, @emptyVars, @emptyDae);
assertEqual(stage.pathcostfun([],[],[],[]),0);
assertEqual(stage.intervalcostfun(1,10,[],[]),0);

[val,lb,ub] = stage.intervalconstraintfun(1,10,[],[]);
assertEqual(val,[]);
assertEqual(lb,[]);
assertEqual(ub,[]);

% stage valid test
stage = OclStage(1, @validVars, @validDae, ...
                  @validPathCosts, @validintervalCosts, @validintervalConstraints);

c = stage.pathcostfun(ones(stage.nx,1),ones(stage.nz,1),ones(stage.nu,1),ones(stage.np,1));
assertEqual(c,26+1e-3*12);

c = stage.intervalcostfun(5,5,ones(stage.nx,1),ones(stage.np,1));
assertEqual(c, -1);

% path constraints in the form of : -inf <= val <= 0 or 0 <= val <= 0
[val,lb,ub] = stage.intervalconstraintfun(2,5,ones(stage.nx,1),ones(stage.np,1));
% ub all zero
assertEqual(ub,zeros(36,1));
% lb either zero for eq or -inf for ineq
assertEqual(lb,[-inf,-inf,0,0,-inf,-inf,-inf*ones(1,5),0,-inf*ones(1,12),-inf*ones(1,12)].');
% val = low - high
assertEqual(val,[0,0,0,0,0,-1,2,2,2,2,2,0,-3*ones(1,12),zeros(1,12)].');

% bc
[val,lb,ub] = stage.intervalconstraintfun(1,5,2*ones(stage.nx,1),ones(stage.np,1));
assertEqual(ub,zeros(3,1));
assertEqual(lb,[0,-inf,-inf].');
assertEqual(val,[-1,1,-4].');
  
end

function emptyVars(self)    
end

function emptyDae(self,x,z,u,p)     
end

function validVars(svh)
  svh.addState('a');
  svh.addState('b',1);
  svh.addState('c',7);
  svh.addState('d',[1,1]);
  svh.addState('e',[1,4]);
  svh.addState('f',[5,1]);
  svh.addState('g',[3,4]);

  svh.addState('ttt')

  svh.addControl('a'); % same as state!? (conflict bounds in Simultaneous)
  svh.addControl('h',1);
  svh.addControl('i',7);
  svh.addControl('j',[1,1]);
  svh.addControl('k',[1,4]);
  svh.addControl('l',[5,1]);
  svh.addControl('m',[3,4]);

  svh.addAlgVar('n');
  svh.addAlgVar('o',1);
  svh.addAlgVar('p',7);
  svh.addAlgVar('q',[1,1]);
  svh.addAlgVar('r',[1,4]);
  svh.addAlgVar('s',[5,1]);
  svh.addAlgVar('t',[3,4]);

  svh.addParameter('u');
  svh.addParameter('v',1);
  svh.addParameter('w',7);
  svh.addParameter('x',[1,1]);
  svh.addParameter('y',[1,4]);
  svh.addParameter('z',[5,1]);
  svh.addParameter('aa',[3,4]);
end

function validDae(daeh,x,z,u,p)

  daeh.setODE('g',p.aa+z.t);
  daeh.setODE('b',z.n);
  daeh.setODE('a',p.u);
  daeh.setODE('d',x.a+x.b*z.o+p.u*p.x);
  daeh.setODE('c',z.p);
  daeh.setODE('f',z.s);
  daeh.setODE('e',u.k);

  daeh.setODE('ttt',1);

  % 31x1
  daeh.setAlgEquation(reshape(p.y,4,1));
  daeh.setAlgEquation(reshape(z.t,12,1));
  daeh.setAlgEquation(reshape(x.g,12,1)+[u.a,u.h,u.j,4,5,6,z.n,z.q,p.u,10,11,12].');
  daeh.setAlgEquation(p.y(:,1:3,:));
end

function validPathCosts(ch,x,z,u,p)
  ch.add(x.a); % 1
  ch.add(x.c.'*x.c); % 7
  ch.add(1e-3*sum(sum(u.m))+sum(sum(p.z))+sum(sum(z.t))+x.ttt+1); % 1e-3*12+26
  ch.add(0); % 0 ([]) or () ? invalid!
  ch.add(-1); % -1
end

function validintervalCosts(ch,k,N,x,p)
  ch.add(x.d);
  ch.add(0);
  ch.add(-1);
  ch.add(-1*p.v*1);
end

function validintervalConstraints(ch,k,N,x,p)
  if k == 1
    ch.add(x.a,'==',3);
    ch.add(x.a,'>=',3*1);
    ch.add(x.b,'<=',3+3);
  else
    % scalar with constant
    ch.add(x.a,'<=',1);
    ch.add(x.a,'>=',1);
    ch.add(x.a,'==',1);
    ch.add(1,'==',x.a);
    ch.add(1,'>=',x.a);
    ch.add(1,'<=',x.ttt+p.aa(1,1,1));

    % vector with vector
    ch.add(x.f,'>=',2+ones(5,1));

    % scalar with scalar
    ch.add(x.d,'==',x.b);

    % matrix 3x4 with scalar
    ch.add(x.g,'<=',4);

    % matrix with matrix 3x4
    ch.add(x.g,'<=',p.aa);
  end
end
