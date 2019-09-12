% Problem formulation from
%   BOCOP - A collection of examples
%   Frederic Bonnans, Pierre MartinonD. Giorgi, V. Grelard, B. Heymann, J. Liu, S. Maindrault, O. Tissot
%   https://files.inria.fr/bocop/Examples-BOCOP.pdf
%
% TBV
%
function fuller

  problem = ocl.Problem(3.5, ...
    @vars, ...
    @dynamics, ...
    @pathcosts, ...
    'N', 200, 'd', 2);
  
  problem.setInitialState('s', 0)
  problem.setInitialState('sd', 1)
  
  problem.setEndBounds('s', 0);
  problem.setEndBounds('sd', 0);
  
  [sol, times] = problem.solve();
  
  figure;
  ocl.stairs(times.controls, sol.controls);
end


function vars(vh)

  vh.addState('s')
  vh.addState('sd');
  
  vh.addControl('u', 'lb', -1, 'ub', 1);

end

function dynamics(odeh, x, z, u, p)

  odeh.setODE('s', x.sd);
  odeh.setODE('sd', u);

end

function pathcosts(ch, x, z, u, p)

  ch.add(x.s^2);

end