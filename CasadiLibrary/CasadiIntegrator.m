classdef CasadiIntegrator < handle
  %CASADIINTEGRATOR Casadi Integrator
  %   
  
  properties
    systemIntegrator
    system
  end
  
  methods
    function self = CasadiIntegrator(system)
      
      self.system = system;
      
      states = CasadiVariable(system.statesStruct);
      algVars = CasadiVariable(system.algVarsStruct);
      controls = CasadiVariable(system.controlsStruct);
      h = CasadiVariable(MatrixStructure([1,1]));
      parameters = CasadiVariable(system.parametersStruct);
      
      [ode,alg] = system.systemFun.evaluate(states,algVars,controls,parameters);
      
      
      
      dae = struct;
      dae.x = states.value;
      dae.z = algVars.value;
      dae.p = [h.value;controls.value;parameters.value];
      dae.ode = h.value*ode.value;
      dae.alg = alg.value;
      
      integratorOptions = struct;
%       integratorOptions.calc_ic	= false;
%       integratorOptions.abstol = 1e-3;
%       integratorOptions.reltol = 1e-3;
%       integratorOptions.rootfinder = 'kinsol';
%       integratorOptions.number_of_finite_elements = 10;
      self.systemIntegrator = casadi.integrator('integrator','idas',dae,integratorOptions);
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
                                           
      statesNext = Variable(states.varStructure,full(integrationStep.xf));
      algVars = Variable(algVarsGuess.varStructure,full(integrationStep.zf));
      
    end
    
  end
  
end
