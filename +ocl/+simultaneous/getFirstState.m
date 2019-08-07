function x = getFirstState(stage, colloc, stage_vars)

N = stage.N;
nx = stage.nx;
ni = colloc.num_i;
nu = stage.nu;
np = stage.np;

[X_indizes, ~, ~, ~, ~] = ocl.simultaneous.indizes(N, nx, ni, nu, np);
x = stage_vars(X_indizes(:,1));