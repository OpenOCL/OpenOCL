function [x,p] = getLastState(stage,colloc,stageVars)
N = stage.N;
nx = stage.nx;
ni = colloc.num_i;
nu = stage.nu;
np = stage.np;

[X_indizes, ~, ~, P_indizes, ~] = ocl.simultaneous.indizes(N, nx, ni, nu, np);
x = stageVars(X_indizes(:,end));
p = stageVars(P_indizes(:,end));

