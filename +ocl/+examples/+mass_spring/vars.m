function vars(h, num_masses)
h.addState('x', [2*num_masses 1]);
h.addControl('u', [num_masses-1 1]);