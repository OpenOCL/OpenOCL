function r = gridcosts(fh, x_struct, p_struct, k, K, x, p)
gridCostHandler = ocl.Cost();

x = Variable.create(x_struct,x);
p = Variable.create(p_struct,p);

fh(gridCostHandler,k,K,x,p);

r = gridCostHandler.value;