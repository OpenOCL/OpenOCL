classdef ExampleSystem < System
  % The system is defined by inheriting from the System class
  % and implementing its abstract methods
  methods
    function setupVariables(self)
      % State, control, and algebraic variables can be defined
      % by implementing the setupVariables method 
      
      % Define two scalar state variables
      self.addState('x',[1,1]);
      self.addState('y',[1,1]);
      
      % Define a scalar control variable
      self.addControl('u',[1,1]);
      
      % Define a 3x1 algebraic variables
      self.addAlgVar('z',[3,1]);
      
    end
    function setupEquation(self,state,algVars,controls,parameters)
      % The differential and algebraic equations of the system are 
      % implemented in the setupEquation method
      
      % Get access to the system variables
      x = state.get('x').value;
      y = state.get('y').value;
      u = controls.get('u').value;
      z = algVars.get('z').value;
      
      % Define differential equations
      self.setODE('x',(1-y^2)*x - y + u); 
      self.setODE('y',x);
      
      % Define algebraic equation
      self.setAlgEquation(z - [x;y;x+y+u]);
      
    end
  end
end

