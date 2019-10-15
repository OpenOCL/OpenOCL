function [x_struct, z_struct, u_struct, p_struct, ...
          x_bounds, z_bounds, u_bounds, p_bounds, ...
          x_order] = vars(varsfh, userdata)
        
vh = ocl.VarHandler(userdata);
varsfh(vh);

x_struct = vh.x_struct;
z_struct = vh.z_struct;
u_struct = vh.u_struct;
p_struct = vh.p_struct;

x_bounds = vh.x_bounds;
z_bounds = vh.z_bounds;
u_bounds = vh.u_bounds;
p_bounds = vh.p_bounds;

x_order = vh.x_order;