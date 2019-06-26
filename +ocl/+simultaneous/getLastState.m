function x = getLastState(stage,stageVars)
[X_indizes, ~, ~, ~, ~] = Simultaneous.getStageIndizes(stage);
x = stageVars(X_indizes(:,end));