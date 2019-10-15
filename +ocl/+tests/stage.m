function stage

% stage empty test
stage = ocl.Stage(1, @emptyVars, @emptyDae);

pathcostfun = @(x,z,u,p) ocl.model.pathcosts(stage.pathcostsfh, ...
                                             stage.x_struct, ...
                                             stage.z_struct, ...
                                             stage.u_struct, ...
                                             stage.p_struct, ...
                                             x, z, u, p, []);
                                           
gridcostfun = @(k,K,x,p) ocl.model.gridcosts(stage.gridcostsfh, stage.x_struct, stage.p_struct, k, K, x, p, []);
gridconstraintfun = @(k,K,x,p) ocl.model.gridconstraints(stage.gridconstraintsfh, stage.x_struct, stage.p_struct, k, K, x, p, []);
      
                                           
ocl.utils.assertEqual(pathcostfun([],[],[],[]),0);
ocl.utils.assertEqual(gridcostfun(1,10,[],[]),0);

[val,lb,ub] = gridconstraintfun(1,10,[],[]);
ocl.utils.assertEqual(val,[]);
ocl.utils.assertEqual(lb,[]);
ocl.utils.assertEqual(ub,[]);

% stage valid test
stage = ocl.Stage(1, @validVars, @validDae, ...
                  @validPathCosts, @validgridCosts, @validgridConstraints);
                

pathcostfun = @(x,z,u,p) ocl.model.pathcosts(stage.pathcostsfh, ...
                                             stage.x_struct, ...
                                             stage.z_struct, ...
                                             stage.u_struct, ...
                                             stage.p_struct, ...
                                             x, z, u, p, []);
                                           
gridcostfun = @(k,K,x,p) ocl.model.gridcosts(stage.gridcostsfh, stage.x_struct, stage.p_struct, k, K, x, p, []);
gridconstraintfun = @(k,K,x,p) ocl.model.gridconstraints(stage.gridconstraintsfh, stage.x_struct, stage.p_struct, k, K, x, p, []);

c = pathcostfun(ones(stage.nx,1),ones(stage.nz,1),ones(stage.nu,1),ones(stage.np,1));
ocl.utils.assertEqual(c,26+1e-3*12);

c = gridcostfun(5,5,ones(stage.nx,1),ones(stage.np,1));
ocl.utils.assertEqual(c, -1);

% path constraints in the form of : -inf <= val <= 0 or 0 <= val <= 0
[val,lb,ub] = gridconstraintfun(2,5,ones(stage.nx,1),ones(stage.np,1));
% ub all zero
ocl.utils.assertEqual(ub,zeros(36,1));
% lb either zero for eq or -inf for ineq
ocl.utils.assertEqual(lb,[-inf,-inf,0,0,-inf,-inf,-inf*ones(1,5),0,-inf*ones(1,12),-inf*ones(1,12)].');
% val = low - high
ocl.utils.assertEqual(val,[0,0,0,0,0,-1,2,2,2,2,2,0,-3*ones(1,12),zeros(1,12)].');

% bc
[val,lb,ub] = gridconstraintfun(1,5,2*ones(stage.nx,1),ones(stage.np,1));
ocl.utils.assertEqual(ub,zeros(3,1));
ocl.utils.assertEqual(lb,[0,-inf,-inf].');
ocl.utils.assertEqual(val,[-1,1,-4].');
  
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

function validgridCosts(ch,k,N,x,p)
  ch.add(x.d);
  ch.add(0);
  ch.add(-1);
  ch.add(-1*p.v*1);
end

function validgridConstraints(ch,k,N,x,p)
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
