function r = PendulumSystem()

  r = struct;
  r.varsfun = @varsfun;
  r.eqfun = @eqfun;
  r.icfun = @icfun;
  r.simcallbacksetup = @simcallbacksetup;
  r.simcallback = @simcallback;

end

function varsfun(sh)
  sh.addState('p', 2);
  sh.addState('v', 2);
  sh.addControl('F');
  sh.addAlgVar('lambda');

  sh.addParameter('m');
  sh.addParameter('l');
end

function eqfun(sh,x,z,u,p)

  ddp = - 1/p.m * z.lambda*x.p - [0;9.81] + [u.F;0];

  sh.setODE('p',x.v);
  sh.setODE('v',ddp);

  % The algebraic equation constraints the pendulum's mass to be on a circular
  % path if the initial conditions are satisfied.
  sh.setAlgEquation(dot(ddp,x.p)+x.v(1)^2+x.v(2)^2);
end

function icfun(sys,x,p)
  l = p.l;
  p = x.p;
  v = x.v;

  % this constraints the pendulum mass to be at distance l from the center
  % at the beginning of the simulation
  sys.add(p(1)^2+p(2)^2-l^2);
  sys.add(dot(p,v));
end

function simcallbacksetup(~)
  figure;
end

function simcallback(x,~,~,t0,t1,param)
  p = x.p.value;
  l = param.l.value;
  dt = t1-t0;

  plot(0,0,'ob', 'MarkerSize', 22)
  hold on
  plot([0,p(1)],[0,p(2)],'-k', 'LineWidth', 4)
  plot(p(1),p(2),'ok', 'MarkerSize', 22, 'MarkerFaceColor','r')
  xlim([-l,l])
  ylim([-l,l])

  pause(dt.value);
  hold off
end