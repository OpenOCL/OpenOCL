function opt = CasadiOptions  
opt = struct;
opt.ipopt = struct;
opt.ipopt.linear_solver = 'mumps';
opt.ipopt.hessian_approximation = 'exact';