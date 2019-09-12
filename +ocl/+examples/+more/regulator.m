% Problem formulation from
%   BOCOP - A collection of examples
%   Frederic Bonnans, Pierre Martinon, D. Giorgi, V. Grelard, B. Heymann, J. Liu, S. Maindrault, O. Tissot
%   https://files.inria.fr/bocop/Examples-BOCOP.pdf
%
% Second order singular regulator
%
function regulator

  problem = ocl.Problem(5, ...
    @vars, ...
    @dynamics, ...
    @pathcosts, ...
    'N', 500, 'd', 3);
  
  problem.setInitialState('s', 0);
  problem.setInitialState('sd', 1);
  
  [sol,times] = problem.solve();
  
  figure;
  ocl.plot(times.controls, sol.controls);
  xlabel('Time')
  ylabel('Acceleration')
  title('Second order singular regulator')

end

function vars(vh)

  vh.addState('s');
  vh.addState('sd')

  vh.addControl('u', 'lb', -1, 'ub', 1);
  
end

function dynamics(dh, x, z, u, p)

  dh.setODE('s', x.sd);
  dh.setODE('sd', u);

end

function pathcosts(ch, x, z, u, p)

  ch.add(x.s^2 + x.sd^2);
  
end