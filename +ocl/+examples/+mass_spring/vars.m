function vars(h, num_masses)

lbx = horzcat(-4*ones(1,num_masses), -inf*ones(1,num_masses));
ubx = horzcat(4*ones(1,num_masses), inf*ones(1,num_masses));

h.addState('x', [2*num_masses 1], 'lb', lbx, 'ub', ubx);
h.addControl('u', [num_masses-1 1], 'lb', -0.5, 'ub', 0.5);