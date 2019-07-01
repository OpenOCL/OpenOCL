function r = evalCoefficients(coeff, d, point)

oclAssert(point<=1 && point >=0);

r = zeros(d+1, 1);
for j=1:d+1
  r(j) = polyval(coeff(j,:), point);
end