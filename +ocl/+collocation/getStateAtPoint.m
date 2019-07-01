function x = getStateAtPoint(colloc, x0, vars, point)

d = colloc.order;
nx = colloc.num_x;
nz = colloc.num_z;
coeff = colloc.coefficients;

coeff_eval_point = ocl.collocation.evalCoefficients(coeff, d, point);

x = coeff_eval_point(1)*x0;

for j=1:d
  j_vars = (j-1)*(nx+nz);
  j_x = j_vars+1:j_vars+nx;
  x = x + coeff_eval_point(j+1)*vars(j_x);
end