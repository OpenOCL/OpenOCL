function [solution,times,ocl] = mainRaceCar 
  % Title: Race Car Problem Example
  %  Authors: Jonas Koenneman & Giovanni Licitra

  CONTROL_INTERVALS = 50;     % control discretization
  MAX_TIME = 20;              % [s]

  options = OclOptions();
  options.nlp.controlIntervals = CONTROL_INTERVALS;
  options.controls_regularization_value = 1e-3;

  system = OclSystem('varsfun', @varsfun, 'eqfun', @eqfun);
  ocp = OclOCP('arrivalcosts', @arrivalcosts, 'pathconstraints', @pathconstraints);

  ocl = OclSolver([],system,ocp,options);

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
  ocl.setParameter('T', 0, MAX_TIME);

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

function varsfun(self)
  self.addState('x');   % position x[m]
  self.addState('vx');  % velocity vx[m/s]
  self.addState('y');   % position y[m]
  self.addState('vy');  % velocity vy[m/s]

  self.addState('Fx');  % Force x[N]
  self.addState('Fy');  % Force x[N]

  self.addControl('dFx');  % Force x[N]
  self.addControl('dFy');  % Force x[N]

  self.addParameter('m');           % mass [kg]
  self.addParameter('A');           % section area car [m^2]
  self.addParameter('cd');          % drag coefficient [mini cooper 2008
  self.addParameter('rho');         % airdensity [kg/m^3]
  self.addParameter('Vmax');        % max speed [m/s]
  self.addParameter('road_bound');  % lane road relative to the middle lane [m]
  self.addParameter('Fmax');        % maximal force on the car [N]
end

function eqfun(sh,x,z,u,p)
  sh.setODE( 'x', x.vx);
  sh.setODE('vx', 1/p.m*x.Fx - 0.5*p.rho*p.cd*p.A*x.vx^2);
  sh.setODE( 'y', x.vy);
  sh.setODE('vy', 1/p.m*x.Fy - 0.5*p.rho*p.cd*p.A*x.vx^2);
  sh.setODE('Fx', u.dFx);
  sh.setODE('Fy', u.dFy);
end

function arrivalcosts(ch,x,p)
  ch.add(p.T);
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
