function [x,z] = variablesUnpack(vi, nx, nz, d)

[x_indizes, z_indizes] = ocl.collocation.indizes(nx,nz,d);

x = reshape(vi(x_indizes), nx, d);
z = reshape(vi(z_indizes), nz, d);

end