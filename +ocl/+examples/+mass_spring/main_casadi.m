num_masses = 4;

varsfh = @(h) ocl.examples.mass_spring.vars(h,num_masses);
daefh = @(h,x,z,u,p) ocl.examples.mass_spring.dae(h,x,u);
pathcostsfh = @(h,x,z,u,p) ocl.examples.mass_spring.pathcosts(h,x,u);
gridcostsfh = @(h,k,K,x,p) ocl.examples.mass_spring.gridcosts(h,k,K,x);

solver = ocl.Solver(10, varsfh, daefh, pathcostsfh, gridcostsfh, 'N', 30, 'd', 2);

x0 = zeros(2*num_masses, 1); 
x0(1)=2.5; 
x0(2)=2.5;

solver.setInitialBounds('x', x0);

solver.setBounds('x', -4, 4);
solver.setBounds('u', -0.5, 0.5);

[sol,times] = solver.solve(solver.ig());

figure()
subplot(2, 1, 1)
oclPlot(times.states, sol.states.x);
title('trajectory')
ylabel('x')
subplot(2, 1, 2)
oclStairs(times.controls, sol.controls.u.');
ylabel('u')
xlabel('sample')