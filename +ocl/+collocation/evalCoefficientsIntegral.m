function r = evalCoefficientsIntegral(coeff, d, point)

oclAssert(point<=1 && point >=0);

r = zeros(d+1, 1);
for k=1:d+1
  % Evaluate the integral of the polynomial to get 
  % the coefficients of the quadrature function
  p_int = polyint(coeff(k,:));
  r(k) = polyval(p_int, point);
end