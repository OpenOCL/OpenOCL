function x = getFirstState(stage,stageVars)
[X_indizes, ~, ~, ~, ~] = ocl.simultaneous.getStageIndizes(stage);
x = stageVars(X_indizes(:,1));