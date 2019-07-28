function [costs,constraints,constraints_lb,constraints_ub,x0,p0] = ...
  equations(H_norm, T, nx, ni, nu, np, gridcostfun, gridconstraintfun, ...
            terminalcostfun, integratormap, stage_vars, controls_regularization, ...
            controls_regularization_value)

N = length(H_norm);
[X,I,U,P,H] = ocl.simultaneous.variablesUnpack(stage_vars, N, nx, ni, nu, np);

% grid constraints, grid costs
gridcon = cell(1,N+1);
gridcon_lb = cell(1,N+1);
gridcon_ub = cell(1,N+1);
gridcost = 0;
for k=1:N+1
  [gridcon{k}, gridcon_lb{k}, gridcon_ub{k}] = gridconstraintfun(k, N+1, X(:,k), P(:,k));
  gridcost = gridcost + gridcostfun(k, N+1, X(:,k), P(:,k));
end

gridcost = gridcost + terminalcostfun(X(:,N+1), P(:,N+1));

% point costs
% grid = ocl.simultaneous.normalizedStateTimes(stage);
% grid_N = grid(1:end-1,:);
% grid_collocation = ocl.simultaneous.normalizedIntegratorTimes(stage);
% 
% grid_merged = [grid_N,grid_collocation];
% 
% for k=1:length(stage.pointcostsarray)
%   point = stage.pointcostsarray{k}.point;
%   fh = stage.pointcostsarray{k}.fh;
%   
% end

[xend_arr, cost_arr, int_eq_arr] = integratormap(X(:,1:end-1), I, U, H, P(:,1:end-1));

% timestep constraints
h_eq = double.empty(0,N-1);
h_eq_lb = double.empty(0,N-1);
h_eq_ub = double.empty(0,N-1);
if isempty(T)
  % h0 = h_1_hat / h_0_hat * h1 = h_2_hat / h_1_hat * h2 ...
  H_ratio = H_norm(1:end-1)./H_norm(2:end);
  h_eq = H_ratio .* H(:,2:end) - H(:,1:end-1);
  h_eq_lb = zeros(1, N-1);
  h_eq_ub = zeros(1, N-1);
end

% Parameter constraints
% p0=p1=p2=p3 ...
p_eq = P(:,2:end)-P(:,1:end-1);
p_eq_lb = zeros(np, N);
p_eq_ub = zeros(np, N);

% continuity (nx x N)
continuity = xend_arr - X(:,2:end);

% merge all constraints (ordered by apperance in grid)
grid_eq = cell(N+1,1);
grid_eq_lb = cell(N+1,1);
grid_eq_ub = cell(N+1,1);
for k=1:N-1
  gc_k = gridcon{k};
  gc_lb_k = gridcon_lb{k};
  gc_ub_k = gridcon_ub{k};
  grid_eq{k} = vertcat(gc_k(:), int_eq_arr(:,k), h_eq(:,k), p_eq(:,k), continuity(:,k));
  grid_eq_lb{k} = vertcat(gc_lb_k(:), zeros(ni,1), h_eq_lb(:,k), p_eq_lb(:,k), zeros(nx,1));
  grid_eq_ub{k} = vertcat(gc_ub_k(:), zeros(ni,1), h_eq_ub(:,k), p_eq_ub(:,k), zeros(nx,1));
end

gc_k = gridcon{N};
gc_lb_k = gridcon_lb{N};
gc_ub_k = gridcon_ub{N};

grid_eq{N} = vertcat(gc_k(:), int_eq_arr(:,N), p_eq(:,N), continuity(:,N));
grid_eq_lb{N} = vertcat(gc_lb_k(:), zeros(ni,1), p_eq_lb(:,N), zeros(nx,1));
grid_eq_ub{N} = vertcat(gc_ub_k(:), zeros(ni,1), p_eq_ub(:,N), zeros(nx,1));

gc_k = gridcon{N+1};
gc_lb_k = gridcon_lb{N+1};
gc_ub_k = gridcon_ub{N+1};

grid_eq{N+1} = gc_k(:);
grid_eq_lb{N+1} = gc_lb_k(:);
grid_eq_ub{N+1} = gc_ub_k(:);

constraints = vertcat(grid_eq{:});
constraints_lb = vertcat(grid_eq_lb{:});
constraints_ub = vertcat(grid_eq_ub{:});

% sum all costs
costs = sum(cost_arr) + gridcost;

% regularization on U
if controls_regularization && numel(U)>0
  Uvec = U(:);
  costs = costs + controls_regularization_value*(Uvec'*Uvec);
end

x0 = X(:,1);
p0 = P(:,1);