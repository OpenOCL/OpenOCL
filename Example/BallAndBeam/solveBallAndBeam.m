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

%% STEP2: set parameters
nlp.setBound('I', 1, 0.5);
nlp.setBound('J', 1, 25*10^(-3));
nlp.setBound('m', 1, 2);
nlp.setBound('R', 1, 0.05);
nlp.setBound('g', 1, 9.81);

%% STEP3: set constraints    
r_b      = 1;           % beam length [m]
theta_b  = deg2rad(30); % max angle [deg]
dtheta_b = deg2rad(50); % max angular speed [deg/s]
tau_b    = 20;          % bound torque [Nm]

nlp.setBound('time'  ,  ':' ,  1,FINALTIME);           %   T0 <= T <= Tf
nlp.setBound('r'     ,  ':' ,      -r_b , r_b);        % xmin <= x <= xmax
nlp.setBound('theta' ,  ':' ,  -theta_b , theta_b);    % xmin <= x <= xmax
nlp.setBound('dtheta',  ':' , -dtheta_b , dtheta_b);   % xmin <= x <= xmax
nlp.setBound('tau'   ,  ':' ,    -tau_b , tau_b);      % umin <= u <= umax

%% STEP4: set boundary conditions
% Intial conditions
nlp.setBound('r'      , 1  ,-0.8); % x(t=0) = x0
nlp.setBound('dr'     , 1  , 0.3); % x(t=0) = x0
nlp.setBound('theta'  , 1  , deg2rad(5)); % x(t=0) = x0
nlp.setBound('dtheta' , 1  , 0.0); % x(t=0) = x0

% Final conditions
nlp.setBound('r'      , 'end', 0);
nlp.setBound('dr'     , 'end', 0);
nlp.setBound('theta'  , 'end', 0);
nlp.setBound('dtheta' , 'end', 0);

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