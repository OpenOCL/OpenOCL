ocp = ocl.Problem( ...
  3, ...
  'vars', @ocl.examples.cartpole.vars, ...
  'dae', @ocl.examples.cartpole.dae, ...
  'pathcosts', @ocl.examples.cartpole.pathcosts, ...
  'terminalcost', @ocl.examples.cartpole.terminalcost, ...
  'N', 100, 'd', 3);

ocp.setInitialState('p', 0);
ocp.setInitialState('v', 0);
ocp.setInitialState('theta', pi);
ocp.setInitialState('omega', 0);

ocp.initialize('theta', [0 1], [pi 0]);

[sol,times] = ocp.solve();

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




