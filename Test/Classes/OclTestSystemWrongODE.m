classdef OclTestSystemWrongODE < OclSystem
  methods (Static)
    function setupVariables(self)    
      self.addState('x');
    end
    function setupEquations(self,x,z,u,p)   
      self.setODE('x',x);
      self.setODE('y',x+x);
    end
  end
end

