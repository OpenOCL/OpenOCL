function times_r = times(H, colloc)

tau_root = colloc.tau_root;

% times output
times_r = zeros(length(H), length(tau_root)-1);
T0 = [0, cumsum(H(:,1:end-1))];
for k=1:size(H,2)
  times_r(k,:) = T0(k) + ocl.collocation.times(tau_root, H(k));
end
times_r = times_r';
times_r = [T0; times_r; T0];
times_r = [times_r(:); T0(end)+H(end)];