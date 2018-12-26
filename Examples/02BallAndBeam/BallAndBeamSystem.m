classdef BallAndBeamSystem < System
  methods
    function setupVariables(self)
      self.addState('r'     ,[1,1]);
      self.addState('dr'    ,[1,1]);
      self.addState('theta' ,[1,1]);
      self.addState('dtheta',[1,1]);
      
      self.addControl('tau',[1,1]);
      
      self.addParameter('I',[1 1]); % Inertia Beam 
      self.addParameter('J',[1 1]); % Inertia Ball
      self.addParameter('m',[1 1]); % mass ball
      self.addParameter('R',[1 1]); % radious ball
      self.addParameter('g',[1 1]); % gravity
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

