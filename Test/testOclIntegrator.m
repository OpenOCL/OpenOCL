function testOclIntegrator
  
oclDir = getenv('OPENOCL_PATH');
addpath(fullfile(oclDir,'Test','Classes'));

s = OclTestLinearSystem;
s.setup();



d = 2;
integ = CollocationIntegrator(s,d);

N = 60;
T = 1;
h = T/N;

t0 = 0;
tf = t0 + h;
xsym = casadi.SX.sym('x',s.nx);
xisym = casadi.SX.sym('xi',s.nx*d);
usym = casadi.SX.sym('u',s.nu);

pcFun = OclFunction(s,@(varargin)0,{[s.nx*d,1],[],[1,1],[1,1],[1,1],[]},1);
integ.pathCostsFun = pcFun;

[~, ~, ~, equations, times] = integ.integratorFun.evaluate(xsym,xisym,usym,t0,t0+h,tf,[],pcFun);

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

assertAlmostEqual(x,[1;1]);

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

assertAlmostEqual(x,[pEnd;vEnd],0.1);
