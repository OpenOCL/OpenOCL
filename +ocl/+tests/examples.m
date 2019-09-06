% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%

function [o1,o2,o3,o4,o5] = examples

% test basic example (VanDerPol)
[sol,~,solver] = ocl.examples.vanderpol;
ocl.utils.assertAlmostEqual(sol.controls.F.value, ...
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
  -0.0000], 'Control vector of solution is wrong in Example.');
o1 = solver.timeMeasures;

% test ball and beam example problem
[sol,~,solver] = ocl.examples.ballandbeam;
ocl.utils.assertAlmostEqual(sol.controls.tau(1:5:end).value, ...
                  [-20 -11.799175061432 -7.07950809738102 -7.34241665451232 -2.73218112537589 -0.994219272444794 0.837003335955445 1.759782405326 1.15625958638477 -0.1240626768517]', ...
                  'Ball and beam problem Test failed.', 1e-3);

o2 = solver.timeMeasures;

% test race car problem
[sol,~,solver] = ocl.examples.racecar;
ocl.utils.assertAlmostEqual(sol.controls.dFx(1:5:end).value,...
      [-0.0101362795430379;-0.999999558480492;0.319856962019424;-0.764994370307151;0.7697294885374;-0.126456278919074;0.580563346802815;-0.661025508901183;0.999998743528033;-0.9999996584554],...
      'Solve RaceCar Test failed.',1e-2);

o3 = solver.timeMeasures;
 
% test pendulum simulation
simTic = tic;
p_vec = ocl.examples.pendulum_sim;
ocl.utils.assertAlmostEqual(p_vec(1,1:10:41), ...
                  [-0.54539692886092 -0.998705998524509 -0.35261785193535 -0.944326275381522 0.0204417663509827], ...
                  'PendulumSim Test failed.');
o4 = struct;
o4.simulationTest = toc(simTic);

% test cart pole
[sol,~,solver] = ocl.examples.cartpole;
res = sol.controls.F(1:7:end).value;
truth = [12;-11.9999;-12;6.43066;12;-12];
ocl.utils.assertAlmostEqual(res, truth, 'Cart pole test failed.');
o5 = solver.timeMeasures;

% test bouncing ball
[sol,~,solver] = ocl.examples.bouncingball;
stage_1 = sol{1}.states(:,[1,end]).value;
ocl.utils.assertAlmostEqual(stage_1, [1 0;0 -4.47214], 'Bouncing ball test failed.');
stage_2 = sol{2}.controls.F.value;
ocl.utils.assertAlmostEqual(stage_2, [1.02653;0.79841;0.570293;0.342176;0.114059], 'Bouncing ball test failed.');
o6 = solver.timeMeasures;