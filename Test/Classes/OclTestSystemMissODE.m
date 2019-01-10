classdef OclTestSystemMissODE < OclSystem
  methods
    function setupVariables(self)    
      self.addState('x')
    end
    function setupEquation(self,x,z,u,p)     
    end
  end
end

