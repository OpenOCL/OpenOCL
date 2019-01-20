function [o1,o2,o3,o4,o5] = testExamples

% test basic example (VanDerPol)
[sol,~,ocl] = mainVanDerPol;
assert(all(abs(sol.controls.F.value - ...
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
  -0.0000]) < 1e-3 ), 'Control vector of solution is wrong in Example.');
o1 = ocl.timeMeasures;

% test ball and beam example problem
mainBallAndBeam
assert(all(abs(vars.controls.tau.value - ...
  [-20.0000
  -20.0000
  -16.3269
  -13.5240
  -11.3542
  -9.6721
  -8.3999
  -7.4967
  -6.9423
  -6.7264
  -6.8350
  -7.2311
  -7.1171
  -5.8267
  -4.5955
  -3.3285
  -2.1695
  -1.5100
  -1.3162
  -0.9894
  -0.5946
  -0.1785
  0.2309
  0.6172
  0.9673
  1.2678
  1.3287
  1.1185
  1.0929
  1.0568
  0.9386
  0.7573
  0.5338
  0.2886
  0.0392
  -0.1990
  -0.4131
  -0.5917
  -0.7259
  -0.8091
  -0.8382
  -0.8138
  -0.7396
  -0.6221
  -0.4698
  -0.2925
  -0.1010
  0.0934
  0.2796
  0.4469]) < 1e-3 ), 'Ball and beam problem Test failed.');

o2 = ocl.timeMeasures;


% test race car problem
mainRaceCar
assertAlmostEqual(solution.controls.dFx(1,:,1:10:end).value,...
      [-0.00554603;0.548809;0.0892633;0.322054;0.362561],...
      'Solve RaceCar Test failed.');

o3 = ocl.timeMeasures;
 
% test pendulum simulation
simTic = tic;
simulatePendulum
assertAlmostEqual(statesVec.p(1,:,1:10:41).value, ...
                  [-0.545397;-0.998707;-0.352623;-0.944457;0], ...
                  'PendulumSim Test failed.');
o4 = struct;
o4.simulationTest = toc(simTic);


% test cart pole
mainCartPole
res = sol.states.theta(:,:,1:10:end).value;
truth = [3.14159;2.0802;1.11827;0.264782;-0.523718;4.00847e-17];
assertAlmostEqual(res, truth, 'Cart pole test failed.');
o5 = struct;
o5 = ocl.timeMeasures;