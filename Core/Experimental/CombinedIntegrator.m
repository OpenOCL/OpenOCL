classdef CombinedIntegrator < Integrator
  %INTEGRATOR Integrator class
  %   Is able to integrate model
  
  properties(Access = private)
    integrationScheme
    solver
  end
  
  
  methods
    
    function self = CombinedIntegrator(model,integrationScheme,solver)
      self = self@Integrator(model);

      self.integrationScheme = integrationScheme;
      self.solver = solver;
    end

    function [finalState, finalAlgVars, costs] = evaluate(self,state,controls,startTime,finalTime,parameters)
    
      [finalState, finalAlgVars, costs, equations] = self.integrationScheme.evaluate(self,state,integratorVars,controls,startTime,finalTime,parameters);

    end

  end
  
end

