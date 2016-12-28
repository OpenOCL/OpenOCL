classdef RK4Integrator < Integrator
  %RKINTEGRATOR Runge Kutta Intergrator of order 4
  
  properties
  end
  
  methods
    
    function self = RK4Integrator(model)
      self = self@Integrator(model);
    end

    function ni = getNumberIntegratorVars(self)
      ni = 0;
    end
    
    function [finalState, finalAlgVars, costs, equations] = evaluate(self,state,integratorVars,controls,startTime,finalTime,parameters)
  
      
      if ~isempty(integratorVars)
        error('Algebraic variables not supported in explicit RK4 integrator.');
      end
      
      x = state;
      u = controls;
      z = [];
      h = endTime - startTime;
      
      k1 = self.model.evaluate(x,       z,u,startTime,parameters);
      k2 = self.model.evaluate(x+h/2*k1,z,u,startTime,parameters);
      k3 = self.model.evaluate(x+h/2*k2,z,u,startTime,parameters);
      k4 = self.model.evaluate(x+h*k3,  z,u,startTime,parameters);
      xf = x + h/6 * (k1 + 2*k2 + 2*k3 + k4); 
      
      finalState = xf;
      finalAlgVars = [];
      equations = [];

     
      
    end
    
  end
  
end

