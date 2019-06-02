% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Copyright 2015-2018 Jonas Koennemanm, Giovanni Licitra
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
function [vars,times,solver] = ballandbeam
  % Title: Ball and beam problem
  %  Authors: Jonas Koenneman & Giovanni Licitra

  conf = struct;
  conf.r_b      = 1;           % beam length [m]
  conf.theta_b  = deg2rad(30); % max angle [deg]
  conf.dtheta_b = deg2rad(50); % max angular speed [deg/s]
  conf.tau_b    = 20;          % bound torque [Nm]

  conf.L = 1;                  % length of beam [m]
  conf.I = 0.5;                % Inertia beam
  conf.J = 25*10^(-3);         % Inertia ball
  conf.m = 2;                  % mass ball
  conf.R = 0.05;               % radius ball
  conf.g = 9.81;               % gravity

  conf.costQ = eye(4);         % least squares path costs states weighting matrix
  conf.costR = 1;              % least squares path costs controls weighting matrix

  varsfun    = @(sh) bbvarsfun(sh, conf);
  daefun      = @(sh,x,~,u,p) bbeqfun(sh,x,u,conf);
  pathcosts  = @(ch,x,~,u,~,~,~) bbpathcosts(ch,x,u,conf);

  options = ocl.Options();
  options.nlp.controlIntervals = 50;

  system = ocl.System(varsfun, daefun);
  ocp = ocl.OCP(pathcosts);

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
  plot(times.states.value, conf.r_b*ones(length(times)),'Color','b','LineWidth',1.0,'LineStyle','-.');
  plot(times.states.value, conf.r_b*ones(length(times)),'Color','b','LineWidth',1.0,'LineStyle','-.');

  subplot(3,1,2);hold on;grid on;
  plot(times.states.value,rad2deg(vars.states.theta.value) ,'Color','b','LineWidth',1.5)
  plot(times.states.value,rad2deg(vars.states.dtheta.value),'Color','r','LineWidth',1.5)
  legend({'\theta [deg]','dtheta [deg/s]'})
  plot(times.states.value, rad2deg(  conf.theta_b.*ones(length(times))),'Color','b','LineWidth',1.0,'LineStyle','-.');
  plot(times.states.value, rad2deg( -conf.theta_b.*ones(length(times))),'Color','b','LineWidth',1.0,'LineStyle','-.');
  plot(times.states.value, rad2deg( conf.dtheta_b.*ones(length(times))),'Color','r','LineWidth',1.0,'LineStyle','-.');
  plot(times.states.value, rad2deg(-conf.dtheta_b.*ones(length(times))),'Color','r','LineWidth',1.0,'LineStyle','-.');

  subplot(3,1,3);hold on;grid on;
  stairs(times.controls.value,vars.controls.tau.value,'Color','g','LineWidth',1.5)
  plot(times.states.value, conf.tau_b.*ones(length(times)),'Color','g','LineWidth',1.0,'LineStyle','-.');
  plot(times.states.value,-conf.tau_b.*ones(length(times)),'Color','g','LineWidth',1.0,'LineStyle','-.');
  legend({'\tau [Nm]'})
  xlabel('time');

  % Show Animation
  bbanimate(times.states.value,vars.states.r.value,vars.states.theta.value,conf);

end
function bbvarsfun(sh, c)
  sh.addState('r',      'lb', -c.r_b,      'ub', c.r_b      );
  sh.addState('dr');
  sh.addState('theta',  'lb', -c.theta_b,  'ub', c.theta_b  );
  sh.addState('dtheta', 'lb', -c.dtheta_b, 'ub', c.dtheta_b );
  
  sh.addState('time');

  sh.addControl('tau',  'lb', -c.tau_b,    'ub', c.tau_b    );
end

function bbeqfun(sh,x,u,c)
  sh.setODE('theta' ,x.dtheta);
  sh.setODE('dtheta',(u.tau - c.m*c.g*x.r*cos(x.theta) - 2*c.m*x.r*x.dr*x.dtheta)/(c.I + c.m*x.r^2));
  sh.setODE('r'     ,x.dr);
  sh.setODE('dr'    ,(-c.m*c.g*sin(x.theta) + c.m*x.r*x.dtheta^2)/(c.m + c.J/c.R^2));
  
  sh.setODE('time'    , 1);
end

function bbpathcosts(ch,x,u,c)
  ch.add( x(1:end-1).'*c.costQ*x(1:end-1) );
  ch.add( u.'*c.costR*u );
end

function bbanimate(times,rTrajectory,thetaTrajectory,c)

  % Initialize animation
  xbeam = c.L*cos(thetaTrajectory(1));
  ybeam = c.L*sin(thetaTrajectory(1));
  Xbeam = [-xbeam,xbeam];
  Ybeam = [-ybeam,ybeam];
  Xball = rTrajectory(1)*cos(thetaTrajectory(1));
  Yball = rTrajectory(1)*sin(thetaTrajectory(1));

  figure;hold on;grid on;
  Beam = plot(Xbeam,Ybeam,'LineWidth',4,'Color','b');
  plot(0,0,'Marker','o','MarkerEdgeColor','k','MarkerFaceColor','y','MarkerSize',22)
  Ball = plot(Xball,Yball,'Marker','o','MarkerEdgeColor','k','MarkerFaceColor','r','MarkerSize',22);
  axis([-1.2, 1.2, -0.7, 0.7]);
  xlabel('x [m]');ylabel('y [m]');

  for i = 2:1:length(times)
    xbeam = c.L*cos(thetaTrajectory(i));
    ybeam = c.L*sin(thetaTrajectory(i));
    Xbeam = [-xbeam,xbeam];
    Ybeam = [-ybeam,ybeam];
    Xball = rTrajectory(i)*cos(thetaTrajectory(i));
    Yball = rTrajectory(i)*sin(thetaTrajectory(i));

    set(Beam, 'XData', Xbeam);
    set(Beam, 'YData', Ybeam);
    set(Ball, 'XData', Xball);
    set(Ball, 'YData', Yball);

    if ~oclIsTestRun()
      pause(times(i)-times(i-1));
    end

    drawnow
  end

end
