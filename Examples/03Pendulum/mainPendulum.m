% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Copyright 2015-2018 Jonas Koennemanm, Giovanni Licitra
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
function [vars,times,solver] = mainPendulum

  options = ocl.Options;
  options.nlp.controlIntervals = 50;

  s = PendulumSystem;
  system = ocl.System(s.varsfun, s.eqfun, s.icfun, 'cbsetupfun', s.simcallbacksetup, 'cbfun', s.simcallback);
  ocp = ocl.OCP(@pathcosts);

  solver = ocl.Solver([], system, ocp, options);

  solver.setBounds('time',  0, 15);
  
  solver.setBounds('p',       -[3;3], [3;3]);
  solver.setBounds('v',       -[3;3], [3;3]);
  solver.setBounds('F',       -25, 25);
  solver.setBounds('lambda',  -50, 50);
  solver.setBounds('m',       1);
  solver.setBounds('l',       1);

  solver.setInitialBounds('p', [0;-1],[0;-1]);
  solver.setInitialBounds('v', [0.5;0]);
  
  solver.setInitialBounds('time', 0);

  solver.setEndBounds('p',     [0,1]);
  solver.setEndBounds('v',     [-1;-1], [1;1]);

  vars = solver.getInitialGuess();
  vars.states.p.set([0;-1]);
  vars.states.v.set([0.1;0]);
  vars.controls.F.set(-10);

  [solution,times] = solver.solve(vars);

  figure
  solver.solutionCallback(times,solution);

end

function pathcosts(ch,~,~,controls,~,~,~)
  F  = controls.F;
  ch.add( 1e-3 * F^2 );
end
