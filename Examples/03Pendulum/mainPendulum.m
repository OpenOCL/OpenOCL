function [vars,times,ocl] = mainPendulum

  options = OclOptions;
  options.nlp.controlIntervals = 50;

  s = PendulumSystem;
  system = OclSystem(s.varsfun, s.eqfun, s.icfun, 'cbfun', s.simcallback);
  ocp = OclOCP(@pathcosts);

  ocl = OclSolver([], system, ocp, options);

  ocl.setBounds('time',  0, 15);
  
  ocl.setBounds('p',       -[3;3], [3;3]);
  ocl.setBounds('v',       -[3;3], [3;3]);
  ocl.setBounds('F',       -25, 25);
  ocl.setBounds('lambda',  -50, 50);
  ocl.setBounds('m',       1);
  ocl.setBounds('l',       1);

  ocl.setInitialBounds('p', [0;-1],[0;-1]);
  ocl.setInitialBounds('v', [0.5;0]);
  
  ocl.setInitialBounds('time', 0);

  ocl.setEndBounds('p',     [0,1]);
  ocl.setEndBounds('v',     [-1;-1], [1;1]);

  vars = ocl.getInitialGuess();
  vars.states.p.set([0;-1]);
  vars.states.v.set([0.1;0]);
  vars.controls.F.set(-10);

  [solution,times] = ocl.solve(vars);

  ocl.solutionCallback(times,solution);

end

function pathcosts(ch,~,~,controls,~,~,~)
  F  = controls.F;
  ch.add( 1e-3 * F^2 );
end
