function [lb_out, ub_out, Jb] = bounds(lb_in, ub_in)

bounds_select = ~isinf(lb_in) | ~isinf(ub_in);

Jb = diag(bounds_select);
Jb = Jb(any(Jb,2),:);

lb_out = x_lb(bounds_select);
ub_out = u_lb(u_bounds_select);
