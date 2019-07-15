function x = getLastState(stage,stageVars)
N = stage.N;
nx = stage.nx;
ni = stage.ni;
nu = stage.nu;
np = stage.np;

[X_indizes, ~, ~, ~, ~] = ocl.simultaneous.indizes(N, nx, ni, nu, np);
x = stageVars(X_indizes(:,end));