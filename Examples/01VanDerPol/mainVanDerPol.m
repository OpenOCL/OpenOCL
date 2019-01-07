FINALTIME = 10;             % horizon length (seconds)
CONTROL_INTERVALS = 30;     % control discretization

% Get and set solver options
options = OclOptions();
options.iterationCallback = false;
options.nlp.controlIntervals = CONTROL_INTERVALS;
options.nlp.collocationOrder = 3;
options.nlp.ipopt.linear_solver = 'mumps';
options.nlp.solver = 'ipopt';

ocl = OclSolver(VanDerPolSystem,VanDerPolOCP,options);

% state and control bounds
ocl.setBounds('x',    -0.25, inf);   % -0.25 <= x <= inf
ocl.setBounds('u',    -1,    1);     % -1    <= u <= 1

% intial state bounds
ocl.setInitialBounds('x',     0);            % x1 == 0
ocl.setInitialBounds('y',     1);            % y1 == 1

ocl.setParameter('time',  FINALTIME);

% Get and set initial guess
initialGuess = ocl.getInitialGuess();
initialGuess.states.x.set(-0.2);

% Run solver to obtain solution
[solution,times] = ocl.solve(initialGuess);

% plot solution
figure
hold on 
plot(times.states.value,solution.states.x.value,'-.','LineWidth',2)
plot(times.states.value,solution.states.y.value,'--k','LineWidth',2)
stairs(times.controls.value,solution.controls.u.value,'r','LineWidth',2)
xlabel('time')
legend({'x','y','u'})
