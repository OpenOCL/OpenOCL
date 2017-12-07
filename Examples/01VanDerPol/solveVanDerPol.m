FINALTIME = 10;               % horizon length (seconds)
CONTROL_INTERVALS = 30;    % horizon discretization

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

%
% Define bounds on the state, control, and algebraic variables.

% state and control bounds
nlp.setVariableBound('x',    -0.25, inf);   % -0.25 <= x <= inf
nlp.setVariableBound('u',    -1,    1);     % -1    <= u <= 1

% intial state bounds
nlp.setInitialBound('x',     0);            % x1 == 0
nlp.setInitialBound('y',     1);            % y1 == 1

nlp.setParameter('time',  FINALTIME);

% Create solver
solver = Solver.getSolver(nlp,options);

% Get and set initial guess
initialGuess = nlp.getInitialGuess;
initialGuess.states.x.set(-0.2);

% Run solver to obtain solution
[solution,times] = solver.solve(initialGuess);

times = times.value;

figure
hold on 
plot(times,solution.states.x.value,'-.')
plot(times,solution.states.y.value,'--k')
stairs(times(1:end-1),solution.controls.u.value,'r')
xlabel('time')
legend({'x','y','u'})
