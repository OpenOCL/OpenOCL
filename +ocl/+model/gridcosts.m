function r = gridcosts(fh, x_struct, p_struct, k, N, x, p)
gridCostHandler = OclCost();

x = Variable.create(x_struct,x);
p = Variable.create(p_struct,p);

fh(gridCostHandler,k,N,x,p);

r = gridCostHandler.value;