function [lb_stage,ub_stage] = getBounds(stage)

[nv_stage,~] = Simultaneous.nvars(stage.H_norm, stage.nx, stage.integrator.ni, stage.nu, stage.np);

lb_stage = -inf * ones(nv_stage,1);
ub_stage = inf * ones(nv_stage,1);

[X_indizes, I_indizes, U_indizes, P_indizes, H_indizes] = Simultaneous.getStageIndizes(stage);

% states
for m=1:size(X_indizes,2)
  lb_stage(X_indizes(:,m)) = stage.stateBounds.lower;
  ub_stage(X_indizes(:,m)) = stage.stateBounds.upper;
end

% Merge the two vectors of bound values for lower bounds and upper bounds.
% Bound values can only get narrower, e.g. higher for lower bounds.
lb_stage(X_indizes(:,1)) = max(stage.stateBounds.lower,stage.stateBounds0.lower);
ub_stage(X_indizes(:,1)) = min(stage.stateBounds.upper,stage.stateBounds0.upper);

lb_stage(X_indizes(:,end)) = max(stage.stateBounds.lower,stage.stateBoundsF.lower);
ub_stage(X_indizes(:,end)) = min(stage.stateBounds.upper,stage.stateBoundsF.upper);

% integrator bounds
for m=1:size(I_indizes,2)
  lb_stage(I_indizes(:,m)) = stage.integrator.integratorBounds.lower;
  ub_stage(I_indizes(:,m)) = stage.integrator.integratorBounds.upper;
end

% controls
for m=1:size(U_indizes,2)
  lb_stage(U_indizes(:,m)) = stage.controlBounds.lower;
  ub_stage(U_indizes(:,m)) = stage.controlBounds.upper;
end

% parameters (only set the initial parameters)
lb_stage(P_indizes(:,1)) = stage.parameterBounds.lower;
ub_stage(P_indizes(:,1)) = stage.parameterBounds.upper;

% timesteps
if isempty(stage.T)
  lb_stage(H_indizes) = Simultaneous.h_min;
else
  lb_stage(H_indizes) = stage.H_norm * stage.T;
  ub_stage(H_indizes) = stage.H_norm * stage.T;
end