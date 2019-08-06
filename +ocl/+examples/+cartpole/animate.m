function handles = animate(sol,times)

global testRun

pmax = max(abs(sol.states.p.value));

states = sol.states.value;
times = times.states.value;
times = times(:);

x = states(:,1);
p = x(1);
theta = x(2);
l = 0.8;

handles = ocl.examples.cartpole.draw_prepare(p, theta, l, pmax);

for k=2:length(times)
  t = times(k);
  x = states(:,k);
  dt = t-times(k-1);

  ocl.examples.cartpole.draw(handles, t, x, l);

  if isempty(testRun) || (testRun==false)
    pause(dt);
  end
end
