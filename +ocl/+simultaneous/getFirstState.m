function x = getFirstState(stage, stage_vars)

N = stage.N;
nx = stage.nx;
ni = stage.ni;
nu = stage.nu;
np = stage.np;

[X_indizes, ~, ~, ~, ~] = ocl.simultaneous.indizes(N, nx, ni, nu, np);
x = stage_vars(X_indizes(:,1));