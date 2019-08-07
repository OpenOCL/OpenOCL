function V = variablesPack(X, I, U, P, H)

N = length(H);
nx = size(X,1);
ni = size(I,1);
np = size(P,1);

nv = nvars(N, nx, ni, nu, np);

[X_indizes, I_indizes, U_indizes, P_indizes, H_indizes] = ocl.simultaneous.indizes(N, nx, ni, nu, np);

V = zeros(nv, 1);
V(X_indizes) = X;
V(I_indizes) = I;
V(U_indizes) = U;
V(P_indizes) = P;
V(H_indizes) = H;
