% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Copyright 2015-2018 Jonas Koennemanm, Giovanni Licitra
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%

function [solution,times,solver] = mainVanDerPol

  END_TIME = 10;              % horizon length (seconds)
  CONTROL_INTERVALS = 30;     % control discretization

  % Get and set solver options
  options = ocl.Options();
  options.nlp.controlIntervals = CONTROL_INTERVALS;
  options.nlp.collocationOrder = 3;
  options.nlp.ipopt.linear_solver = 'mumps';
  options.nlp.solver = 'ipopt';

  system = ocl.System(@varsfun,@eqfun);
  ocp = ocl.OCP(@pathcosts);

  solver = ocl.Solver(END_TIME,system,ocp,options);

  % intial state bounds
  solver.setInitialBounds('x',     0);
  solver.setInitialBounds('y',     1);

  % Get and set initial guess
  initialGuess = solver.getInitialGuess();
  initialGuess.states.x.set(-0.2);

  % Run solver to obtain solution
  [solution,times] = solver.solve(initialGuess);

  % plot solution
  figure
  hold on
  plot(times.states.value,solution.states.x.value,'-.','LineWidth',2)
  plot(times.states.value,solution.states.y.value,'--k','LineWidth',2)
  stairs(times.controls.value,solution.controls.F.value,'r','LineWidth',2)
  xlabel('time')
  legend({'x','y','u'})

end

function varsfun(sh)
  % sysVars(systemHandler)
  %   Define system variables

  % Scalar x:  -0.25 <= x <= inf
  % Scalar y: unbounded
  sh.addState('x', 'lb', -0.25, 'ub', inf);
  sh.addState('y');

  % Scalar u: -1 <= F <= 1
  sh.addControl('F', 'lb', -1, 'ub', 1);
end

function eqfun(sh,x,~,u,~)
  % sysEq(systemHandler,states,algVars,controls,parameters)
  %   Defines differential equations
  sh.setODE('x',(1-x.y^2)*x.x - x.y + u.F);
  sh.setODE('y',x.x);
end

function pathcosts(ch,x,~,u,p)
  % pathCosts(costHandler,states,algVars,controls,time,endTime,parameters)
  %   Defines lagrange (intermediate) cost terms.
  ch.add( x.x^2 );
  ch.add( x.y^2 );
  ch.add( u.F^2 );
end
