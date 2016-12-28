classdef Integrator < handle
  %INTEGRATOR Integrator class
  %   Is able to integrate model
  
  properties(Access = private)
    model
  end
  
  methods(Abstract)
    [finalState, finalAlgVars, costs] = evaluate(self,state,integratorVars,controls,startTime,finalTime,parameters)
  end
  
  methods
    
    function self = Integrator(model)
      self.model = model;
    end
    
  end
  
end

