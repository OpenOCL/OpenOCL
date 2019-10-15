function [val,lb,ub] = gridconstraints(fh,x_struct, p_struct, k, N, x, p, userdata)
gridConHandler = ocl.Constraint(userdata);
x = ocl.Variable.create(x_struct,x);
p = ocl.Variable.create(p_struct,p);

fh(gridConHandler,k,N,x,p);

val = gridConHandler.values;
lb = gridConHandler.lowerBounds;
ub = gridConHandler.upperBounds;

