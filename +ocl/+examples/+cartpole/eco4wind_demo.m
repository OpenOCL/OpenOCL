clear all;

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

% solver.initialize('theta', [0 1], [pi 0]);

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


acados_solver = ocl.acados.AcadosSolver(3, ...
  'vars', @ocl.examples.cartpole.vars, ...
  'dae', @ocl.examples.cartpole.dae, ...
  'pathcosts', @ocl.examples.cartpole.pathcosts, ...
  'N', 80, 'd', 3);

p0 = 0; v0 = 0;
theta0 = 180*pi/180; omega0 = 0;

acados_solver.setInitialState('p', p0);
acados_solver.setInitialState('v', v0);
acados_solver.setInitialState('theta', theta0);
acados_solver.setInitialState('omega', omega0);

x_times_norm = times.states.value;
x_times_norm = x_times_norm / max(x_times_norm);

acados_solver.initialize('p', x_times_norm, sol.states.p.value);
acados_solver.initialize('v', x_times_norm, sol.states.v.value);
acados_solver.initialize('theta', x_times_norm, sol.states.theta.value);
acados_solver.initialize('omega', x_times_norm, sol.states.omega.value);

% Run solver to obtain solution
[sol,times] = acados_solver.solve();

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






