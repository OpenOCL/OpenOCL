function ic = ic(icfh, x_struct,p_struct,x,p, userdata)
% initial condition function
icHandler = ocl.Constraint(userdata);
x = ocl.Variable.create(x_struct,x);
p = ocl.Variable.create(p_struct,p);
icfh(icHandler,x,p)
ic = icHandler.values;
assert(all(icHandler.lowerBounds==0) && all(icHandler.upperBounds==0),...
  'In initial condition are only equality constraints allowed.');