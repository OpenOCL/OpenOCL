function [costs,constraints,constraints_lb,constraints_ub,times,x0,p0] = ...
  equations(stage, stage_vars, controls_regularization, ...
            controls_regularization_value)

H_norm = stage.H_norm;
T = stage.T;
nx = stage.nx;
ni = stage.integrator.ni;
nu = stage.nu;
np = stage.np;
pointcost_fun = @stage.pointcostfun;
pointcon_fun = @stage.pointconstraintfun;

[~,N] = ocl.simultaneous.nvars(H_norm, nx, ni, nu, np);
[X_indizes, I_indizes, U_indizes, P_indizes, H_indizes] = ocl.simultaneous.getStageIndizes(stage);

X = reshape(stage_vars(X_indizes), nx, N+1);
I = reshape(stage_vars(I_indizes), ni, N);
U = reshape(stage_vars(U_indizes), nu, N);
P = reshape(stage_vars(P_indizes), np, N+1);
H = reshape(stage_vars(H_indizes), 1 , N);

% point constraints, point costs
pointcon = cell(1,N+1);
pointcon_lb = cell(1,N+1);
pointcon_ub = cell(1,N+1);
pointcost = 0;
for k=1:N+1
  [pointcon{k}, pointcon_lb{k}, pointcon_ub{k}] = pointcon_fun(k, N+1, X(:,k), P(:,k));
  pointcost = pointcost + pointcost_fun(k, N+1, X(:,k), P(:,k));
end

pointcon0 = pointcon{1};
pointcon0_lb = pointcon_lb{1};
pointcon0_ub = pointcon_ub{1};

pointconF = pointcon{end};
pointconF_lb = pointcon_lb{end};
pointconF_ub = pointcon_ub{end};

pointcon = horzcat(pointcon{2:end-1});
pointcon_lb = horzcat(pointcon_lb{2:end-1});
pointcon_ub = horzcat(pointcon_ub{2:end-1});

% fix dimensions of empty path constraints
if isempty(pointcon)
  pointcon = double.empty(0,N-1);
  pointcon_lb = double.empty(0,N-1);
  pointcon_ub = double.empty(0,N-1);
end

[xend_arr, cost_arr, int_eq_arr, int_times] = stage.integratormap(X(:,1:end-1), I, U, H, P(:,1:end-1));

% timestep constraints
h_eq = [];
h_eq_lb = [];
h_eq_ub = [];

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

% merge integrator equations, continuity, and path constraints,
% timesteps constraints
shooting_eq    = [int_eq_arr(:,1:N-1);   continuity(:,1:N-1);   pointcon;     h_eq;     p_eq(:,1:N-1)];
shooting_eq_lb = [zeros(ni,N-1);         zeros(nx,N-1);         pointcon_lb;  h_eq_lb;  p_eq_lb(:,1:N-1)];
shooting_eq_ub = [zeros(ni,N-1);         zeros(nx,N-1);         pointcon_ub;  h_eq_ub;  p_eq_ub(:,1:N-1)];

% reshape shooting equations to column vector, append lastintegrator and
% continuity equations
constraints    = [pointcon0;      shooting_eq(:);    int_eq_arr(:,N); continuity(:,N); pointconF;       p_eq(:,N)    ];
constraints_lb = [pointcon0_lb;   shooting_eq_lb(:); zeros(ni,1);     zeros(nx,1);     pointconF_lb;    p_eq_lb(:,N) ];
constraints_ub = [pointcon0_ub;   shooting_eq_ub(:); zeros(ni,1);     zeros(nx,1);     pointconF_ub;    p_eq_ub(:,N) ];

% sum all costs
costs = sum(cost_arr) + pointcost;

% regularization on U
if controls_regularization && numel(U)>0
  Uvec = U(:);
  costs = costs + controls_regularization_value*(Uvec'*Uvec);
end

% times output
T0 = [0, cumsum(H(:,1:end-1))];
for k=1:size(int_times,1)
  int_times(k,:) = T0 + int_times(k,:);
end
times = [T0; int_times; T0];
times = [times(:); T0(end)+H(end)];

x0 = X(:,1);
p0 = P(:,1);