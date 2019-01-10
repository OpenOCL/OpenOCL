classdef VanDerPolSystem < OclSystem
  % The system is defined by inheriting from the System class

  methods
    function setupVariables(self)    
      % Define two scalar state variables
      self.addState('x');
      self.addState('y');
      
      % Define a scalar control variable
      self.addControl('u');
    end
    function setupEquation(self,states,algVars,controls,parameters)     
      % Get access to the system variables
      x = states.x;
      y = states.y;
      u = controls.u;
      
      % Define differential equations
      self.setODE('x',(1-y^2)*x - y + u); 
      self.setODE('y',x);
    end
  end
end

