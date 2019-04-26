function testOclIntegrator

% linear system defined below
s = OclSystem(@linearVars,@linearEq);

d = 2;
integ = OclCollocation(s.states, s.algvars, s.nu, s.np, s.daefun, d);

N = 60;
T = 1;
h = T/N;

t0 = 0;
tf = t0 + h;
xsym = casadi.SX.sym('x',s.nx);
xisym = casadi.SX.sym('xi',s.nx*d);
usym = casadi.SX.sym('u',s.nu);

pcFun = OclFunction(s,@(varargin)0,{[s.nx*d,1],[],[1,1],[1,1],[1,1],[]},1);
integ.pathcostfun = pcFun;

[~, ~, ~, equations, ~] = integ.integratorfun.evaluate(xsym,xisym,usym,t0,h,[]);

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

assertAlmostEqual(x,[1;1],'Integrator test (constant velocity) failed');

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

assertAlmostEqual(x,[pEnd;vEnd],'Integrator test (constant acceleration) failed',0.1);

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
