function daefun(sh,x,z,u,p,conf)

  ddp = - 1/conf.m * z.lambda*x.p - [0;9.81] + [u.F;0];

  sh.setODE('p', p.T*x.v);
  sh.setODE('v', p.T*ddp);

  % The algebraic equation constraints the pendulum's mass to be on a circular
  % path if the initial conditions are satisfied.
  sh.setAlgEquation(dot(ddp,x.p)+x.v(1)^2+x.v(2)^2);
end