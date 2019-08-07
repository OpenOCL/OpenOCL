function pathcosts(h, x, u)

s = size(x);
nx = s(1);

s = size(u);
nu = s(1);

yr_u = zeros(nu, 1);
yr_x = zeros(nx, 1);
dWu = 2*ones(nu, 1);
dWx = ones(nx, 1);

ymyr = [u; x] - [yr_u; yr_x];

h.add(0.5 * ymyr.' * ([dWu; dWx] .* ymyr));