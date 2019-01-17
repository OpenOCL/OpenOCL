
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

% visualize solution
figure; hold on; grid on;
oclStairs(times.controls, sol.controls/10.)
xlabel('time [s]');
oclPlot(times.states, sol.states.p)
xlabel('time [s]');
oclPlot(times.states, sol.states.v)
xlabel('time [s]'); 
oclPlot(times.states, sol.states.theta)
legend({'force [10*N]','position [m]','velocity [m/s]','theta [rad]'})
xlabel('time [s]');

animateCartPole(sol,times);


