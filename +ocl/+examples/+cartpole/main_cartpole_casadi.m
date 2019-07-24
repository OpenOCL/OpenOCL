% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
function [sol,times,solver] = main_acados

  solver = ocl.Solver([], ...
                      'vars', @ocl.examples.cartpole.vars, ...
                      'dae', @ocl.examples.cartpole.dae, ...
                      'gridcosts', @ocl.examples.cartpole.gridcosts, ...
                      'N', 40, 'd', 3);

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
  ocl.stairs(times.controls, sol.controls.F/10.)
  xlabel('time [s]');
  ocl.plot(times.states, sol.states.p)
  xlabel('time [s]');
  ocl.plot(times.states, sol.states.v)
  xlabel('time [s]');
  ocl.plot(times.states, sol.states.theta)
  legend({'force [10*N]','position [m]','velocity [m/s]','theta [rad]'})
  xlabel('time [s]');

  ocl.examples.cartpole.animate(sol,times);

end





