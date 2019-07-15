function [lb,ub] = bounds(i_vars, x_bounds, z_bounds)

ni = length(i_vars);

lb = Variable.create(i_vars, -inf * ones(ni, 1));
ub = Variable.create(i_vars, inf * ones(ni, 1));

for k=1:length(x_bounds)
  id = x_bounds{k}.id;
  x_lb = x_bounds{k}.lower;
  x_ub = x_bounds{k}.upper;
  lb.states.get(id).set(x_lb);
  ub.states.get(id).set(x_ub);
end

for k=1:length(z_bounds)
  id = z_bounds{k}.id;
  z_lb = z_bounds{k}.lower;
  z_ub = z_bounds{k}.upper;
  lb.states.get(id).set(z_lb);
  ub.states.get(id).set(z_ub);
end

lb = lb.value;
ub = ub.value;
