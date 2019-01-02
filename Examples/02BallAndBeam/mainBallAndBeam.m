% Title: Ball and beam problem
%  Authors: Jonas Koenneman & Giovanni Licitra

END_TIME = 5; % horizon length (seconds)

options = OclOptions();
options.nlp.controlIntervals = 50;

ocl = OclSolver(BallAndBeamSystem,BallAndBeamOCP,options);

% assign values to system parameters
ocl.setParameter('I', 0.5);
ocl.setParameter('J', 25*10^(-3));
ocl.setParameter('m', 2);
ocl.setParameter('R', 0.05);
ocl.setParameter('g', 9.81);
ocl.setParameter('time'  ,  1, END_TIME);  %   T0 <= T <= Tf

% set bounds    
r_b      = 1;           % beam length [m]
theta_b  = deg2rad(30); % max angle [deg]
dtheta_b = deg2rad(50); % max angular speed [deg/s]
tau_b    = 20;          % bound torque [Nm]

ocl.setBounds('r'     ,  -r_b      , r_b);  
ocl.setBounds('theta' ,  -theta_b  , theta_b);
ocl.setBounds('dtheta',  -dtheta_b , dtheta_b); 
ocl.setBounds('tau'   ,  -tau_b    , tau_b);

% set bounds for initial and endtime
ocl.setInitialBounds('r'      , -0.8);
ocl.setInitialBounds('dr'     , 0.3);
ocl.setInitialBounds('theta'  , deg2rad(5));
ocl.setInitialBounds('dtheta' , 0.0);

ocl.setEndBounds('r'      , 0);
ocl.setEndBounds('dr'     , 0);
ocl.setEndBounds('theta'  , 0);
ocl.setEndBounds('dtheta' , 0);

% Solve OCP
vars = ocl.getInitialGuess();
[vars,times] = ocl.solve(vars);

% Plot solution
figure;
subplot(3,1,1);hold on;grid on; 
plot(times,vars.states.r.value     ,'Color','b','LineWidth',1.5)
plot(times,vars.states.dr.value    ,'Color','r','LineWidth',1.5)
legend({'r [m]','dr [m/s]'})
plot(times, r_b.*ones(length(times)),'Color','b','LineWidth',1.0,'LineStyle','-.');
plot(times,-r_b.*ones(length(times)),'Color','b','LineWidth',1.0,'LineStyle','-.');

subplot(3,1,2);hold on;grid on;
plot(times,rad2deg(vars.states.theta.value) ,'Color','b','LineWidth',1.5)
plot(times,rad2deg(vars.states.dtheta.value),'Color','r','LineWidth',1.5)
legend({'\theta [deg]','dtheta [deg/s]'})
plot(times, rad2deg(  theta_b.*ones(length(times))),'Color','b','LineWidth',1.0,'LineStyle','-.');
plot(times, rad2deg( -theta_b.*ones(length(times))),'Color','b','LineWidth',1.0,'LineStyle','-.');
plot(times, rad2deg( dtheta_b.*ones(length(times))),'Color','r','LineWidth',1.0,'LineStyle','-.');
plot(times, rad2deg(-dtheta_b.*ones(length(times))),'Color','r','LineWidth',1.0,'LineStyle','-.');

subplot(3,1,3);hold on;grid on;
stairs(times(1:end-1),vars.controls.tau.value,'Color','g','LineWidth',1.5)
plot(times, tau_b.*ones(length(times)),'Color','g','LineWidth',1.0,'LineStyle','-.');
plot(times,-tau_b.*ones(length(times)),'Color','g','LineWidth',1.0,'LineStyle','-.');
legend({'\tau [Nm]'})
xlabel('time');

% Show Animation
animateBallAndBeam(times,vars.states.r.value,vars.states.theta.value);