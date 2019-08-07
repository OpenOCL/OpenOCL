function [lb,ub] = bounds(vi_struct, x_lb, x_ub, z_lb, z_ub)

ni = length(vi_struct);

lb_var = ocl.Variable.create(vi_struct, -inf * ones(ni, 1));
ub_var = ocl.Variable.create(vi_struct, inf * ones(ni, 1));

lb_var.states.set(x_lb);
ub_var.states.set(x_ub);

lb_var.algvars.set(z_lb);
ub_var.algvars.set(z_ub);

lb = lb_var.value;
ub = ub_var.value;
