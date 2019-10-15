function r = gridcosts(fh, x_struct, p_struct, k, K, x, p, userdata)
gridCostHandler = ocl.Cost(userdata);

x = ocl.Variable.create(x_struct,x);
p = ocl.Variable.create(p_struct,p);

fh(gridCostHandler,k,K,x,p);

r = gridCostHandler.value;