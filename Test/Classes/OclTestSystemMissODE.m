classdef OclTestSystemMissODE < OclSystem
  methods (Static)
    function setupVariables(self)    
      self.addState('x')
    end
    function setupEquation(self,x,z,u,p)     
    end
  end
end

