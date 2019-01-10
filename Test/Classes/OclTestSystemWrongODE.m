classdef OclTestSystemWrongODE < OclSystem
  methods
    function setupVariables(self)    
      self.addState('x');
    end
    function setupEquation(self,x,z,u,p)   
      self.setODE('x',x);
      self.setODE('y',x+x);
    end
  end
end

