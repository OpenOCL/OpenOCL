function dae(daeh,x,z,u,p)

M = 1;    % mass of the cart [kg]
m = 0.1;  % mass of the ball [kg]
l = 0.8;  % length of the rod [m]
g = 9.81; % gravity constant [m/s^2]

v = x.v; 
theta = x.theta;
omega = x.omega;
F = u.F;

a = (- l*m*sin(theta)*omega.^2 + F ...
  + g*m*cos(theta)*sin(theta))/(M + m - m*cos(theta).^2);

domega = (- l*m*cos(theta)*sin(theta)*omega.^2 + ...
  F*cos(theta) + g*m*sin(theta) + ...
  M*g*sin(theta))/(l*(M + m - m*cos(theta).^2));

daeh.setODE('p',     v);
daeh.setODE('theta', omega);
daeh.setODE('v',     a);
daeh.setODE('omega', domega);
