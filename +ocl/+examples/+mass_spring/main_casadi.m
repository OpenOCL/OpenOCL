num_masses = 4;

data = struct;
data.num_masses = num_masses;

ocp = ocl.Problem(10, ...
  @ocl.examples.mass_spring.vars, ...
  @ocl.examples.mass_spring.dae, ...
  @ocl.examples.mass_spring.pathcosts, ...
  @ocl.examples.mass_spring.gridcosts, ...
  'N', 20, 'userdata', data);

x0 = zeros(2*num_masses, 1);
x0(1) = 2.5;
x0(2) = 2.5;

ocp.setInitialBounds('x', x0);

[sol,times] = ocp.solve(ocp.ig());

figure()
subplot(2, 1, 1)
ocl.plot(times.states, sol.states.x);
title('trajectory')
ylabel('x')
subplot(2, 1, 2)
ocl.stairs(times.controls, sol.controls.u.');
ylabel('u')
xlabel('sample')