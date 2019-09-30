% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Copyright 2015-2018 Jonas Koennemanm, Giovanni Licitra
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
function [ig,times,ocp] = pendulum

conf = struct;
conf.l = 1;
conf.m = 1;

ocp = ocl.Problem([], ...
  @ocl.examples.pendulum.varsfun, ...
  @(h,x,z,u,p) ocl.examples.pendulum.daefun(h,x,z,u,conf), ...
  @ocl.examples.pendulum.pathcosts, ...
  @ocl.examples.pendulum.gridcosts, ...
  'N', 100);

ocp.setBounds('time', 0, 15);

ocp.setBounds('v',       -[3;3], [3;3]);
ocp.setBounds('F',       -40, 40);

ocp.setInitialBounds('time', 0);
ocp.setInitialBounds('p', [0; -conf.l]);
ocp.setInitialBounds('v', [0.5;0]);

ocp.setEndBounds('p',     [0;0], [0;inf]);
ocp.setEndBounds('v',     [-1;-1], [1;1]);

ig = ocp.getInitialGuess();
ig.states.p.set([0;-1]);
ig.states.v.set([0.1;0]);
ig.controls.F.set(-10);

[solution,times] = ocp.solve(ig);

ocl.examples.pendulum.animate(conf.l, solution.states.p.value, times.value);

snapnow;
