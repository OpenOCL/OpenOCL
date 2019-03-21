function [solution,times,ocl] = mainVanDerPol

END_TIME = 10;              % horizon length (seconds)
CONTROL_INTERVALS = 30;     % control discretization

% Get and set solver options
options = OclOptions();
options.nlp.controlIntervals = CONTROL_INTERVALS;
options.nlp.collocationOrder = 3;
options.nlp.ipopt.linear_solver = 'mumps';
options.nlp.solver = 'ipopt';

system = OclSystem(@sysVars,@sysEq);
ocp = OclOCP(@pathCosts);

ocl = OclSolver(END_TIME,system,ocp,options);

% intial state bounds
ocl.setInitialBounds('x',     0); 
ocl.setInitialBounds('y',     1); 

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
stairs(times.controls.value,solution.controls.F.value,'r','LineWidth',2)
xlabel('time')
legend({'x','y','u'})
end

function sysVars(sh)
  % sysVars(systemHandler)
  %   Define system variables

  % Scalar x:  -0.25 <= x <= inf
  % Scalar y: unbounded
  sh.addState('x', 'lb', -0.25, 'ub', inf);
  sh.addState('y');

  % Scalar u: -1 <= F <= 1
  sh.addControl('F', 'lb', -1, 'ub', 1);
end

function sysEq(sh,x,~,u,~)     
  % sysEq(systemHandler,states,algVars,controls,parameters) 
  %   Defines differential equations
  sh.setODE('x',(1-x.y^2)*x.x - x.y + u.F); 
  sh.setODE('y',x.x);
end

function pathCosts(ch,x,~,u,p)
  % pathCosts(costHandler,states,algVars,controls,time,endTime,parameters)
  %   Defines lagrange (intermediate) cost terms.
  ch.add( x.x^2 );
  ch.add( x.y^2 );
  ch.add( u.F^2 );
end

