classdef Integrator < handle
  %INTEGRATOR Integrator class
  %   Is able to integrate system
  
  properties
    system
  end
  
  methods(Abstract)
    [finalStates, finalAlgVars, costs] = evaluate(self,states,integratorVars,controls,startTime,finalTime,parameters)
  end
  
  methods
    
    function self = Integrator(system)
      self.system = system;
    end
    
  end
  
end

