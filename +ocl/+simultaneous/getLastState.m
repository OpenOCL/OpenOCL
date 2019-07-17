function x = getLastState(stage,colloc,stageVars)
N = stage.N;
nx = stage.nx;
ni = colloc.num_i;
nu = stage.nu;
np = stage.np;

[X_indizes, ~, ~, ~, ~] = ocl.simultaneous.indizes(N, nx, ni, nu, np);
x = stageVars(X_indizes(:,end));