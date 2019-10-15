function vars(vh)

num_masses = vh.userdata.num_masses;

lbx = horzcat(-4*ones(1,num_masses), -inf*ones(1,num_masses)).';
ubx = horzcat(4*ones(1,num_masses), inf*ones(1,num_masses)).';

vh.addState('x', [2*num_masses 1], 'lb', lbx, 'ub', ubx);
vh.addControl('u', [num_masses-1 1], 'lb', -0.5, 'ub', 0.5);