% Problem formulation from
%   http://www.gpops2.com/Examples/Brachistochrone.html
%
% Slightly changed so that ball rolls down, limits on slope angle control
% to be +-90 degree. 0 degree means no slope. Positive velocity constraint.
%
function brachistochrone

  problem = ocl.Problem([], ...
    @vars, ...
    @dynamics, ...
    'terminalcost', @terminalcost, ...
    'N', 200, 'd', 3);
  
  problem.setInitialState('time', 0);
  
  problem.setInitialState('x', 0);
  problem.setInitialState('y', 0);
  problem.setInitialState('v', 0);
  
  problem.setEndBounds('x', 2);
  problem.setEndBounds('y', -2);
  
  ig = problem.ig();
  ig.controls.set(1);
  
  [sol, times] = problem.solve(ig);
  
  figure;
  subplot(2,1,1);
  ocl.plot(times.controls, sol.controls.u);
  xlabel('time')
  ylabel('slope')
  subplot(2,1,2);
  ocl.plot(sol.states.x, sol.states.y)
  xlabel('x')
  ylabel('y')

end

function vars(vh)

  vh.addState('x');
  vh.addState('y');
  vh.addState('v', 'lb', 0);
  
  vh.addState('time');
  
  vh.addControl('u', 'lb', -pi/2, 'ub', pi/2);

end

function dynamics(dh, x, z, u, p)

  g = 9.81;

  dh.setODE('x', x.v * cos(u));
  dh.setODE('y', x.v * sin(u));
  dh.setODE('v', -g * sin(u));

  dh.setODE('time', 1);
  
end

function terminalcost(ch, x, p)

  ch.add(x.time);

end