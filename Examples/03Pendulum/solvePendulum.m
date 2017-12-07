% Create system and OCP
system = PendulumSystem;
ocp = PendulumOCP(system);

% Get and set solver options
options = Solver.getOptions;
nlp = Solver.getNLP(ocp,system,options);

% set time parameter
nlp.setParameter('time',  1, 10);

% state bounds
nlp.setVariableBound('p',       -[2;2], [3;3]); 
nlp.setVariableBound('v',       -[2;2], [3;3]); 
nlp.setVariableBound('F',       -20, 20); 
nlp.setVariableBound('lambda',  -50, 50); 
nlp.setVariableBound('m',       1);
nlp.setVariableBound('l',       1);

nlp.setInitialBound('p', [-inf;-1],[inf,-1]);
nlp.setInitialBound('v', [0.5;0]);

% Create solver
solver = Solver.getSolver(nlp,options);

% Get and set initial guess
initialGuess = nlp.getInitialGuess;
initialGuess.states.p.set([0;-1]);
initialGuess.states.v.set([0.1;0]);
initialGuess.controls.F.set(-10);

nlp.interpolateGuess(initialGuess);

% Run solver to obtain solution
solution = solver.solve(initialGuess);

% run system callback for the solution
figure
system.solutionCallback(solution);
