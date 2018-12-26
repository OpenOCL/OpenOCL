FINALTIME = 10;             % horizon length (seconds)
CONTROL_INTERVALS = 30;     % control discretization

% Create system and OCP
system = VanDerPolSystem;
ocp = VanDerPolOCP(system);

% Get and set solver options
options = Solver.getOptions;
options.iterationCallback = false;
options.nlp.controlIntervals = CONTROL_INTERVALS;
options.nlp.collocationOrder = 3;
options.nlp.ipopt.linear_solver = 'mumps';
options.nlp.solver = 'ipopt';

nlp = Solver.getNLP(ocp,system,options);

% state and control bounds
nlp.setBounds('x',    -0.25, inf);   % -0.25 <= x <= inf
nlp.setBounds('u',    -1,    1);     % -1    <= u <= 1

% intial state bounds
nlp.setInitialBounds('x',     0);            % x1 == 0
nlp.setInitialBounds('y',     1);            % y1 == 1

nlp.setParameter('time',  FINALTIME);

% Create solver
solver = Solver.getSolver(nlp,options);

% Get and set initial guess
initialGuess = nlp.getInitialGuess;
initialGuess.states.x.set(-0.2);

% Run solver to obtain solution
[solution,times] = solver.solve(initialGuess);
times = times.value;

% plot solution
figure
hold on 
plot(times,solution.states.x.value,'-.','LineWidth',2)
plot(times,solution.states.y.value,'--k','LineWidth',2)
stairs(times(1:end-1),solution.controls.u.value,'r','LineWidth',2)
xlabel('time')
legend({'x','y','u'})
