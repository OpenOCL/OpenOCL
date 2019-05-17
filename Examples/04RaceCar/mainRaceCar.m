% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Copyright 2015-2018 Jonas Koennemanm, Giovanni Licitra
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
function [solution,times,solver] = mainRaceCar 
  % Title: Race Car Problem Example
  %  Authors: Jonas Koenneman & Giovanni Licitra

  CONTROL_INTERVALS = 50;     % control discretization
  MAX_TIME = 20;              % [s]

  options = ocl.Options();
  options.nlp.controlIntervals = CONTROL_INTERVALS;
  options.controls_regularization_value = 1e-3;

  system = ocl.System('varsfun', @varsfun, 'eqfun', @eqfun);
  ocp = ocl.OCP('arrivalcosts', @arrivalcosts, 'pathconstraints', @pathconstraints);

  solver = ocl.Solver([],system,ocp,options);

  % parameters
  m    = 1;         % mass [kg]
  A    = 1;         % section area car [m^2]
  cd   = 0.35;      % drag coefficient [mini cooper 2008]
  rho  = 1.23;      % airdensity [kg/m^3]
  Vmax = 1;         % max velocity [m/s]
  Fmax   = 1;       % [N]
  road_bound = 0.4; % [m]

  solver.setParameter('m'   , m);
  solver.setParameter('A'   , A);
  solver.setParameter('cd'  , cd);
  solver.setParameter('rho' , rho);
  solver.setParameter('Vmax', Vmax);
  solver.setParameter('Fmax', Fmax);
  solver.setParameter('road_bound', road_bound);
  
  solver.setBounds('time', 0, MAX_TIME);

  solver.setInitialBounds( 'x',   0.0);
  solver.setInitialBounds('vx',   0.0);
  solver.setInitialBounds( 'y',   0.0);
  solver.setInitialBounds('vy',   0.0);

  solver.setEndBounds( 'x',  2*pi);
  solver.setEndBounds('vx',  0.0 );
  solver.setEndBounds( 'y',  0.0 );
  solver.setEndBounds('vy',  0.0 );

  initialGuess    = solver.getInitialGuess();

  % Initialize the middle lane
  N        = length(initialGuess.states.x.value);
  x_road   = linspace(0,2*pi,N);
  y_center = sin(x_road);
  initialGuess.states.x.set(x_road);
  initialGuess.states.y.set(y_center);

  % Solve OCP
  [solution,times] = solver.solve(initialGuess);

  % Plot solution
  figure('units','normalized')
  subplot(3,2,1);hold on;grid on;
  plot(times.states.value,solution.states.x.value,'Color','b','LineWidth',1.5);
  plot(times.states.value,solution.states.y.value,'Color','r','LineWidth',1.5);
  ylabel('[m]');legend({'x','y'});

  subplot(3,2,3);hold on;grid on;
  vx = solution.states.vx.value;
  vy = solution.states.vy.value;
  V  = sqrt(vx.^2+vy.^2);

  plot(times.states.value,vx,'Color','b','LineWidth',1.5);
  plot(times.states.value,vy,'Color','r','LineWidth',1.5);
  plot(times.states.value,V,'Color','g','LineWidth',1.5);
  legend({'vx','vy','V'});
  plot(times.states.value,Vmax.*ones(1,length(times)),'Color','k','LineWidth',1.5,'LineStyle','-.')
  ylabel('[m/s]');

  subplot(3,2,5);hold on;grid on;
  plot(times.states.value,solution.states.Fx.value,'Color','b','LineWidth',1.5)
  plot(times.states.value,solution.states.Fy.value,'Color','r','LineWidth',1.5)
  legend({'Fx','Fy'});
  plot(times.states.value,-Fmax.*ones(1,length(times.states.value)),'Color','k','LineWidth',1.5,'LineStyle','-.')
  plot(times.states.value, Fmax.*ones(1,length(times.states.value)),'Color','k','LineWidth',1.5,'LineStyle','-.')
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
  animateRaceCar(times.states.value,solution,x_road,y_center,y_min,y_max)

end

function varsfun(sh)
  sh.addState('x');   % position x[m]
  sh.addState('vx');  % velocity vx[m/s]
  sh.addState('y');   % position y[m]
  sh.addState('vy');  % velocity vy[m/s]

  sh.addState('Fx');  % Force x[N]
  sh.addState('Fy');  % Force y[N]
  
  sh.addState('time');  % time [s]

  sh.addControl('dFx');  % Force x[N]
  sh.addControl('dFy');  % Force y[N]

  sh.addParameter('m');           % mass [kg]
  sh.addParameter('A');           % section area car [m^2]
  sh.addParameter('cd');          % drag coefficient [mini cooper 2008
  sh.addParameter('rho');         % airdensity [kg/m^3]
  sh.addParameter('Vmax');        % max speed [m/s]
  sh.addParameter('road_bound');  % lane road relative to the middle lane [m]
  sh.addParameter('Fmax');        % maximal force on the car [N]
end

function eqfun(sh,x,z,u,p)
  sh.setODE( 'x', x.vx);
  sh.setODE('vx', 1/p.m*x.Fx - 0.5*p.rho*p.cd*p.A*x.vx^2);
  sh.setODE( 'y', x.vy);
  sh.setODE('vy', 1/p.m*x.Fy - 0.5*p.rho*p.cd*p.A*x.vx^2);
  sh.setODE('Fx', u.dFx);
  sh.setODE('Fy', u.dFy);
  
  sh.setODE('time', 1);
end

function arrivalcosts(ch,x,p)
  ch.add(x.time);
end

function pathconstraints(ch,x,p)
  % speed constraint
  ch.add(x.vx^2+x.vy^2, '<=', p.Vmax^2);

  % force constraint
  ch.add(x.Fx^2+x.Fy^2, '<=', p.Fmax^2);

  % road bounds
  y_center = sin(x.x);
  y_max = y_center + p.road_bound;
  y_min = y_center - p.road_bound;
  ch.add(x.y,'<=',y_max);
  ch.add(x.y,'>=',y_min);
end
