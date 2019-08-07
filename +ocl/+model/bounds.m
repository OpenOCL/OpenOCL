function [lb, ub] = bounds(var_struct, bounds)

lb_var = ocl.Variable.create(var_struct, -inf);
ub_var = ocl.Variable.create(var_struct, inf);

for k=1:length(bounds.data)
  
  d = bounds.data{k};
  id = d.id;
  lower = d.lower;
  upper = d.upper;
  
  lb_var.get(id).set(lower);
  ub_var.get(id).set(upper);
  
end

lb = lb_var.value;
ub = ub_var.value;