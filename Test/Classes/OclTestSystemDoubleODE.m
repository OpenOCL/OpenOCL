classdef OclTestSystemDoubleODE < OclSystem
  methods (Static)
    function setupVariables(self)    
      self.addState('x');
    end
    function setupEquation(self,x,z,u,p)   
      self.setODE('x',x);
      self.setODE('x',x+x);
    end
  end
end

