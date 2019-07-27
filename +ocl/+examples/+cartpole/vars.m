function vars(sh)

sh.addState('p', 'lb', -5, 'ub', 5);
sh.addState('theta', 'lb', -2*pi, 'ub', 2*pi);
sh.addState('v');
sh.addState('omega');

sh.addControl('F', 'lb', -60, 'ub', 60);