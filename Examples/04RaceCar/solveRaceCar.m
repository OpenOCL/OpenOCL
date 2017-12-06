%% Title: Race Car Problem Example
%  Author: PhD students Jonas Koenneman & Giovanni Licitra

DISCRETIZATIONPOINTS = 100;    % horizon discretization

%% Create system and OCP
system = RaceCarSystem();
ocp    = RaceCarOCP(system);

%% STEP1: Get and set solver options
options = Solver.getOptions;
options.iterationCallback = false;
options.nlp.controlIntervals = DISCRETIZATIONPOINTS;
nlp = Solver.getNLP(ocp,system,options);

%% STEP2: set parameters
% car
m    = 1;    % mass [kg]
A    = 1;    % section area car [m^2]
cd   = 0.35; % drag coefficient [mini cooper 2008]
rho  = 1.23; % airdensity [kg/m^3]
Vmax = 1;    % max velocity [m/s]
Fmax   = 1;       % [N] 

% road
road_bound = 0.4; % [m]

nlp.setBound('m'   , 1, m);
nlp.setBound('A'   , 1, A);
nlp.setBound('cd'  , 1, cd);
nlp.setBound('rho' , 1, rho);
nlp.setBound('Vmax', 1, Vmax);
nlp.setBound('Fmax', 1, Fmax);

nlp.setBound('road_bound', 1, road_bound);


%% STEP3: set constraints    
FINALTIME = 20; % [s]

nlp.setBound('time',':', 0,FINALTIME);       %   T0 <= T <= Tf
% nlp.setBound('Fx'  ,':' , -F_bound, F_bound);% umin <= u <= umax
% nlp.setBound('Fy'  ,':' , -F_bound, F_bound);% umin <= u <= umax

%% STEP4: set boundary conditions
% Intial conditions
nlp.setBound( 'x', 1  , 0.0); % x(t=0) = x0
nlp.setBound('vx', 1  , 0.0); % x(t=0) = x0
nlp.setBound( 'y', 1  , 0.0); % x(t=0) = x0
nlp.setBound('vy', 1  , 0.0); % x(t=0) = x0

% Final conditions
nlp.setBound( 'x','end', 2*pi); % x(t=T) = xf
nlp.setBound('vx','end', 0.0 ); % x(t=T) = xf
nlp.setBound( 'y','end', 0.0 ); % x(t=T) = xf
nlp.setBound('vy','end', 0.0 ); % x(t=T) = xf

%% initialize NLP 
solver          = Solver.getSolver(nlp,options); % Create solver
initialGuess    = nlp.getInitialGuess;           

% initialize in the middle lane
N        = length(initialGuess.get('states').get('x').value); % get number of collocation points
x_road   = linspace(0,2*pi,N);
y_center = sin(x_road);
initialGuess.get('states').get('x').set(x_road);
initialGuess.get('states').get('y').set(y_center);

%% Solve OCP
[solution,times] = solver.solve(initialGuess);    % Run solver to obtain solution
times = times.value;

%% Plote solution
figure('units','normalized','outerposition',[0 0 1 1])
subplot(3,2,1);hold on;grid on; 
plot(times,solution.get('states').get('x').value,'Color','b','LineWidth',1.5);
plot(times,solution.get('states').get('y').value,'Color','r','LineWidth',1.5);
ylabel('[m]');legend({'x','y'});

subplot(3,2,3);hold on;grid on; 
vx = solution.get('states').get('vx').value;
vy = solution.get('states').get('vy').value;
V  = sqrt(vx.^2+vy.^2);

plot(times,vx,'Color','b','LineWidth',1.5);
plot(times,vy,'Color','r','LineWidth',1.5);
plot(times,V,'Color','g','LineWidth',1.5);
legend({'vx','vy','V'});
plot(times,Vmax.*ones(1,length(times)),'Color','k','LineWidth',1.5,'LineStyle','-.')
ylabel('[m/s]');

subplot(3,2,5);hold on;grid on; 
plot(times(1:end-1),solution.get('controls').get('Fx').value,'Color','b','LineWidth',1.5)
plot(times(1:end-1),solution.get('controls').get('Fy').value,'Color','r','LineWidth',1.5)
legend({'Fx','Fy'});
plot(times(1:end-1),-F_bound.*ones(1,length(times(1:end-1))),'Color','k','LineWidth',1.5,'LineStyle','-.')
plot(times(1:end-1), F_bound.*ones(1,length(times(1:end-1))),'Color','k','LineWidth',1.5,'LineStyle','-.')
ylabel('[N]');xlabel('time');

% build street
subplot(3,2,[2,4,6]);hold on;grid on; 
x_road   = linspace(0,2*pi,1000);
y_center = sin(x_road);

y_max = y_center + road_bound;
y_min = y_center - road_bound;

plot(x_road,y_center,'Color','k','LineWidth',0.5,'LineStyle','--');
plot(x_road,y_min   ,'Color','k','LineWidth',0.5,'LineStyle','-');
plot(x_road,y_max   ,'Color','k','LineWidth',0.5,'LineStyle','-');
plot(solution.get('states').get( 'x').value,...
     solution.get('states').get( 'y').value,'Color','b','LineWidth',1.5);
axis equal;xlabel('x[m]');ylabel('y[m]');

%% Show Animation
animateRaceCar(times,solution,x_road,y_center,y_min,y_max)