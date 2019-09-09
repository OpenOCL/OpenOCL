function [sol,times,ocp] = bouncingball  
  
  before_contact = ocl.Stage([], @before_contact_vars, @before_contact_ode, 'N', 3, 'd', 2);
  after_contact = ocl.Stage(1, @after_contact_vars, @after_contact_ode, ...
                            @after_contact_cost, 'N', 5, 'd', 2);

  before_contact.setInitialStateBounds('s', 1);
  before_contact.setInitialStateBounds('v', 0);
  before_contact.setEndStateBounds('s', 0);
  
  after_contact.setEndStateBounds('s', 1);

  ocp = ocl.MultiStageProblem({before_contact, after_contact}, {@stage_transition});

  [sol,times] = ocp.solve(ocp.getInitialGuess());

  % stage 1
  figure; 
  subplot(1,2,1)
  hold on; grid on;
  ocl.plot(times{1}.states, sol{1}.states.s)
  ocl.plot(times{1}.states, sol{1}.states.v)
  legend({'s','v'})
  xlabel('time [s]');
  ylim([-5 3])
  yticks(-5:3)
  title('stage 1')
  
  % stage 2
  subplot(1,2,2)
  hold on; grid on;
  ocl.plot(times{2}.states, sol{2}.states.s)
  ocl.plot(times{2}.states, sol{2}.states.v)
  ocl.stairs(times{2}.controls, sol{2}.controls.F)
  legend({'s','v','F'})
  xlabel('time [s]');
  ylim([-5 3])
  yticks(-5:3)
  title('stage 2')

end

function before_contact_vars(sh)
  sh.addState('s');
  sh.addState('v');
end

function before_contact_ode(sh,x,~,~,~)  
  sh.setODE('s', x.v);
  sh.setODE('v', -10);
end

function after_contact_vars(sh)
  sh.addState('s');
  sh.addState('v');
  sh.addControl('F');
end

function after_contact_ode(sh,x,~,u,~)
  sh.setODE('s', x.v);
  sh.setODE('v', -10 + 10*u.F);
end

function after_contact_cost(ch,~,~,u,~)
  ch.add( u.F^2 );
end

function stage_transition(ch, x0, xF)
  % x0 current stage
  % xF previous stage
  ch.add(x0.s, '==', xF.s);
  ch.add(x0.v, '==', -xF.v/2);
end


