classdef VanDerPolSystem < OclSystem
  % The system is defined by inheriting from the System class

  methods
    function setupVariables(self)    
      % Scalar x:  -0.25 <= x <= inf
      % Scalar y: unbounded
      self.addState('x',1,-0.25,inf);
      self.addState('y');
      
      % Scalar u: -1 <= u <= 1
      self.addControl('u',1,-1,1);
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

