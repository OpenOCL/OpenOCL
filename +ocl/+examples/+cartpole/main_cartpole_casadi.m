% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%

solver = ocl.Solver(3, ...
  'vars', @ocl.examples.cartpole.vars, ...
  'dae', @ocl.examples.cartpole.dae, ...
  'pathcosts', @ocl.examples.cartpole.pathcosts, ...
  'N', 80, 'd', 3);

p0 = 0; v0 = 0;
theta0 = 180*pi/180; omega0 = 0;

solver.setInitialState('p', p0);
solver.setInitialState('v', v0);
solver.setInitialState('theta', theta0);
solver.setInitialState('omega', omega0);

solver.initialize('theta', [0 1], [pi 0]);

% Run solver to obtain solution
[sol,times] = solver.solve();

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




