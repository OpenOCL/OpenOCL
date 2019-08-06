function [lb, ub] = boundsTrajectory(var_struct, bounds, N)

traj_struct = ocl.types.Structure();
traj_struct.addRepeated({'traj'}, {var_struct}, N);

lb_var = ocl.Variable.create(traj_struct, -inf);
ub_var = ocl.Variable.create(traj_struct, inf);

lb_var = lb_var.traj;
ub_var = ub_var.traj;

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