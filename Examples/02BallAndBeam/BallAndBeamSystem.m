classdef BallAndBeamSystem < OclSystem
  methods
    function setupVariables(self)
      
      % bounds
      r_b      = 1;           % beam length [m]
      theta_b  = deg2rad(30); % max angle [deg]
      dtheta_b = deg2rad(50); % max angular speed [deg/s]
      tau_b    = 20;          % bound torque [Nm]

      % addState(id,size,lowerBound,upperBound)
      self.addState('r',      1, -r_b      , r_b      );
      self.addState('dr',     1, -theta_b  , theta_b  );
      self.addState('theta'                           );
      self.addState('dtheta', 1, -dtheta_b , dtheta_b );
      
      % addControl(id,size,lowerBound,upperBound)
      self.addControl('tau',  1, -tau_b    , tau_b    );
      
      % addParamter(id,size,defaultValue)
      self.addParameter('I',1, 0.5);        % Inertia Beam 
      self.addParameter('J',1, 25*10^(-3)); % Inertia Ball
      self.addParameter('m',1, 2);          % mass ball
      self.addParameter('R',1, 0.05);       % radious ball
      self.addParameter('g',1, 9.81);       % gravity
    end
    function setupEquation(self,states,algVars,controls,parameters)
      I = parameters.I;
      J = parameters.J;
      m = parameters.m;
      R = parameters.R;
      g = parameters.g;

      r      = states.r;
      dr     = states.dr;
      theta  = states.theta;
      dtheta = states.dtheta;
      tau    = controls.tau;

      self.setODE('theta' ,dtheta); 
      self.setODE('dtheta',(tau - m*g*r*cos(theta) - 2*m*r*dr*dtheta)/(I + m*r^2));
      self.setODE('r'     ,dr); 
      self.setODE('dr'    ,(-m*g*sin(theta) + m*r*dtheta^2)/(m + J/R^2));
    end
  end
end

