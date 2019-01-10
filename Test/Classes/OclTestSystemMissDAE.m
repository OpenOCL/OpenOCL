classdef OclTestSystemMissDAE < OclSystem
  methods
    function setupVariables(self)    
      self.addState('x');
      self.addAlgVar('z');
    end
    function setupEquation(self,x,z,u,p)   
      self.setODE('x',x);
    end
  end
end

