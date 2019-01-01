classdef CasadiIntegrator < handle
  %CASADIINTEGRATOR Casadi Integrator
  %   
  
  properties
    casadiIntegrator
    system
  end
  
  methods
    function self = CasadiIntegrator(system)
      
      self.system = system;
      
      states = CasadiVariable(system.statesStruct);
      algVars = CasadiVariable(system.algVarsStruct);
      controls = CasadiVariable(system.controlsStruct);
      h = CasadiVariable(OclMatrix([1,1]));
      parameters = CasadiVariable(system.parametersStruct);
      
      [ode,alg] = system.systemFun.evaluate(states,algVars,controls,parameters);
      
      
      
      dae = struct;
      dae.x = states.value;
      dae.z = algVars.value;
      dae.p = [h.value;controls.value;parameters.value];
      dae.ode = h.value*ode.value;
      dae.alg = alg.value;
      
      integratorOptions = struct;
      self.casadiIntegrator = casadi.integrator('integrator','idas',dae,integratorOptions);
    end
    
    function [statesNext,algVars] = evaluate(self,states,algVarsGuess,controls,timestep,parameters)
      
      x = states.value;
      u = controls.value;
      z = algVarsGuess.value;
      p = parameters.value;
      dt = timestep.value;
      
      integrationStep = self.systemIntegrator('x0', x, ...
                                             'p', [dt;u;p], ...
                                             'z0', z);
                                           
      statesNext = Variable(states,full(integrationStep.xf));
      algVars = Variable(algVarsGuess,full(integrationStep.zf));
      
    end
    
  end
  
end
