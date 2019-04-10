function mainCartPole

  options = OclOptions();
  options.nlp.controlIntervals = 50;
  options.nlp.collocationOrder = 3;

  system = OclSystem('varsfun',@varsfun, 'eqfun', @eqfun);
  ocp = OclOCP('arrivalcosts', @arrivalcosts);
  ocl = OclSolver([], system, ocp, options);

  p0 = 0; v0 = 0;
  theta0 = 180*pi/180; omega0 = 0;

  ocl.setInitialBounds('p', p0);
  ocl.setInitialBounds('v', v0);
  ocl.setInitialBounds('theta', theta0);
  ocl.setInitialBounds('omega', omega0);

  ocl.setEndBounds('p', 0);
  ocl.setEndBounds('v', 0);
  ocl.setEndBounds('theta', 0);
  ocl.setEndBounds('omega', 0);

  ocl.setParameter('T', 0, 20);

  % Get and set initial guess
  initialGuess = ocl.getInitialGuess();

  % Run solver to obtain solution
  [sol,times] = ocl.solve(initialGuess);

  % visualize solution
  figure; hold on; grid on;
  oclStairs(times.controls, sol.controls.F/10.)
  xlabel('time [s]');
  oclPlot(times.states, sol.states.p)
  xlabel('time [s]');
  oclPlot(times.states, sol.states.v)
  xlabel('time [s]');
  oclPlot(times.states, sol.states.theta)
  legend({'force [10*N]','position [m]','velocity [m/s]','theta [rad]'})
  xlabel('time [s]');

  animateCartPole(sol,times);

end

function varsfun(sh)

  sh.addState('p', 'lb', -5, 'ub', 5);
  sh.addState('theta', 'lb', -2*pi, 'ub', 2*pi);
  sh.addState('v');
  sh.addState('omega');

  sh.addControl('F', 'lb', -20, 'ub', 20);
end

function eqfun(sh,x,~,u,~)

  g = 9.8;
  cm = 1.0;
  pm = 0.1;
  phl = 0.5; % pole half length

  m = cm+pm;
  pml = pm*phl; % pole mass length

  ctheta = cos(x.theta);
  stheta = sin(x.theta);

  domega = (g*stheta + ...
            ctheta * (-u.F-pml*x.omega^2*stheta) / m) / ...
            (phl * (4.0 / 3.0 - pm * ctheta^2 / m));

  a = (u.F + pml*(x.omega^2*stheta-domega*ctheta)) / m;

  sh.setODE('p',x.v);
  sh.setODE('theta',x.omega);
  sh.setODE('v',a);
  sh.setODE('omega',domega);
end

function arrivalcosts(self,x,tf,p)
  self.add( tf );
end
