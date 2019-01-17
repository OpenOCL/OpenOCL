
% Set solver options
options = OclOptions();
options.nlp.controlIntervals = 50;
options.nlp.collocationOrder = 3;

ocl = OclSolver(CartPoleSystem,CartPoleOCP,options);

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

ocl.setParameter('time', 0, 20);

% Get and set initial guess
initialGuess = ocl.getInitialGuess();

% Run solver to obtain solution
[sol,times] = ocl.solve(initialGuess);

% plot solution
handles = {};
pmax = max(abs(sol.states.p.value));
for k=2:prod(times.integrator.size)
  t = times.integrator(k);
  x = sol.integrator.states(:,:,k);
  dt = times.integrator(k)-times.integrator(k-1);
  handles = visualizeCartPole(t, dt.value, x, [0,0,0,0], pmax, handles);
end

figure;
oclPlot(times.controls, sol.controls)
