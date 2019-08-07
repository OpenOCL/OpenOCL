function dae(h, x, u)

s = size(x);
nx = s(1);

s = size(u);
nu = s(1);

num_masses = nx/2;

A = zeros(nx, nx);
for k=1:num_masses
	A(k, num_masses+k) = 1.0;
	A(num_masses+k, k) = -2.0;
end
for k=1:num_masses-1
	A(num_masses+k, k+1) = 1.0;
	A(num_masses+k+1, k) = 1.0;
end

B = zeros(nx, nu);
for k=1:nu
	B(num_masses+k, k) = 1.0;
end

h.setODE('x', A*x+B*u);