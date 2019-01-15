classdef CartPoleOCP < OclOCP
  
  methods
    function pathCosts(self,x,z,u,t,tf,p)
    end
    function arrivalCosts(self,x,tf,p)      
      self.addArrivalCost( tf );
    end 
  end
end
