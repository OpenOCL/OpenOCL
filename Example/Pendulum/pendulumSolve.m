StartupOC

% set up parameters
parameters = Var('parameters');
parameters.add('m',[1 1]);
parameters.add('l',[1 1]);

% Create model and OCP
model = PendulumModel(parameters);
ocp = PendulumOCP(model);

% Get and set solver options
options = Solver.getOptions;
options.nlp.scaling = false;
nlp = Solver.getNLP(ocp,model,options);

% state bounds
nlp.setBound('p',     ':',   -[2;2], [3;3]); 
nlp.setBound('v',     ':',   -[2;2], [3;3]); 
nlp.setBound('F',     ':',   -20, 20); 
nlp.setBound('lambda',':',   -50, 50); 
nlp.setBound('time',  ':',   1, 10);
nlp.setBound('m',     ':',   1);
nlp.setBound('l',     ':',   1);

nlp.setBound('p', 1, [-inf;-1],[inf,-1]);
nlp.setBound('v', 1, [0.5;0]);

% Create solver
solver = Solver.getSolver(nlp,options);

% Get and set initial guess
initialGuess = nlp.getInitialGuess;
initialGuess.get('state').get('p').set([0;-1]);
initialGuess.get('state').get('v').set([0.1;0]);
initialGuess.get('controls').get('F').set(-10);

nlp.interpolateGuess(initialGuess);

% Run solver to obtain solution
solution = solver.solve(initialGuess);

% run model callback for the solution
figure
model.solutionCallback(solution);
