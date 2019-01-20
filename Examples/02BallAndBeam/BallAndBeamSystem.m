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
      sh.addState('r',      'lb', -sh.r_b,      'ub', sh.r_b      );
      sh.addState('dr');
      sh.addState('theta',  'lb', -sh.theta_b,  'ub', sh.theta_b  );
      sh.addState('dtheta', 'lb', -sh.dtheta_b, 'ub', sh.dtheta_b );
      
      % addControl(id,size,lowerBound,upperBound)
      sh.addControl('tau',  'lb', -sh.tau_b,    'ub', sh.tau_b    );
      
      % addParamter(id,size,defaultValue)
      sh.addParameter('I', 'default', 0.5       ); % Inertia Beam 
      sh.addParameter('J', 'default', 25*10^(-3)); % Inertia Ball
      sh.addParameter('m', 'default', 2         ); % mass ball
      sh.addParameter('R', 'default', 0.05      ); % radious ball
      sh.addParameter('g', 'default', 9.81      ); % gravity
    end
    function setupEquations(sh,x,~,u,p)
      I = p.I;
      J = p.J;
      m = p.m;
      R = p.R;
      g = p.g;

      r      = x.r;
      dr     = x.dr;
      theta  = x.theta;
      dtheta = x.dtheta;
      tau    = u.tau;

      sh.setODE('theta' ,dtheta); 
      sh.setODE('dtheta',(tau - m*g*r*cos(theta) - 2*m*r*dr*dtheta)/(I + m*r^2));
      sh.setODE('r'     ,dr); 
      sh.setODE('dr'    ,(-m*g*sin(theta) + m*r*dtheta^2)/(m + J/R^2));
    end
  end
end

