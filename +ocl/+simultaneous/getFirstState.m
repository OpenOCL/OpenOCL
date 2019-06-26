function x = getFirstState(stage,stageVars)
[X_indizes, ~, ~, ~, ~] = Simultaneous.getStageIndizes(stage);
x = stageVars(X_indizes(:,1));