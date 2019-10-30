function stage_bounds

before_contact = ocl.Stage([], @before_contact_vars, @before_contact_ode, 'N', 3, 'd', 2);
after_contact = ocl.Stage(1, @after_contact_vars, @after_contact_ode, ...
  @after_contact_cost, 'N', 5, 'd', 2);

before_contact.setInitialBounds('s', 1);
before_contact.setInitialBounds('v', 0);
before_contact.setEndBounds('s', 0);

after_contact.setBounds('s', 0, 2);

after_contact.setEndBounds('s', 1);

ocp = ocl.MultiStageProblem({before_contact, after_contact}, {@stage_transition});

[sol,times] = ocp.solve(ocp.getInitialGuess());

stage_1 = sol{1}.states(:,[1,end]).value;
ocl.utils.assertAlmostEqual(stage_1, [1 0;0 -4.47214], 'Feature test bouncing ball failed.');

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

function after_contact_ode(dh,x,~,u,~)
dh.setODE('s', x.v);
dh.setODE('v', -10 + 10*u.F);

ocl.utils.assert(isempty(dh.userdata()));
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


