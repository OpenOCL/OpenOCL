% This file defines the system and optimal control problem
% for the Ball and Beam example.

function bb = BallAndBeam()
  % Returns a struct with the parameters (configuration)
  % and the function handles to the system and ocp functions.
  configuration = struct;
  configuration.r_b      = 1;           % beam length [m]
  configuration.theta_b  = deg2rad(30); % max angle [deg]
  configuration.dtheta_b = deg2rad(50); % max angular speed [deg/s]
  configuration.tau_b    = 20;          % bound torque [Nm]

  configuration.L = 1;                  % length of beam [m]
  configuration.I = 0.5;                % Inertia beam
  configuration.J = 25*10^(-3);         % Inertia ball
  configuration.m = 2;                  % mass ball
  configuration.R = 0.05;               % radius ball
  configuration.g = 9.81;               % gravity

  configuration.Q = eye(4);             % LS path costs states weighting matrix
  configuration.R = 1;             % LS path costs controls weighting matrix

  bb = struct;
  bb.varsfun    = @(sh) bbvarsfun(sh, configuration);
  bb.eqfun      = @(sh,x,~,u,p) bbeqfun(sh,x,u,p,configuration);
  bb.pathcosts  = @(ch,x,~,u,~,~,~) bbpathcosts(ch,x,u,configuration);
  bb.animate    = @(t,r,theta) bbanimate(t,r,theta,configuration);
  bb.c = configuration;

end

function bbvarsfun(sh, c)
  sh.addState('r',      'lb', -c.r_b,      'ub', c.r_b      );
  sh.addState('dr');
  sh.addState('theta',  'lb', -c.theta_b,  'ub', c.theta_b  );
  sh.addState('dtheta', 'lb', -c.dtheta_b, 'ub', c.dtheta_b );

  sh.addControl('tau',  'lb', -c.tau_b,    'ub', c.tau_b    );
end

function bbeqfun(sh,x,u,p,c)
  sh.setODE('theta' ,x.dtheta);
  sh.setODE('dtheta',(u.tau - c.m*c.g*x.r*cos(x.theta) - 2*c.m*x.r*x.dr*x.dtheta)/(c.I + c.m*x.r^2));
  sh.setODE('r'     ,x.dr);
  sh.setODE('dr'    ,(-c.m*c.g*sin(x.theta) + c.m*x.r*x.dtheta^2)/(c.m + c.J/c.R^2));
end

function bbpathcosts(ch,x,u,c)
  ch.add( x.'*c.Q*x );
  ch.add( u.'*c.R*u );
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
