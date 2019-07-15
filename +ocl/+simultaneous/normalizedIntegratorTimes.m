function r = normalizedIntegratorTimes(H_norm, nt, order)

r = zeros(length(H_norm), nt);
time = 0;
for k=1:length(H_norm)
  h = H_norm(k);
  r(k,:) = time + h * ocl.collocation.collocationPoints(order);
  time = time + H_norm(k);
end
