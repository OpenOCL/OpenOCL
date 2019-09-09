function ig_stage = getInitialGuess(H_norm, T, nx, ni, nu, np, ...
                                    x0_lb, x0_ub, xF_lb, xF_ub, x_lb, x_ub, ...
                                    z_lb, z_ub, u_lb_traj, u_ub_traj, p_lb, p_ub, ...
                                    vi_struct)
% creates an initial guess from the information that we have about
% bounds in the stage

N = length(H_norm);
nv_stage = ocl.simultaneous.nvars(N, nx, ni, nu, np);

[X_indizes, I_indizes, U_indizes, P_indizes, H_indizes] = ocl.simultaneous.indizes(N, nx, ni, nu, np);

ig_stage = 0 * ones(nv_stage,1);

igx0 = ocl.simultaneous.igFromBounds(x0_lb, x0_ub);
igxF = ocl.simultaneous.igFromBounds(xF_lb, xF_ub);

ig_stage(X_indizes(:,1)) = igx0;
ig_stage(X_indizes(:,end)) = igxF;

algVarsGuess = ocl.simultaneous.igFromBounds(z_lb, z_ub);
for m=1:N
  xGuessInterp = igx0 + (m-1)/N.*(igxF-igx0);
  % integrator variables
  ig_stage(I_indizes(:,m)) = ocl.collocation.initialGuess(vi_struct, xGuessInterp, algVarsGuess);
  
  % states
  ig_stage(X_indizes(:,m)) = xGuessInterp;
end

% controls
ig_stage(U_indizes) = ocl.simultaneous.igFromBounds(u_lb_traj, u_ub_traj);

% parameters
for m=1:size(P_indizes,2)
  ig_stage(P_indizes(:,m)) = ocl.simultaneous.igFromBounds(p_lb, p_ub);
end

% timesteps
if isempty(T)
  ig_stage(H_indizes) = 1;
else
  ig_stage(H_indizes) = T;
end