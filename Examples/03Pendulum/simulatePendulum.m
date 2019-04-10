function simulatePendulum

% Create system and simulator
system = OclSystem(@varsfun, @eqfun, @icfun, 'cbsetupfun', @simcallbacksetup, 'cbfun', @simcallback);
simulator = Simulator(system);

states = simulator.getStates();
states.p.set([0,1]);
states.v.set([-0.5,-1]);

p = simulator.getParameters();
p.m.set(1);
p.l.set(1);

times = 0:0.1:4;

% simulate without control inputs
%simulator.simulate(states,times,p);

% simulate again using a given series of control inputs
controlsSeries = simulator.getControlsVec(length(times)-1);
controlsSeries.F.set(10);

[~,~,~] = simulator.simulate(states,times,controlsSeries,p);

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

function pathcosts(ch,~,~,controls,~,~,~)
  F  = controls.F;
  ch.add( 1e-3 * F^2 );
end

