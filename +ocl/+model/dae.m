function [ode,alg] = dae(daefh, ...
  x_struct, z_struct, u_struct, p_struct, x_order, ...
  x, z, u, p, userdata)
% evaluate the system equations for the assigned variables

x = ocl.Variable.create(x_struct,x);
z = ocl.Variable.create(z_struct,z);
u = ocl.Variable.create(u_struct,u);
p = ocl.Variable.create(p_struct,p);

daehandler = ocl.DaeHandler(userdata);
daefh(daehandler,x,z,u,p);

nx = length(x_struct);
nz = length(z_struct);

ode = daehandler.getOde(nx, x_order);
alg = daehandler.getAlg(nz);