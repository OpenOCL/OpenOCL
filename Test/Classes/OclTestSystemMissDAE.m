classdef OclTestSystemMissDAE < OclSystem
  methods (Static)
    function setupVariables(self)    
      self.addState('x');
      self.addAlgVar('z');
    end
    function setupEquation(self,x,z,u,p)   
      self.setODE('x',x);
    end
  end
end

