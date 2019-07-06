num_masses = 4;

varsfh = @(h) ocl.examples.linear_mass_spring.vars(h,num_masses);
daefh = @(h,x,z,u,p) ocl.examples.linear_mass_spring.dae(h,x,u);
pathcostsfh = @(h,x,z,u,p) ocl.examples.linear_mass_spring.pathcosts(h,x,u);
gridcostsfh = @(h,k,K,x,p) ocl.examples.linear_mass_spring.gridcosts(h,k,K,x);
gridconstraintsfh = @(varargin) [];
  
ocl.acados.initialize( ...
    10, 30, ...
    varsfh, daefh, gridcostsfh, pathcostsfh, gridconstraintsfh )