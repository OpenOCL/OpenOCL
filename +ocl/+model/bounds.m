function [x_lb, x_ub, z_lb, z_ub, u_lb, u_ub] = bounds(x_struct, z_struct, u_struct, p_struct, bounds)

x_names = x_struct.getNames();
z_names = z_struct.getNames();
u_names = u_struct.getNames();
p_names = p_struct.getNames();

for k=1:length(bounds.data)
  d = bounds.data{k};

  if any(strcmp(x_names, d.id))

  elseif any(strcmp(z_names, d.id))

  end
end
