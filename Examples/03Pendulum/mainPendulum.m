
options = OclOptions;
ocl = OclSolver(PendulumSystem, PendulumOCP, options);

ocl.setParameter('time',  1, 10);
ocl.setBounds('p',       -[2;2], [3;3]); 
ocl.setBounds('v',       -[2;2], [3;3]); 
ocl.setBounds('F',       -30, 30); 
ocl.setBounds('lambda',  -50, 50); 
ocl.setBounds('m',       1);
ocl.setBounds('l',       1);

ocl.setInitialBounds('p', [-inf;-1],[inf;-1]);
ocl.setInitialBounds('v', [0.5;0]);

ocl.setEndBounds('p',     [0,1]);
ocl.setEndBounds('v',     [-1;-1], [1;1]);

vars = ocl.getInitialGuess();
vars.states.p.set([0;-1]);
vars.states.v.set([0.1;0]);
vars.controls.F.set(-10);

solution = ocl.solve(vars);

figure
system.solutionCallback(solution);
