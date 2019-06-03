function [sol,times,solver] = bouncingball  
  
  before_contact = ocl.Phase([], @before_contact_vars, @before_contact_ode, 'N', 3, 'd', 2);
  after_contact = ocl.Phase(1, @after_contact_vars, @after_contact_ode, ...
                            @after_contact_cost, 'N', 5, 'd', 2);

  before_contact.setInitialStateBounds('s', 1);
  before_contact.setInitialStateBounds('v', 0);
  before_contact.setEndStateBounds('s', 0);
  
  after_contact.setEndStateBounds('s', 1);

  solver = OclSolver({before_contact, after_contact}, {@phase_transition});

  [sol,times] = solver.solve(solver.getInitialGuess());

  disp('Jacobian of the constraints');
  figure
  spy(full(solver.jacobian_pattern(sol)))
  
  % phase 1
  figure; 
  subplot(1,2,1)
  hold on; grid on;
  oclPlot(times{1}.states, sol{1}.states.s)
  oclPlot(times{1}.states, sol{1}.states.v)
  legend({'s','v'})
  xlabel('time [s]');
  ylim([-5 3])
  yticks(-5:3)
  title('phase 1')
  
  % phase 2
  subplot(1,2,2)
  hold on; grid on;
  oclPlot(times{2}.states, sol{2}.states.s)
  oclPlot(times{2}.states, sol{2}.states.v)
  oclStairs(times{2}.states, [sol{2}.controls.F;sol{2}.controls.F(end)])
  legend({'s','v','F'})
  xlabel('time [s]');
  ylim([-5 3])
  yticks(-5:3)
  title('phase 2')

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

function phase_transition(ch, x0, xF)
  % x0 current phase
  % xF previous phase
  ch.add(x0.s, '==', xF.s);
  ch.add(x0.v, '==', -xF.v/2);
end


