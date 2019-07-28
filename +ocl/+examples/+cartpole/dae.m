function dae(daeh,x,z,u,p)

g = 9.8;
cm = 5.0;
pm = 0.3;
phl = 0.5;

v = x.v;
theta = x.theta;
omega = x.omega;

m = cm+pm;
pml = pm*phl;

domega = (g*sin(theta) + ...
  cos(theta) * (-u.F-pml*omega^2*sin(theta)) / m) / ...
  (phl * (4.0 / 3.0 - pm * cos(theta)^2 / m));

a = (u.F + pml*(omega^2*sin(theta)-domega*cos(theta))) / m;

daeh.setODE('p',     v);
daeh.setODE('theta', omega);
daeh.setODE('v',     a);
daeh.setODE('omega', domega);
