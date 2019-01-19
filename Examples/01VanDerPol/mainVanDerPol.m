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
system.options.dependent = 1;
ocp = OclOCP(@pathCosts);
ocl = OclSolver([],system,ocp,options);

% intial state bounds
ocl.setInitialBounds('x',     0);            % x1 == 0
ocl.setInitialBounds('y',     1);            % y1 == 1

%ocl.setParameter('time_end', END_TIME);            % y1 == 1
ocl.setEndBounds('time', END_TIME)

% Get and set initial guess
initialGuess = ocl.getInitialGuess();
initialGuess.states.x.set(-0.2);

initialGuess.states.time = linspace(0,10,31);

% Run solver to obtain solution
[solution,times] = ocl.solve(initialGuess);

% plot solution
figure
hold on 
ut = solution.states.time.value;
plot(solution.states.time.value,solution.states.x.value,'-.','LineWidth',2)
plot(solution.states.time.value,solution.states.y.value,'--k','LineWidth',2)
stairs(ut(2:end),solution.controls.u.value,'r','LineWidth',2)
xlabel('time')
legend({'x','y','u'})

  function sysVars(sh)
    % sysVars(systemHandler)
    %   Define system variables

    % Scalar x:  -0.25 <= x <= inf
    % Scalar y: unbounded
    sh.addState('x',1,-0.25,inf);
    sh.addState('y');

    % Scalar u: -1 <= u <= 1
    sh.addControl('u',1,-1,1);
  end

  function sysEq(sh,x,~,u,~)     
    % sysEq(systemHandler,states,algVars,controls,parameters) 
    %   Defines differential equations
    sh.setODE('x',(1-x.y^2)*x.x - x.y + u); 
    sh.setODE('y',x.x);
  end

  function pathCosts(ch,x,~,u,p)
    % pathCosts(costHandler,states,algVars,controls,time,endTime,parameters)
    %   Defines lagrange (intermediate) cost terms.
    ch.addPathCost( x.x^2 );
    ch.addPathCost( x.y^2 );
    ch.addPathCost( u^2 );
  end

end