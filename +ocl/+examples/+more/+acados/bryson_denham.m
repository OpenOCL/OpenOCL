% Problem formulation from
%   http://www.gpops2.com/Examples/Bryson-Denham.html
%
function bryson_denham

  problem = ocl.acados.Solver(1, ...
    @vars, ...
    @dynamics, ...
    @pathcosts, ...
    'gridconstraints', @gridconstraints, ...
    'N', 100, 'd', 2);
  
  problem.setInitialState('x', 0);
  problem.setInitialState('v', 1);
  
  [sol, times] = problem.solve();
  
  figure; 
  subplot(1,2,1); hold on;
  ocl.plot(times.states, sol.states.x);
  ocl.plot(times.states, sol.states.v);
  legend({'x', 'v'})
  xlabel('time');
  
  subplot(1,2,2)
  ocl.stairs(times.controls, sol.controls.u);
  ylabel('u')
  xlabel('time');

end

function vars(vh)

  vh.addState('x', 'ub', 1/9);
  vh.addState('v');
  
  vh.addControl('u');

end

function dynamics(dh, x, z, u, p)

  dh.setODE('x', x.v);
  dh.setODE('v', u);

end

function pathcosts(ch, x, z, u, p)

  ch.add(u^2);

end

function gridconstraints(ch, k, K, x, p)

  if k==K
    ch.add(x.x, '==', 0);
    ch.add(x.v, '==', -1);
  end

end