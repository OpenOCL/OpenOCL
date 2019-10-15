% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Copyright 2015-2018 Jonas Koennemanm, Giovanni Licitra
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
function [solution,times,problem] = vanderpol

  problem = ocl.Problem(10, @varsfun, @daefun, @pathcosts, 'N', 30);

  % intial state bounds
  problem.setInitialBounds('x',     0);
  problem.setInitialBounds('y',     1);

  % Get and set initial guess
  initialGuess = problem.getInitialGuess();
  initialGuess.states.x.set(-0.2);

  % Run solver to obtain solution
  [solution,times] = problem.solve(initialGuess);

  % plot solution
  figure
  hold on
  plot(times.states.value,solution.states.x.value,'-.','LineWidth',2)
  plot(times.states.value,solution.states.y.value,'--k','LineWidth',2)
  stairs(times.controls.value,solution.controls.F.value,'r','LineWidth',2)
  xlabel('time')
  legend({'x','y','u'})

  snapnow;
end

function varsfun(svh)
  % Scalar x:  -0.25 <= x <= inf
  % Scalar y: unbounded
  svh.addState('x', 'lb', -0.25, 'ub', inf);
  svh.addState('y');

  % Scalar u: -1 <= F <= 1
  svh.addControl('F', 'lb', -1, 'ub', 1);
end

function daefun(daeh,x,~,u,~)
  daeh.setODE('x', (1-x.y^2)*x.x - x.y + u.F);
  daeh.setODE('y', x.x);
end

function pathcosts(ch,x,~,u,~)
  ch.add( x.x^2 );
  ch.add( x.y^2 );
  ch.add( u.F^2 );
end
