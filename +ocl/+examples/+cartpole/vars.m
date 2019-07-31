function vars(vh)

vh.addState('p');
vh.addState('theta');
vh.addState('v');
vh.addState('omega');

vh.addControl('F', 'lb', -15, 'ub', 15);

