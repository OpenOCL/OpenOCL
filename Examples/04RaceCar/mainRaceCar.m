% Title: Race Car Problem Example
%  Authors: Jonas Koenneman & Giovanni Licitra

CONTROL_INTERVALS = 50;     % control discretization
MAX_TIME = 20;             % [s]

options = OclOptions();
options.debug = false;
options.nlp.controlIntervals = CONTROL_INTERVALS;

ocl = OclSolver(RaceCarSystem,RaceCarOCP,options);

% parameters
m    = 1;         % mass [kg]
A    = 1;         % section area car [m^2]
cd   = 0.35;      % drag coefficient [mini cooper 2008]
rho  = 1.23;      % airdensity [kg/m^3]
Vmax = 1;         % max velocity [m/s]
Fmax   = 1;       % [N] 
road_bound = 0.4; % [m]

ocl.setParameter('m'   , m);
ocl.setParameter('A'   , A);
ocl.setParameter('cd'  , cd);
ocl.setParameter('rho' , rho);
ocl.setParameter('Vmax', Vmax);
ocl.setParameter('Fmax', Fmax);
ocl.setParameter('road_bound', road_bound);
ocl.setParameter('time', 0, MAX_TIME);  

ocl.setInitialBounds( 'x',   0.0); 
ocl.setInitialBounds('vx',   0.0);
ocl.setInitialBounds( 'y',   0.0);
ocl.setInitialBounds('vy',   0.0);

ocl.setEndBounds( 'x',  2*pi);
ocl.setEndBounds('vx',  0.0 );
ocl.setEndBounds( 'y',  0.0 );
ocl.setEndBounds('vy',  0.0 );

initialGuess    = ocl.getInitialGuess();           

% Initialize the middle lane
N        = length(initialGuess.states.x.value);
x_road   = linspace(0,2*pi,N);
y_center = sin(x_road);
initialGuess.states.x.set(x_road);
initialGuess.states.y.set(y_center);

% Solve OCP
[solution,times] = ocl.solve(initialGuess);

% Plot solution
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

% Show Animation
animateRaceCar(times,solution,x_road,y_center,y_min,y_max)