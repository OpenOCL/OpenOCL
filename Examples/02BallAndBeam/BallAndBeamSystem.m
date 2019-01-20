classdef BallAndBeamSystem < OclSystem
  properties
    r_b
    theta_b
    dtheta_b
    tau_b
  end
  
  methods 
    function self = BallAndBeamSystem()
      self.r_b      = 1;           % beam length [m]
      self.theta_b  = deg2rad(30); % max angle [deg]
      self.dtheta_b = deg2rad(50); % max angular speed [deg/s]
      self.tau_b    = 20;          % bound torque [Nm]
    end
  end
  
  methods (Static)
    function setupVariables(sh)
      % addState(id,size,lowerBound,upperBound)
      sh.addState('r', 1, -sh.r_b, sh.r_b);
      sh.addState('dr');
      sh.addState('theta', 1,  -sh.theta_b, sh.theta_b);
      sh.addState('dtheta', 1, -sh.dtheta_b, sh.dtheta_b );
      
      % addControl(id,size,lowerBound,upperBound)
      sh.addControl('tau',  1, -sh.tau_b    , sh.tau_b    );
      
      % addParamter(id,size,defaultValue)
      sh.addParameter('I',1, 0.5);        % Inertia Beam 
      sh.addParameter('J',1, 25*10^(-3)); % Inertia Ball
      sh.addParameter('m',1, 2);          % mass ball
      sh.addParameter('R',1, 0.05);       % radious ball
      sh.addParameter('g',1, 9.81);       % gravity
    end
    function setupEquations(sh,states,algVars,controls,parameters)
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

      sh.setODE('theta' ,dtheta); 
      sh.setODE('dtheta',(tau - m*g*r*cos(theta) - 2*m*r*dr*dtheta)/(I + m*r^2));
      sh.setODE('r'     ,dr); 
      sh.setODE('dr'    ,(-m*g*sin(theta) + m*r*dtheta^2)/(m + J/R^2));
    end
  end
end

