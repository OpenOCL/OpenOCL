%% Title: Ball and beam problem
%  Author: PhD students Jonas Koenneman & Giovanni Licitra

FINALTIME = 5;                % horizon length (seconds)

%% Create system and OCP
system = BallAndBeamSystem();
ocp    = BallAndBeamOCP(system);

%% STEP1: Get and set solver options
options = Solver.getOptions;
options.nlp.controlIntervals = 50;
nlp = Solver.getNLP(ocp,system,options);

%% STEP2: assign values to system parameters
nlp.setParameter('I', 0.5);
nlp.setParameter('J', 25*10^(-3));
nlp.setParameter('m', 2);
nlp.setParameter('R', 0.05);
nlp.setParameter('g', 9.81);
nlp.setParameter('time'  ,  1, FINALTIME);  %   T0 <= T <= Tf

%% STEP3: set bounds    
r_b      = 1;           % beam length [m]
theta_b  = deg2rad(30); % max angle [deg]
dtheta_b = deg2rad(50); % max angular speed [deg/s]
tau_b    = 20;          % bound torque [Nm]


nlp.setVariableBound('r'     ,  -r_b      , r_b);   
nlp.setVariableBound('theta' ,  -theta_b  , theta_b);
nlp.setVariableBound('dtheta',  -dtheta_b , dtheta_b); 
nlp.setVariableBound('tau'   ,  -tau_b    , tau_b);

%% STEP4: set bounds for initial and end time
% Intial conditions
nlp.setInitialBound('r'      , -0.8);
nlp.setInitialBound('dr'     , 0.3);
nlp.setInitialBound('theta'  , deg2rad(5));
nlp.setInitialBound('dtheta' , 0.0);

% Final conditions
nlp.setEndBound('r'      , 0);
nlp.setEndBound('dr'     , 0);
nlp.setEndBound('theta'  , 0);
nlp.setEndBound('dtheta' , 0);

%% Solve OCP
solver   = Solver.getSolver(nlp,options);   % Create solver
vars     = nlp.getInitialGuess();           % Get and set initial guess
[vars,times] = solver.solve(vars);          % Run solver to obtain solution
times = times.value;

%% Plot solution
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

%% Show Animation
animateBallAndBeam(times,vars.states.r.value,vars.states.theta.value);