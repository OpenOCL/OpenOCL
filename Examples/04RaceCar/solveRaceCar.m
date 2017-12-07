%% Title: Race Car Problem Example
%  Author: PhD students Jonas Koenneman & Giovanni Licitra

DISCRETIZATIONPOINTS = 100;    % horizon discretization

%% Create system and OCP
system = RaceCarSystem();
ocp    = RaceCarOCP(system);

%% Get and set solver options
options = Solver.getOptions;
options.iterationCallback = false;
options.nlp.controlIntervals = DISCRETIZATIONPOINTS;
nlp = Solver.getNLP(ocp,system,options);

%% set parameters
% car
m    = 1;    % mass [kg]
A    = 1;    % section area car [m^2]
cd   = 0.35; % drag coefficient [mini cooper 2008]
rho  = 1.23; % airdensity [kg/m^3]
Vmax = 1;    % max velocity [m/s]
Fmax   = 1;  % [N] 

% road
road_bound = 0.4; % [m]

nlp.setParameter('m'   , m);
nlp.setParameter('A'   , A);
nlp.setParameter('cd'  , cd);
nlp.setParameter('rho' , rho);
nlp.setParameter('Vmax', Vmax);
nlp.setParameter('Fmax', Fmax);
nlp.setParameter('road_bound', road_bound);

% time
FINALTIME = 20; % [s]
nlp.setParameter('time', 0,FINALTIME);       %   T0 <= T <= Tf

%% set boundary conditions
% Intial conditions
nlp.setInitialBound( 'x',   0.0); % x(t=0) = x0
nlp.setInitialBound('vx',   0.0); % x(t=0) = x0
nlp.setInitialBound( 'y',   0.0); % x(t=0) = x0
nlp.setInitialBound('vy',   0.0); % x(t=0) = x0

% Final conditions
nlp.setEndBound( 'x',  2*pi); % x(t=T) = xf
nlp.setEndBound('vx',  0.0 ); % x(t=T) = xf
nlp.setEndBound( 'y',  0.0 ); % x(t=T) = xf
nlp.setEndBound('vy',  0.0 ); % x(t=T) = xf

%% initialize NLP 
solver          = Solver.getSolver(nlp,options); % Create solver
initialGuess    = nlp.getInitialGuess;           

% initialize in the middle lane
N        = length(initialGuess.states.x.value); % get number of collocation points
x_road   = linspace(0,2*pi,N);
y_center = sin(x_road);
initialGuess.states.x.set(x_road);
initialGuess.states.y.set(y_center);

%% Solve OCP
[solution,times] = solver.solve(initialGuess);    % Run solver to obtain solution
times = times.value;

%% Plote solution
figure('units','normalized','outerposition',[0 0 1 1])
subplot(3,2,1);hold on;grid on; 
plot(times,solution.states.x.value,'Color','b','LineWidth',1.5);
plot(times,solution.states.y.value,'Color','r','LineWidth',1.5);
ylabel('[m]');legend({'x','y'});

subplot(3,2,3);hold on;grid on; 
vx = solution.states.vx.value;
vy = solution.states.vy.value;
V  = sqrt(vx.^2+vy.^2);

plot(times,vx,'Color','b','LineWidth',1.5);
plot(times,vy,'Color','r','LineWidth',1.5);
plot(times,V,'Color','g','LineWidth',1.5);
legend({'vx','vy','V'});
plot(times,Vmax.*ones(1,length(times)),'Color','k','LineWidth',1.5,'LineStyle','-.')
ylabel('[m/s]');

subplot(3,2,5);hold on;grid on; 
plot(times(1:end-1),solution.controls.Fx.value,'Color','b','LineWidth',1.5)
plot(times(1:end-1),solution.controls.Fy.value,'Color','r','LineWidth',1.5)
legend({'Fx','Fy'});
plot(times(1:end-1),-Fmax.*ones(1,length(times(1:end-1))),'Color','k','LineWidth',1.5,'LineStyle','-.')
plot(times(1:end-1), Fmax.*ones(1,length(times(1:end-1))),'Color','k','LineWidth',1.5,'LineStyle','-.')
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
plot(solution.states.x.value,...
     solution.states.y.value,'Color','b','LineWidth',1.5);
axis equal;xlabel('x[m]');ylabel('y[m]');

%% Show Animation
animateRaceCar(times,solution,x_road,y_center,y_min,y_max)