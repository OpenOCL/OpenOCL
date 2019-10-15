function r = terminalcost(fh, x_struct, p_struct, x, p, userdata)
% ocl.model.pathcosts(pathcostsfh, states, parameters, x, p)
%
pcHandler = ocl.Cost(userdata);

x = ocl.Variable.create(x_struct,x);
p = ocl.Variable.create(p_struct,p);

fh(pcHandler,x,p);

r = pcHandler.value;
