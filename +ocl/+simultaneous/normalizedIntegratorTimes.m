function r = normalizedIntegratorTimes(stage)
H_norm = stage.H_norm;
integrator = stage.integrator;

r = zeros(length(H_norm), integrator.num_t);
time = 0;
for k=1:length(H_norm)
  h = H_norm(k);
  r(k,:) = time + h * stage.integrator.normalized_times();
  time = time + H_norm(k);
end
