function [vars,times,solver] = mainBallAndBeam
% Title: Ball and beam problem
%  Authors: Jonas Koenneman & Giovanni Licitra

options = ocl.Options();
options.nlp.controlIntervals = 50;

bb = BallAndBeam();
system = ocl.System(@bb.varsfun, @bb.eqfun);
ocp = ocl.OCP(@bb.pathcosts);

solver = ocl.Solver([],system,ocp,options);

 % bound on time: 0 <= time <= 5
solver.setBounds('time', 0, 5);

% set bounds for initial and endtime
solver.setInitialBounds('r'      , -0.8);
solver.setInitialBounds('dr'     , 0.3);
solver.setInitialBounds('theta'  , deg2rad(5));
solver.setInitialBounds('dtheta' , 0.0);
solver.setInitialBounds('time' , 0);

solver.setEndBounds('r'      , 0);
solver.setEndBounds('dr'     , 0);
solver.setEndBounds('theta'  , 0);
solver.setEndBounds('dtheta' , 0);

% Solve OCP
vars = solver.getInitialGuess();
[vars,times] = solver.solve(vars);

% Plot solution
figure;
subplot(3,1,1);hold on;grid on;
plot(times.states.value,vars.states.r.value     ,'Color','b','LineWidth',1.5)
plot(times.states.value,vars.states.dr.value    ,'Color','r','LineWidth',1.5)
legend({'r [m]','dr [m/s]'})
plot(times.states.value, bb.c.r_b*ones(length(times)),'Color','b','LineWidth',1.0,'LineStyle','-.');
plot(times.states.value, bb.c.r_b*ones(length(times)),'Color','b','LineWidth',1.0,'LineStyle','-.');

subplot(3,1,2);hold on;grid on;
plot(times.states.value,rad2deg(vars.states.theta.value) ,'Color','b','LineWidth',1.5)
plot(times.states.value,rad2deg(vars.states.dtheta.value),'Color','r','LineWidth',1.5)
legend({'\theta [deg]','dtheta [deg/s]'})
plot(times.states.value, rad2deg(  bb.c.theta_b.*ones(length(times))),'Color','b','LineWidth',1.0,'LineStyle','-.');
plot(times.states.value, rad2deg( -bb.c.theta_b.*ones(length(times))),'Color','b','LineWidth',1.0,'LineStyle','-.');
plot(times.states.value, rad2deg( bb.c.dtheta_b.*ones(length(times))),'Color','r','LineWidth',1.0,'LineStyle','-.');
plot(times.states.value, rad2deg(-bb.c.dtheta_b.*ones(length(times))),'Color','r','LineWidth',1.0,'LineStyle','-.');

subplot(3,1,3);hold on;grid on;
stairs(times.controls.value,vars.controls.tau.value,'Color','g','LineWidth',1.5)
plot(times.states.value, bb.c.tau_b.*ones(length(times)),'Color','g','LineWidth',1.0,'LineStyle','-.');
plot(times.states.value,-bb.c.tau_b.*ones(length(times)),'Color','g','LineWidth',1.0,'LineStyle','-.');
legend({'\tau [Nm]'})
xlabel('time');

% Show Animation
bb.animate(times.states.value,vars.states.r.value,vars.states.theta.value);
