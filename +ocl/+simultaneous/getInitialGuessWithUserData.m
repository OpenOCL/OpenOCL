function ig_stage = getInitialGuessWithUserData(stage, ig_data)

ig_values = Simultaneous.getInitialGuess(stage);
varsStruct = Simultaneous.vars(stage);
ig_stage = Variable.create(varsStruct, ig_values);

% incoorperate user input ig data for state trajectories
names = fieldnames(ig_data.data);
for k=1:length(names)
  id = names{k};
  
  xdata = ig_data.data.(id).x;
  ydata = ig_data.data.(id).y;
  
  % state trajectories
  xtarget = Simultaneous.normalized_state_times(stage);
  ytarget = interp1(xdata,ydata',xtarget,'linear','extrap');
  
  ig_stage.states.get(id).set(ytarget');
  
  xtarget = Simultaneous.normalized_integrator_times(stage);
  ytarget = interp1(xdata,ydata',xtarget,'linear','extrap');
  
  ig_stage.integrator.states.get(id).set(ytarget');
  
end