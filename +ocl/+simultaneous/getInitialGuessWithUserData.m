function ig_stage = getInitialGuessWithUserData(ig_stage, stage, colloc)

H_norm = stage.H_norm;
nt = colloc.num_t;

x_guess = stage.x_guess.data;

x_times = [0, cumsum(H_norm)]';

colloc_times = zeros(nt, length(H_norm));
time = 0;
for k=1:length(H_norm)
  h = H_norm(k);
  colloc_times(:,k) = time + ocl.collocation.times(colloc.tau_root, h);
  time = time + H_norm(k);
end
colloc_times = colloc_times(:);

% incoorperate user input ig data for state trajectories
names = fieldnames(x_guess);
for k=1:length(names)
  id = names{k};
  
  xdata = x_guess.(id).x;
  ydata = x_guess.(id).y;
  
  % state trajectories
  ytarget = interp1(xdata, ydata, x_times,'linear','extrap');
  ig_stage.states.get(id).set(ytarget');
  
  % integrator states
  ytarget = interp1(xdata, ydata, colloc_times,'linear','extrap');
  ig_stage.integrator.states.get(id).set(ytarget')
  
end

u_guess = stage.u_guess.data;

u_times = cumsum(H_norm)';

% incoorperate user input ig data for control trajectories
names = fieldnames(u_guess);
for k=1:length(names)
  id = names{k};
  
  xdata = u_guess.(id).x;
  ydata = u_guess.(id).y;
  
  % control trajectories
  ytarget = interp1(xdata, ydata, u_times,'linear','extrap');
  ig_stage.controls.get(id).set(ytarget');
  
end