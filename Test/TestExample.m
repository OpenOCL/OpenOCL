function TestExample
StartupOC
eval('Example');

assert(all(abs(solution.get('controls').flat - ...
  [ 0.2434
    0.9611
    0.9074
    0.8610
    0.8049
    0.7491
    0.6876
    0.6240
    0.5561
    0.5342
    0.4947
    0.4131
    0.3171
    0.2245
    0.1448
    0.0821
    0.0365
    0.0062
   -0.0119
   -0.0207
   -0.0233
   -0.0220
   -0.0185
   -0.0143
   -0.0102
   -0.0066
   -0.0037
   -0.0017
   -0.0005
   -0.0000]) < 1e-4 ), 'Control vector of solution is wrong.');
