function [nv_stage,N] = nvars(H_norm, nx, ni, nu, np)
% number of control intervals
N = length(H_norm);

% N control interval which each have states, integrator vars,
% controls, parameters, and timesteps.
% Ends with a single state.
nv_stage = N*nx + N*ni + N*nu + N*np + N + nx + np;