function [lb_stage,ub_stage] = bounds(H_norm, T, nx, ni, nu, np, ...
                                      x_lb, x_ub, x0_lb, x0_ub, xF_lb, xF_ub, ...
                                      vi_lb, vi_ub, u_lb, u_ub, p_lb, p_ub)

[nv_stage,N] = ocl.simultaneous.nvars(H_norm, nx, ni, nu, np);

lb_stage = -inf * ones(nv_stage,1);
ub_stage = inf * ones(nv_stage,1);

[X_indizes, I_indizes, U_indizes, P_indizes, H_indizes] = ocl.simultaneous.indizes(N, nx, ni, nu, np);

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
for m=1:size(U_indizes,2)
  lb_stage(U_indizes(:,m)) = u_lb;
  ub_stage(U_indizes(:,m)) = u_ub;
end

% parameters (only set the initial parameters)
lb_stage(P_indizes(:,1)) = p_lb;
ub_stage(P_indizes(:,1)) = p_ub;

% timesteps
if isempty(stage.T)
  lb_stage(H_indizes) = 0.0;
else
  lb_stage(H_indizes) = H_norm * T;
  ub_stage(H_indizes) = H_norm * T;
end