classdef ImplicitIntegrationScheme < handle
  
  properties(Access = protected)
    system
  end
  
  methods(Abstract)
    var = getIntegratorVars(self)
    ni = getIntegratorVarsSize(self)
    [finalStates, finalAlgVars, costs, equations] = getIntegrator(self,states,integratorVars,controls,startTime,finalTime,parameters)
  end
  
  methods
    
    function self = ImplicitIntegrationScheme(system)
      self.system = system;
    end
    
  end
  
end

