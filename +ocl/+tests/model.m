% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%

function model

% empty dae test
[x_struct, z_struct, u_struct, p_struct, ...
          ~, ~, ~, ~, ...
          x_order] = ocl.model.vars(@emptyVars, []);
        
daefun = @(x,z,u,p) ocl.model.dae( ...
        @emptyEq, ...
        x_struct, ...
        z_struct, ...
        u_struct, ...
        p_struct, ...
        x_order, x, z, u, p, []);
      
nx = length(x_struct);
nz = length(z_struct);
nu = length(u_struct);
np = length(p_struct);

ocl.utils.assertEqual(nx,0);
ocl.utils.assertEqual(nz,0);
ocl.utils.assertEqual(nu,0);
ocl.utils.assertEqual(np,0);

ocl.utils.assertEqual(daefun([],[],[],[]),[]);

% valid dae test
[x_struct, z_struct, u_struct, p_struct, ...
          ~, ~, ~, ~, ...
          x_order] = ocl.model.vars(@validVars, []);
        
daefun = @(x,z,u,p) ocl.model.dae( ...
        @validEq, ...
        x_struct, ...
        z_struct, ...
        u_struct, ...
        p_struct, ...
        x_order, x, z, u, p, []);
      
nx = length(x_struct);
nz = length(z_struct);
nu = length(u_struct);
np = length(p_struct);

ocl.utils.assertEqual(nx,32);
ocl.utils.assertEqual(nu,31);
ocl.utils.assertEqual(np,31);
ocl.utils.assertEqual(nz,31);
[dx,alg] = daefun(ones(nx,1),ones(nz,1),ones(nu,1),ones(np,1));
ocl.utils.assertEqual(dx,[1,1,1,1,1,1,1,1,1,3,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,1].')
ocl.utils.assertEqual(alg,[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,5,6,7,2,2,2,11,12,13,1,1,1].')


% miss ode test
[x_struct, z_struct, u_struct, p_struct, ...
          ~, ~, ~, ~, ...
          x_order] = ocl.model.vars(@missOdeVars, []);
        
daefun = @(x,z,u,p) ocl.model.dae( ...
        @missOdeEq, ...
        x_struct, ...
        z_struct, ...
        u_struct, ...
        p_struct, ...
        x_order, x, z, u, p, []);
      
nx = length(x_struct);
nz = length(z_struct);
nu = length(u_struct);
np = length(p_struct);

ocl.utils.assertException('ode', daefun, zeros(nx,1), zeros(nz,1), zeros(nu,1), zeros(np,1));


% double ode test
[x_struct, z_struct, u_struct, p_struct, ...
          ~, ~, ~, ~, ...
          x_order] = ocl.model.vars(@doubleOdeVars, []);
        
daefun = @(x,z,u,p) ocl.model.dae( ...
        @doubleOdeEq, ...
        x_struct, ...
        z_struct, ...
        u_struct, ...
        p_struct, ...
        x_order, x, z, u, p, []);
      
nx = length(x_struct);
nz = length(z_struct);
nu = length(u_struct);
np = length(p_struct);

ocl.utils.assertException('ode', daefun, zeros(nx,1), zeros(nz,1), zeros(nu,1), zeros(np,1));

% wrong ode test
[x_struct, z_struct, u_struct, p_struct, ...
          ~, ~, ~, ~, ...
          x_order] = ocl.model.vars(@wrongOdeVars, []);
        
daefun = @(x,z,u,p) ocl.model.dae( ...
        @wrongOdeEq, ...
        x_struct, ...
        z_struct, ...
        u_struct, ...
        p_struct, ...
        x_order, x, z, u, p, []);
      
nx = length(x_struct);
nz = length(z_struct);
nu = length(u_struct);
np = length(p_struct);

ocl.utils.assertException('exist', daefun, zeros(nx,1), zeros(nz,1), zeros(nu,1), zeros(np,1));

% missing dae test
[x_struct, z_struct, u_struct, p_struct, ...
          ~, ~, ~, ~, ...
          x_order] = ocl.model.vars(@missDaeVars, []);
        
daefun = @(x,z,u,p) ocl.model.dae( ...
        @missDaeEq, ...
        x_struct, ...
        z_struct, ...
        u_struct, ...
        p_struct, ...
        x_order, x, z, u, p, []);
      
nx = length(x_struct);
nz = length(z_struct);
nu = length(u_struct);
np = length(p_struct);

ocl.utils.assertException('algebraic equations', daefun, zeros(nx,1), zeros(nz,1), zeros(nu,1), zeros(np,1));

% too many dae test
[x_struct, z_struct, u_struct, p_struct, ...
          ~, ~, ~, ~, ...
          x_order] = ocl.model.vars(@missDaeVars, []);
        
daefun = @(x,z,u,p) ocl.model.dae( ...
        @missDaeEq, ...
        x_struct, ...
        z_struct, ...
        u_struct, ...
        p_struct, ...
        x_order, x, z, u, p, []);
      
nx = length(x_struct);
nz = length(z_struct);
nu = length(u_struct);
np = length(p_struct);

ocl.utils.assertException('algebraic equations', daefun, zeros(nx,1), zeros(nz,1), zeros(nu,1), zeros(np,1));

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