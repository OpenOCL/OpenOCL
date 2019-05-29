function [sol,times,ocl] = mainBouncingBall  

  options = OclOptions();
  options.nlp.controlIntervals = 20;
  options.nlp.collocationOrder = 3;
  
  before_contact = OclPhase(0.452, @before_contact_vars, @before_contact_ode);
  after_contact = OclPhase(0.452, @after_contact_vars, @after_contact_ode, @after_contact_cost);

  before_contact.setInitialStateBounds('s', 1);
  before_contact.setInitialStateBounds('v', 0);
  before_contact.setEndStateBounds('s', 0);
  
  after_contact.setEndStateBounds('s', 1);
  after_contact.setEndStateBounds('v', 0);
  
  ocl = OclSolver({before_contact, after_contact}, {@phase_transition}, options);

  % Run solver to obtain solution
  [sol,times] = ocl.solve(ocl.getInitialGuess());

  % phase 1
  figure; hold on; grid on;
  oclPlot(times{1}.states, sol{1}.states.s)
  oclPlot(times{1}.states, sol{1}.states.v)
  legend({'s','v'})
  xlabel('time [s]');
  
  % phase 2
  figure; hold on; grid on;
  oclStairs(times{2}.controls, sol{2}.controls.F*100)
  xlabel('time [s]');
  oclPlot(times{2}.states, sol{2}.states.s)
  xlabel('time [s]');
  oclPlot(times{2}.states, sol{2}.states.v)
  xlabel('time [s]');
  legend({'F','s','v'})
  xlabel('time [s]');

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
  % x0 current phase
  % xF previous phase
  ch.add(x0.s, '==', xF.s);
  ch.add(x0.v, '==', -xF.v);
  ch.add(x0.iF, '==', 0);
end


