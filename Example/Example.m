StartupOC

FINALTIME = 10;               % horizon length (seconds)
CONTROL_INTERVALS = 30;    % horizon discretization

% Create system and OCP
system = ExampleSystem;
ocp = ExampleOCP(system);

% Get and set solver options
options = Solver.getOptions;
options.iterationCallback = false;
options.nlp.controlIntervals = CONTROL_INTERVALS;
options.nlp.collocationOrder = 3;
options.nlp.ipopt.linear_solver = 'mumps';
options.nlp.solver = 'ipopt';
options.nlp.scaling = true;
options.nlp.detectParameters = true;

nlp = Solver.getNLP(ocp,system,options);

%
% Define bounds on the state, control, and algebraic variables.
% Set bound either on all (':'), the first (1), or last ('end')
% time interval along the horizon.

% state bounds
nlp.setBound('x',    ':',   -0.25, inf);   % -0.25 <= x <= inf
nlp.setBound('u',    ':',   -1,    1);     % -1    <= u <= 1

% intial state bounds
nlp.setBound('x',     1,    0);            % x1 == 0
nlp.setBound('y',     1,    1);            % y1 == 1

nlp.setBound('time',  ':',  FINALTIME);

nlp.setScaling('x', ':', -0.25, 1);
nlp.setScaling('y', ':', -1, 1);
nlp.setScaling('z', ':', -1*ones(3,1),ones(3,1));


% Create solver
solver = Solver.getSolver(nlp,options);

% Get and set initial guess
initialGuess = nlp.getInitialGuess;
initialGuess.get('state').get('x').set(-0.2);

% Run solver to obtain solution
[solution,times] = solver.solve(initialGuess);

figure
hold on 
plot(times,solution.get('state').get('x').value,'-.')
plot(times,solution.get('state').get('y').value,'--k')
stairs(times(1:end-1),solution.get('controls').get('u').value,'r')
xlabel('time')
legend({'x','y','u'})
