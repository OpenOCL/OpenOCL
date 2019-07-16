function [x_struct, z_struct, u_struct, p_struct, ...
          x_bounds, z_bounds, u_bounds, p_bounds, ...
          x_order] = vars(varsfh)
        
svh = OclSysvarsHandler;
varsfh(svh);

x_struct = svh.x_struct;
z_struct = svh.z_struct;
u_struct = svh.u_struct;
p_struct = svh.p_struct;

x_bounds = svh.x_bounds;
z_bounds = svh.z_bounds;
u_bounds = svh.u_bounds;
p_bounds = svh.p_bounds;

x_order = svh.x_order;