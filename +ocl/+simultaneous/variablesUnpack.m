function [X,I,U,P,H] = variablesUnpack(V, N, nx, ni, nu, np)

[X_indizes, I_indizes, U_indizes, P_indizes, H_indizes] = ocl.simultaneous.indizes(N, nx, ni, nu, np);

X = reshape(V(X_indizes), nx, N+1);
I = reshape(V(I_indizes), ni, N);
U = reshape(V(U_indizes), nu, N);
P = reshape(V(P_indizes), np, N+1);
H = reshape(V(H_indizes), 1 , N);