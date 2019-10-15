% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Copyright 2015-2018 Jonas Koennemanm, Giovanni Licitra
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
function p_vec = pendulum_sim

  conf = struct;
  conf.l = 1;
  conf.m = 1;

  simulator = ocl.Simulator(@ocl.examples.pendulum.varsfun, ...
    @ocl.examples.pendulum.daefun, ...
    @ocl.examples.pendulum.icfun, ...
    'userdata', conf);

  x0 = simulator.getStates();
  x0.p.set([0;conf.l]);
  x0.v.set([-0.5;-1]);

  times = 0:0.1:4;

  figure
  simulator.reset(x0);

  p_vec = zeros(2,length(times));
  p_vec(:,1) = x0.p.value;

  for k=1:length(times)-1

    dt = times(k+1)-times(k);
    [x,~] = simulator.step(10, dt);

    p_vec(:,k+1) = x.p.value;
  end

  ocl.examples.pendulum.animate(conf.l, p_vec, times);
  snapnow;
end
