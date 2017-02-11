classdef Integrator < handle
  %INTEGRATOR Integrator class
  %   Is able to integrate system
  
  properties
    system
  end
  
  methods(Abstract)
    [finalState, finalAlgVars, costs] = evaluate(self,state,integratorVars,controls,startTime,finalTime,parameters)
  end
  
  methods
    
    function self = Integrator(system)
      self.system = system;
    end
    
  end
  
end

