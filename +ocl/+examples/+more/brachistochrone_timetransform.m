% Problem formulation from
%   http://www.gpops2.com/Examples/Brachistochrone.html
%
function brachistochrone_timetransform

  problem = ocl.Problem(1, ...
    @vars, ...
    @dynamics, ...
    'terminalcost', @terminalcost, ...
    'N', 200, 'd', 2);
  
  problem.setInitialState('x', 0);
  problem.setInitialState('y', 0);
  problem.setInitialState('v', 0);
  
  problem.setEndBounds('x', 2);
  problem.setEndBounds('y', -2);
  
  ig = problem.ig();
  ig.controls.set(1);
  ig.states.T.set(1);
  
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
  
  vh.addState('T', 'lb', 0);
  
  vh.addControl('u', 'lb', -pi/2, 'ub', pi/2);

end

function dynamics(dh, x, z, u, p)

  g = 9.81;

  dh.setODE('x', x.T * x.v * cos(u));
  dh.setODE('y', x.T * x.v * sin(u));
  dh.setODE('v', -x.T * g * sin(u));

  dh.setODE('T', 0);
  
end

function terminalcost(ch, x, p)

  ch.add(x.T);

end

