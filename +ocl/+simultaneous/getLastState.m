function x = getLastState(stage,stageVars)
[X_indizes, ~, ~, ~, ~] = ocl.simultaneous.getStageIndizes(stage);
x = stageVars(X_indizes(:,end));