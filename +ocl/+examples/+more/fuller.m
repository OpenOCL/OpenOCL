% Problem formulation from
%   https://mintoc.de/index.php/Fuller%27s_problem
%
function fuller

  problem = ocl.Problem(1, ...
    @vars, ...
    @dynamics, ...
    @pathcosts, ...
    'N', 50, 'd', 2);
  
  problem.setInitialState('x1', 0.01)
  problem.setInitialState('x2', 0)
  
  problem.setEndBounds('x1', 0.01);
  problem.setEndBounds('x2', 0);
  
  [sol, times] = problem.solve();
  
  figure;
  subplot(3,1,1);
  ocl.plot(times.states, sol.states.x1);
  ylabel('x1')
  xlim([0 1]);
  subplot(3,1,2);
  ocl.plot(times.states, sol.states.x2);
  ylabel('x2')
  xlim([0 1]);
  subplot(3,1,3);
  ocl.stairs(times.controls, sol.controls);
  ylabel('u')
  xlim([0 1]);
  xlabel('time')
end


function vars(vh)

  vh.addState('x1')
  vh.addState('x2');
  
  vh.addControl('u', 'lb', 0, 'ub', 1);

end

function dynamics(odeh, x, z, u, p)

  odeh.setODE('x1', x.x2);
  odeh.setODE('x2', 1-2*u);

end

function pathcosts(ch, x, z, u, p)

  ch.add(x.x1^2);

end