% Problem formulation from
%   BOCOP - A collection of examples
%   Frederic Bonnans, Pierre MartinonD. Giorgi, V. Grelard, B. Heymann, J. Liu, S. Maindrault, O. Tissot
%   https://files.inria.fr/bocop/Examples-BOCOP.pdf
%
% TBV
%
function robbins

  problem = ocl.Problem(10, ...
    @vars, ...
    @dynamics, ...
    @pathcosts, ...
    'N', 100, 'd', 3);

  problem.setInitialState('y', 1);
  problem.setInitialState('yd', -2);
  problem.setInitialState('ydd', 0);
  
  [sol, times] = problem.solve(problem.ig());
  
  figure;
  subplot(2,1,1);
  ocl.plot(times.states, sol.states.y)
  
  subplot(2,1,2)
  ocl.stairs(times.controls, sol.controls);

end

function vars(vh)

  vh.addState('y', 'lb', 0);
  vh.addState('yd');
  vh.addState('ydd');
  
  vh.addControl('u');

end

function dynamics(dh, x, z, u, p)

  dh.setODE('y', x.y);
  dh.setODE('yd', x.yd);
  dh.setODE('ydd', u);

end

function pathcosts(ch, x, z, u, p)

  ch.add(3 * x.y^2 + 0.5 * u^2);

end