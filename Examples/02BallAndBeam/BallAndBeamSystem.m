classdef BallAndBeamSystem < OclSystem
  properties
    r_b
    theta_b
    dtheta_b
    tau_b
  end
  methods
  
    function self = BallAndBeamSystem()
      % bounds

    end
  
    function setupVariables(self)
      
      self.r_b      = 1;           % beam length [m]
      self.theta_b  = deg2rad(30); % max angle [deg]
      self.dtheta_b = deg2rad(50); % max angular speed [deg/s]
      self.tau_b    = 20;          % bound torque [Nm]

      % addState(id,size,lowerBound,upperBound)
      self.addState('r',      1, -self.r_b      , self.r_b      );
      self.addState('dr'                                        );
      self.addState('theta',  1, -self.theta_b  , self.theta_b  );
      self.addState('dtheta', 1, -self.dtheta_b , self.dtheta_b );
      
      % addControl(id,size,lowerBound,upperBound)
      self.addControl('tau',  1, -self.tau_b    , self.tau_b    );
      
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

