classdef CasadiIntegrator < Integrator
  %CASADIINTEGRATOR Casadi Integrator
  %   
  
  properties
    systemIntegrator
  end
  
  methods
    function self = CasadiIntegrator(system)
      
      self = self@Integrator(system);
      
      states = CasadiArithmetic(system.statesStruct);
      algVars = CasadiArithmetic(system.algVarsStruct);
      controls = CasadiArithmetic(system.controlsStruct);
      h = CasadiArithmetic(MatrixStructure([1,1]));
      parameters = CasadiArithmetic(system.parametersStruct);
      
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
                                           
      statesNext = Arithmetic(states.varStructure,full(integrationStep.xf));
      algVars = Arithmetic(algVarsGuess.varStructure,full(integrationStep.zf));
      
    end
    
  end
  
end
