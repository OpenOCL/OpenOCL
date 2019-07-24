function vars(sh)

sh.addState('p', 'lb', -5, 'ub', 5);
sh.addState('theta', 'lb', -2*pi, 'ub', 2*pi);
sh.addState('v');
sh.addState('omega');

sh.addState('time', 'lb', 0, 'ub', 10);

sh.addControl('F', 'lb', -12, 'ub', 12);