function gridconstraints(ch, k, K, x, ~)

if k==K
  ch.add(x.p, '==', 0);
  ch.add(x.v, '==', 0);
  ch.add(x.theta, '==', 0);
  ch.add(x.omega, '==', 0);
end