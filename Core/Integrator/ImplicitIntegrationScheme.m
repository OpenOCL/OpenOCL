classdef ImplicitIntegrationScheme < handle
  
  properties(Access = protected)
    model
  end
  
  methods(Abstract)
    var = getIntegratorVars(self)
    ni = getIntegratorVarsSize(self)
    [finalState, finalAlgVars, costs, equations] = evaluate(self,state,integratorVars,controls,startTime,finalTime,parameters)
  end
  
  methods
    
    function self = ImplicitIntegrationScheme(model)
      self.model = model;
    end
    
  end
  
end

