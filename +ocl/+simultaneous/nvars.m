function [nv_stage] = nvars(N, nx, ni, nu, np)

% N control interval which each have states, integrator vars,
% controls, parameters, and timesteps.
% Ends with a single state.
nv_stage = N*nx + N*ni + N*nu + N*np + N + nx + np;