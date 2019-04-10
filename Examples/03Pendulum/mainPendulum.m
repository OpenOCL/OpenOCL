function [vars,times,ocl] = mainPendulum

  options = OclOptions;
  options.nlp.controlIntervals = 50;

  system = OclSystem(@varsfun, @eqfun, @icfun, 'cbsetupfun', @simcallbacksetup, 'cbfun', @simcallback);
  ocp = OclOCP(@pathcosts);

  ocl = OclSolver([], system, ocp, options);

  ocl.setParameter('T',  1, 10);
  ocl.setBounds('p',       -[3;3], [3;3]);
  ocl.setBounds('v',       -[3;3], [3;3]);
  ocl.setBounds('F',       -25, 25);
  ocl.setBounds('lambda',  -50, 50);
  ocl.setBounds('m',       1);
  ocl.setBounds('l',       1);

  ocl.setInitialBounds('p', [-inf;-1],[inf;-1]);
  ocl.setInitialBounds('v', [0.5;0]);

  ocl.setEndBounds('p',     [0,1]);
  ocl.setEndBounds('v',     [-1;-1], [1;1]);

  vars = ocl.getInitialGuess();
  vars.states.p.set([0;-1]);
  vars.states.v.set([0.1;0]);
  vars.controls.F.set(-10);

  [solution,times] = ocl.solve(vars);

  figure
  ocl.solutionCallback(times,solution);

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
