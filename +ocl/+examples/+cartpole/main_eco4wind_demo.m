clear all;

T = 3;

ipopt_solver = ocl.Solver( ...
  T, ...
  'vars', @ocl.examples.cartpole.vars, ...
  'dae', @ocl.examples.cartpole.dae, ...
  'pathcosts', @ocl.examples.cartpole.pathcosts, ...
  'terminalcost', @ocl.examples.cartpole.terminalcost, ...
  'N', 100, 'd', 3);

ipopt_solver.setInitialState('p', 0);
ipopt_solver.setInitialState('v', 0);
ipopt_solver.setInitialState('theta', pi);
ipopt_solver.setInitialState('omega', 0);

acados_solver = ocl.acados.Solver( ...
  T, ...
  'vars', @ocl.examples.cartpole.vars, ...
  'dae', @ocl.examples.cartpole.dae, ...
  'pathcosts', @ocl.examples.cartpole.pathcosts, ...
  'terminalcost', @ocl.examples.cartpole.terminalcost, ...
  'N', 100);

acados_solver.setInitialState('p', 0);
acados_solver.setInitialState('v', 0);
acados_solver.setInitialState('theta', pi);
acados_solver.setInitialState('omega', 0);

%% Run first ipopt and then acados
[sol,times] = ipopt_solver.solve();

acados_solver.initialize('p', times.states, sol.states.p, T);
acados_solver.initialize('v', times.states, sol.states.v, T);
acados_solver.initialize('theta', times.states, sol.states.theta, T);
acados_solver.initialize('omega', times.states, sol.states.omega, T);

acados_solver.initialize('F', times.controls, sol.controls.F, T);

[sol,times] = acados_solver.solve();

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






