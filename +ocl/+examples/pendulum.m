% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Copyright 2015-2018 Jonas Koennemanm, Giovanni Licitra
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
function [ig,times,solver] = pendulum

conf = struct;
conf.l = 1;
conf.m = 1;

solver = ocl.Solver([], ...
  @ocl.examples.pendulum.varsfun, ...
  @(h,x,z,u,p) ocl.examples.pendulum.daefun(h,x,z,u,conf), ...
  @ocl.examples.pendulum.pathcosts, ...
  @ocl.examples.pendulum.gridcosts, ...
  'N', 100);

solver.setBounds('time', 0, 15);

solver.setBounds('v',       -[3;3], [3;3]);
solver.setBounds('F',       -40, 40);

solver.setInitialBounds('time', 0);
solver.setInitialBounds('p', [0; -conf.l]);
solver.setInitialBounds('v', [0.5;0]);

solver.setEndBounds('p',     [0,0], [0,inf]);
solver.setEndBounds('v',     [-1;-1], [1;1]);

ig = solver.getInitialGuess();
ig.states.p.set([0;-1]);
ig.states.v.set([0.1;0]);
ig.controls.F.set(-10);

[solution,times] = solver.solve(ig);

ocl.examples.pendulum.animate(conf.l, solution.states.p.value, times.value);

snapnow;
