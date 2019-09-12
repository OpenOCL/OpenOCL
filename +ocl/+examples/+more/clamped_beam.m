% Problem formulation from
%   BOCOP - A collection of examples
%   Frederic Bonnans, Pierre MartinonD. Giorgi, V. Grelard, B. Heymann, J. Liu, S. Maindrault, O. Tissot
%   https://files.inria.fr/bocop/Examples-BOCOP.pdf
%   https://www.bocop.org/clamped-beam/
%
function clamped_beam

  problem = ocl.Problem(1, ...
    @vars, ...
    @dynamics, ...
    @pathcosts, ...
    'N', 100, 'd', 2);
  
  problem.setInitialState('y', 0);
  problem.setInitialState('yd', 1);
  
  problem.setEndBounds('y', 0);
  problem.setEndBounds('yd', -1);
  
  problem.setBounds('y', 0, 0.1)
  
  [sol, times] = problem.solve();
  
  figure;
  title('Clamped Beam')
  subplot(1, 2, 1)
  ocl.plot(times.states, sol.states.y);
  xlabel('t')
  ylabel('y')
  subplot(1, 2, 2)
  ocl.plot(times.controls, sol.controls);
  xlabel('t')
  ylabel('u')
  

end

function vars(vh)

  vh.addState('y');
  vh.addState('yd');
  vh.addControl('u');
  
end

function dynamics(dh, x, z, u, p)

  dh.setODE('y', x.yd);
  dh.setODE('yd', u);

end

function pathcosts(ch, x, z, u, p)

  ch.add(u^2);

end