% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%

function [sol,times,solver] = mainCartPole  

  options = ocl.Options();
  options.nlp.controlIntervals = 50;
  options.nlp.collocationOrder = 3;

  system = ocl.System('varsfun',@varsfun, 'eqfun', @eqfun);
  ocp = ocl.OCP('arrivalcosts', @arrivalcosts);
  
  solver = ocl.Solver([], system, ocp, options);

  p0 = 0; v0 = 0;
  theta0 = 180*pi/180; omega0 = 0;

  solver.setInitialBounds('p', p0);
  solver.setInitialBounds('v', v0);
  solver.setInitialBounds('theta', theta0);
  solver.setInitialBounds('omega', omega0);
  
  solver.setInitialBounds('time', 0);

  solver.setEndBounds('p', 0);
  solver.setEndBounds('v', 0);
  solver.setEndBounds('theta', 0);
  solver.setEndBounds('omega', 0);

  % Run solver to obtain solution
  [sol,times] = solver.solve(solver.ig());

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
  
  sh.addState('time', 'lb', 0, 'ub', 20);

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
  
  sh.setODE('time', 1);
  
end

function arrivalcosts(self,x,p)
  self.add( x.time );
end
