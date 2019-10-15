% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%

function integrator

% linear system defined below
[x_struct, z_struct, u_struct, p_struct, ...
          ~, ~, ~, ~, ...
          x_order] = ocl.model.vars(@linearVars, []);
        
daefun = @(x,z,u,p) ocl.model.dae(@linearEq, ...
  x_struct, z_struct, u_struct, p_struct, x_order, ...
  x, z, u, p, []);

d = 2;
collocation = ocl.collocation.Collocation(x_struct, z_struct, u_struct, p_struct, x_order, ...
                              daefun, @(varargin)0, d);

N = 60;
T = 1;
h = T/N;

xsym = casadi.SX.sym('x', length(x_struct));
xisym = casadi.SX.sym('xi', length(x_struct)*d);
usym = casadi.SX.sym('u', length(u_struct));

[~, ~, equations] = ocl.collocation.equations(collocation, xsym, xisym, usym, h, []);

nlp    = struct('x', vertcat(xsym,xisym,usym), 'f', 0, 'g', equations);

opt.verbose_init = 0;
opt.verbose = 0;
opt.common_options.verbose = 0;
opt.print_time = 0;
opt.ipopt.print_level = 0;
solver = casadi.nlpsol('solver', 'ipopt', nlp, opt);

% constant start velocity, no acceleration
p0 = 0;
v0 = 1;
u = 0;

x = [p0;v0];
v = [x;repmat(x,d,1);u];
for i=1:N
  v = solver('x0', v, 'lbx', [x;repmat([-inf;-inf],d,1);-inf], 'ubx', [x;repmat([inf;inf],d,1);inf],'lbg', 0, 'ubg', 0);
  v = full(v.x);
  x = v(2+d*2-1:2+d*2);
end

ocl.utils.assertAlmostEqual(x,[1;1],'Integrator test (constant velocity) failed');

% constant start velocity, constant acceleration
p0 = 2;
v0 = 12;
u = -1.5;

x = [p0;v0];
v = [x;repmat(x,d,1);u];
for i=1:N
  v = solver('x0', v, 'lbx', [x;repmat([-inf;-inf],d,1);-inf], 'ubx', [x;repmat([inf;inf],d,1);inf],'lbg', 0, 'ubg', 0);
  v = full(v.x);
  x = v(2+d*2-1:2+d*2);
end

pEnd = p0 + v0*T + 0.5*u*T^2;
vEnd = v0 + u*T;

ocl.utils.assertAlmostEqual(x,[pEnd;vEnd],'Integrator test (constant acceleration) failed',0.1);

end

function linearVars(self)
  self.addState('p');
  self.addState('v');

  self.addControl('F');
end

function linearEq(self,x,z,u,p)
  m = 1;

  self.setODE('p', x.v);
  self.setODE('v', u.F/m);
end
