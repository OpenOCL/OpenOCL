function ig_stage = getInitialGuessWithUserData(stage, ig_data)

ig_values = ocl.simultaneous.getInitialGuess(stage);
varsStruct = ocl.simultaneous.variables(stage);
ig_stage = Variable.create(varsStruct, ig_values);

% incoorperate user input ig data for state trajectories
names = fieldnames(ig_data.data);
for k=1:length(names)
  id = names{k};
  
  xdata = ig_data.data.(id).x;
  ydata = ig_data.data.(id).y;
  
  % state trajectories
  xtarget = ocl.simultaneous.normalizedStateTimes(stage);
  ytarget = interp1(xdata,ydata,xtarget,'linear','extrap');
  
  ocl.types.variable.setFromNdMatrix(ig_stage.states.get(id), ytarget);
  
  xtarget = ocl.simultaneous.normalizedIntegratorTimes(stage);
  ytarget = interp1(xdata,ydata,xtarget,'linear','extrap');
  
  ocl.types.variable.setFromNdMatrix(ig_stage.integrator.states.get(id), ytarget);
  
end