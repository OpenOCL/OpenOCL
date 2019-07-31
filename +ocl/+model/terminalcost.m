function r = terminalcost(fh, x_struct, p_struct, x, p)
% ocl.model.pathcosts(pathcostsfh, states, parameters, x, p)
%
pcHandler = ocl.Cost();

x = Variable.create(x_struct,x);
p = Variable.create(p_struct,p);

fh(pcHandler,x,p);

r = pcHandler.value;
