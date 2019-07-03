function [ode,alg] = dae(daefh, ...
  x_struct, z_struct, u_struct, p_struct, x_order, ...
  x, z, u, p)
% evaluate the system equations for the assigned variables

x = Variable.create(x_struct,x);
z = Variable.create(z_struct,z);
u = Variable.create(u_struct,u);
p = Variable.create(p_struct,p);

daehandler = OclDaeHandler();
daefh(daehandler,x,z,u,p);

ode = daehandler.getOde(self.nx, x_order);
alg = daehandler.getAlg(self.nz);