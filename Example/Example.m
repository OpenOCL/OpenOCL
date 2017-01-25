function Example

StartupOC

FINALTIME = 10;               % horizon length (seconds)
DISCRETIZATIONPOINTS = 30;    % horizon discretization

% Create model and OCP
model = ExampleModel;
ocp = ExampleOCP(model);

% Get and set solver options
options = Solver.getOptions;
options.iterationCallback = false;
options.nlp.discretizationPoints = DISCRETIZATIONPOINTS;
options.nlp.collocationOrder = 3;
options.nlp.ipopt.linear_solver = 'mumps';

nlp = Solver.getNLP(ocp,model,options);
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

% Create solver
solver = Solver.getSolver(nlp,options);

% Get and set initial guess
initialGuess = nlp.getInitialGuess;
initialGuess.get('state').get('x').set(-0.2);

% Run solver to obtain solution
solution = solver.solve(initialGuess);



times = 0:FINALTIME/DISCRETIZATIONPOINTS:FINALTIME;

figure
hold on 
plot(times,solution.get('state').get('x').value,'-.')
plot(times,solution.get('state').get('y').value,'--k')
stairs(times(1:end-1),solution.get('controls').get('u').value,'r')
xlabel('time')
legend({'x','y','u'})
