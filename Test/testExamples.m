% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%

function [o1,o2,o3,o4,o5] = testExamples

% test basic example (VanDerPol)
[sol,~,solver] = ocl.examples.vanderpol;
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
o1 = solver.timeMeasures;

% test ball and beam example problem
[sol,~,solver] = ocl.examples.ballandbeam;
assertAlmostEqual(sol.controls.tau(1:5:end).value, ...
                  [-20;-9.67180946278377;-6.83499933773107;-3.3277726553036;-0.594240414712151;1.26802912244169;0.938453275453379;-0.199369534081799;-0.838286223053903;-0.292251460119773], ...
                  'Ball and beam problem Test failed.', 1e-3);

o2 = solver.timeMeasures;

% test race car problem
[sol,~,solver] = ocl.examples.racecar;
assertAlmostEqual(sol.controls.dFx(1,:,1:5:end).value,...
      [-0.0101362795430379;-0.999999558480492;0.319856962019424;-0.764994370307151;0.7697294885374;-0.126456278919074;0.580563346802815;-0.661025508901183;0.999998743528033;-0.9999996584554],...
      'Solve RaceCar Test failed.',1e-2);

o3 = solver.timeMeasures;
 
% test pendulum simulation
simTic = tic;
statesVec = ocl.examples.pendulum_sim;
assertAlmostEqual(statesVec.p(1,:,1:10:41).value, ...
                  [-0.545396928860894;-0.998705998524533;-0.35261807316407;-0.944329126056321;0], ...
                  'PendulumSim Test failed.');
o4 = struct;
o4.simulationTest = toc(simTic);

% test cart pole
[sol,~,solver] = ocl.examples.cartpole;
res = sol.states.theta(:,:,1:10:end).value;
truth = [3.14159265358979;3.86044803075832;2.52342234356076;0.885691999280203;0];
assertAlmostEqual(res, truth, 'Cart pole test failed.');
o5 = solver.timeMeasures;

% test bouncing ball
[sol,~,solver] = ocl.examples.bouncingball;
phase_1 = sol{1}.states.s.value;
assertAlmostEqual(phase_1, [1;0.888888888888889;0.555555555555555;0], 'Cart pole test failed.');
phase_2 = sol{2}.states.s.value;
assertAlmostEqual(phase_2, [0;0.452518978545424;0.870025304727232;1.16127214163633;1.23501265236362;1], 'Cart pole test failed.');
o6 = solver.timeMeasures;