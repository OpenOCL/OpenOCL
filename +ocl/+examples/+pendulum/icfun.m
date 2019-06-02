function icfun(ic,x,p)
  % initial condition function
  l = p.l;
  p = x.p;
  v = x.v;

  % this constraints the pendulum mass to be at distance l from the center
  % at the beginning of the simulation
  ic.add(p(1)^2+p(2)^2-l^2);
  ic.add(dot(p,v));
end