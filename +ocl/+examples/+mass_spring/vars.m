function vars(h, num_masses)
h.addState('x', [2*num_masses 1], 'lb', -4, 'ub', 4);
h.addControl('u', [num_masses-1 1], 'lb', -0.5, 'ub', 0.5);