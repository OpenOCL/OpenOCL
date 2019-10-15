function daefun(dh,x,z,u,p)

  conf = dh.userdata;

  ddp = - 1/conf.m * z.lambda*x.p - [0;9.81] + [u.F;0];

  dh.setODE('p',x.v);
  dh.setODE('v',ddp);
  dh.setODE('time', 1);

  % The algebraic equation constraints the pendulum's mass to be on a circular
  % path if the initial conditions are satisfied.
  dh.setAlgEquation(dot(ddp,x.p)+x.v(1)^2+x.v(2)^2);
end