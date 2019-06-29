function r = evalCoefficientsDerivative(coeff, tau_root, d)
r = zeros(d+1, d+1);
for k=1:d+1
  pder = polyder(coeff(k,:));
  for j=1:d+1
    r(k,j) = polyval(pder, tau_root(j));
  end
end
