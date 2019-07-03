function r = pathcosts(fh, x_struct, z_struct, u_struct, p_struct, x, z, u, p)
% ocl.model.pathcosts(pathcostsfh, states, algvars, controls, parameters, x,z,u,p)
%
pcHandler = OclCost();

x = Variable.create(x_struct,x);
z = Variable.create(z_struct,z);
u = Variable.create(u_struct,u);
p = Variable.create(p_struct,p);

fh(pcHandler,x,z,u,p);

r = pcHandler.value;
