function gridcosts(h, k, K, x, p)

if k==K
  s = size(x);
  nx = s(1);
  
  dWx = ones(nx, 1);

  yr_x = zeros(nx, 1);
  ymyr_e = x - yr_x;
	h.add(0.5 * ymyr_e.' * (dWx .* ymyr_e));
end

