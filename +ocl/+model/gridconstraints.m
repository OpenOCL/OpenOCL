function [val,lb,ub] = gridconstraints(fh,x_struct, p_struct, k, N, x, p)
gridConHandler = OclConstraint();
x = Variable.create(x_struct,x);
p = Variable.create(p_struct,p);

fh(gridConHandler,k,N,x,p);

val = gridConHandler.values;
lb = gridConHandler.lowerBounds;
ub = gridConHandler.upperBounds;

