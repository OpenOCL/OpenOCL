classdef BallAndBeamSystem < OclSystem
  methods
    function setupVariables(self)
      self.addState('r');
      self.addState('dr');
      self.addState('theta');
      self.addState('dtheta');
      
      self.addControl('tau');
      
      self.addParameter('I'); % Inertia Beam 
      self.addParameter('J'); % Inertia Ball
      self.addParameter('m'); % mass ball
      self.addParameter('R'); % radious ball
      self.addParameter('g'); % gravity
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

