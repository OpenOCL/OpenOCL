% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Copyright 2015-2018 Jonas Koennemanm, Giovanni Licitra
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
% This file defines the system and optimal control problem
% for the Ball and Beam example.
%
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

  configuration.costQ = eye(4);             % LS path costs states weighting matrix
  configuration.costR = 1;             % LS path costs controls weighting matrix

  bb = struct;
  bb.varsfun    = @(sh) bbvarsfun(sh, configuration);
  bb.eqfun      = @(sh,x,~,u,p) bbeqfun(sh,x,u,configuration);
  bb.pathcosts  = @(ch,x,~,u,~,~,~) bbpathcosts(ch,x,u,configuration);
  bb.animate    = @(t,r,theta) bbanimate(t,r,theta,configuration);
  bb.c = configuration;

end

