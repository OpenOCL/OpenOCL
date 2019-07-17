% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Copyright 2015-2018 Jonas Koennemanm, Giovanni Licitra
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
function [vars,times,solver] = pendulum

  solver = ocl.Solver([], ...
                      @ocl.examples.pendulum.varsfun, ...
                      @ocl.examples.pendulum.daefun, ...
                      @pathcosts, @gridcosts, ...
                      'N', 40);
  
  solver.setBounds('time', 0, 15);
  
  solver.setBounds('p',       -[1;1], [1;1]);
  solver.setBounds('v',       -[3;3], [3;3]);
  solver.setBounds('F',       -25, 25);
  solver.setBounds('lambda',  -50, 50);
  solver.setBounds('m',       1);
  solver.setBounds('l',       1);

  solver.setInitialBounds('time', 0);
  solver.setInitialBounds('p', [0;-1],[0;-1]);
  solver.setInitialBounds('v', [0.5;0]);

  solver.setEndBounds('p',     [0,1]);
  solver.setEndBounds('v',     [-1;-1], [1;1]);

  vars = solver.getInitialGuess();
  vars.states.p.set([0;-1]);
  vars.states.v.set([0.1;0]);
  vars.controls.F.set(-10);

  [solution,times] = solver.solve(vars);

  figure
  solver.solutionCallback(times,solution);

  snapnow;
end

function gridcosts(ch,k,K,x,~)
  if k==K
    ch.add(1e-6*x.time);
  end
end

function pathcosts(ch,~,~,controls,~)
  F  = controls.F;
  ch.add( F^2 );
end
