StartupOC

FINALTIME = 10;               % horizon length (seconds)
DISCRETIZATIONPOINTS = 30;    % horizon discretization

% Create model and OCP
model = ExampleModel;
ocp = ExampleOCP(model,FINALTIME);

% Get and set solver options
options = Solver.getOptions;
options.iterationCallback = false;
options.nlp.discretizationPoints = DISCRETIZATIONPOINTS;
options.nlp.collocationOrder = 2;
options.nlp.ipopt.linear_solver = 'mumps';

% Create solver
solver = Solver.getSolver(ocp,model,options);

% Get and set initial guess
initialGuess = solver.getInitialGuess;
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
