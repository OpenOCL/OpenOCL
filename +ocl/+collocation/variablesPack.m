function vi = variablesPack(x,z)

d = size(x,2);
nx = size(x,1);
nz = size(z,1);

[x_indizes, z_indizes] = ocl.collocation.indizes(nx,nz,d);

vi = zeros(d*(nx+nz), 1);

vi(x_indizes) = x;
vi(z_indizes) = z;

end