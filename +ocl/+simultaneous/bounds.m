function [lb_stage,ub_stage] = bounds(H_norm, T, nx, ni, nu, np, ...
                                      x_lb, x_ub, x0_lb, x0_ub, xF_lb, xF_ub, ...
                                      vi_lb, vi_ub, u_lb_traj, u_ub_traj, p_lb, p_ub)

N = length(H_norm);
nv_stage = ocl.simultaneous.nvars(N, nx, ni, nu, np);

lb_stage = -inf * ones(nv_stage,1);
ub_stage = inf * ones(nv_stage,1);

[X_indizes, I_indizes, U_indizes, P_indizes, T_indizes] = ocl.simultaneous.indizes(N, nx, ni, nu, np);

% states
for m=1:size(X_indizes,2)
  lb_stage(X_indizes(:,m)) = x_lb;
  ub_stage(X_indizes(:,m)) = x_ub;
end

% Merge the two vectors of bound values for lower bounds and upper bounds.
% Bound values can only get narrower, e.g. higher for lower bounds.
lb_stage(X_indizes(:,1)) = max(x_lb, x0_lb);
ub_stage(X_indizes(:,1)) = min(x_ub, x0_ub);

lb_stage(X_indizes(:,end)) = max(x_lb, xF_lb);
ub_stage(X_indizes(:,end)) = min(x_ub, xF_ub);

% integrator bounds
for m=1:size(I_indizes,2)
  lb_stage(I_indizes(:,m)) = vi_lb;
  ub_stage(I_indizes(:,m)) = vi_ub;
end

% controls
lb_stage(U_indizes) = u_lb_traj;
ub_stage(U_indizes) = u_ub_traj;

% parameters (only set the initial parameters)
lb_stage(P_indizes(:,1)) = p_lb;
ub_stage(P_indizes(:,1)) = p_ub;

% timesteps
if isempty(T)
  lb_stage(T_indizes(:,1)) = 0.001;
else
  lb_stage(T_indizes(:,1)) = T;
  ub_stage(T_indizes(:,1)) = T;
end