classdef ImplicitIntegrationScheme < handle
  
  properties(Access = protected)
    system
  end
  
  methods(Abstract)
    var = getIntegratorVars(self)
    ni = getIntegratorVarsSize(self)
    [finalState, finalAlgVars, costs, equations] = evaluate(self,state,integratorVars,controls,startTime,finalTime,parameters)
  end
  
  methods
    
    function self = ImplicitIntegrationScheme(system)
      self.system = system;
    end
    
  end
  
end

