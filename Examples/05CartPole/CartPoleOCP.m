classdef CartPoleOCP < OclOCP
  
  methods (Static)
    function arrivalCosts(self,x,tf,p)      
      self.add( tf );
    end 
  end
end
