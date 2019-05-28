function [sol,times,ocl] = mainBouncingBall  

  options = OclOptions();
  options.nlp.controlIntervals = 40;
  options.nlp.collocationOrder = 2;
  
  before_contact = OclPhase([], @before_contact_vars, @before_contact_ode);
  after_contact = OclPhase(0.452, @after_contact_vars, @after_contact_ode, @after_contact_cost);

  before_contact.setInitialStateBounds('s', 1);
  before_contact.setInitialStateBounds('v', 0);
  before_contact.setEndStateBounds('s', 1);
  
  after_contact.setEndStateBounds('s', 1);
  after_contact.setEndStateBounds('v', 1);
  
  ocl = OclSolver({before_contact, after_contact}, {@phase_transition}, options);

  % Run solver to obtain solution
  [sol,times] = ocl.solve(ocl.getInitialGuess());

  % visualize solution
  figure; hold on; grid on;
  oclStairs(times.controls, sol.controls.F/10.)
  xlabel('time [s]');
  oclPlot(times.states, sol.states.p)
  xlabel('time [s]');
  oclPlot(times.states, sol.states.v)
  xlabel('time [s]');
  oclPlot(times.states, sol.states.theta)
  legend({'force [10*N]','position [m]','velocity [m/s]','theta [rad]'})
  xlabel('time [s]');

  animateCartPole(sol,times);

end

function before_contact_vars(sh)
  sh.addState('s', 'lb', 0, 'ub', 1);
  sh.addState('v');
end

function before_contact_ode(sh,x,~,u,~)
  sh.setODE('s', x.v);
  sh.setODE('v', -9.81);
end

function after_contact_vars(sh)
  sh.addState('s', 'lb', 0, 'ub', 1);
  sh.addState('v');
  sh.addState('iF');
  
  sh.addControl('F');
end

function after_contact_ode(sh,x,~,u,~)
  sh.setODE('s', x.v);
  sh.setODE('v', -9.81 + u.F);
  sh.setODE('iF', u.F^2);
end

function after_contact_cost(self,k,K,x,~)
  if k == K
    self.add( x.iF );
  end
end

function phase_transition(ch, x0, xF)
  ch.add(x0.s, '==', xF.s);
  ch.add(x0.v, '==', -xF.v / 2);
  ch.add(x0.iF, '==', 0);
end


