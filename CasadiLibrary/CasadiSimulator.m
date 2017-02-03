classdef CasadiSimulator < Simulator
  
  properties
    integrator
    h
  end
  
  methods
    
    function self = CasadiSimulator(model,h)
      self.integrator = CasadiIntegrator(model);
      self.h = h;
    end
    
    function [state, algState] = evaluate(self,state,algState,controls,N)
      
      for i=1:N
        [state, algState] = self.integrator.evaluate(state,algState,controls,self.h);
      end
      
    end
  
  end

end

