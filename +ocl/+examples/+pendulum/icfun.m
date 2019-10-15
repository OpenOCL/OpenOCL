function icfun(ic,x,p)

  conf = ic.userdata;

  % initial condition function
  l = conf.l;
  p = x.p;
  v = x.v;

  % this constraints the pendulum mass to be at distance l from the center
  % at the beginning of the simulation
  ic.add(p(1)^2+p(2)^2-l^2);
  ic.add(dot(p,v));
end