classdef CasadiIntegrator < Integrator
  %CASADIINTEGRATOR Casadi Integrator
  %   
  
  properties
    systemIntegrator
  end
  
  methods
    function self = CasadiIntegrator(system)
      
      self = self@Integrator(system);
      
      states = casadi.SX.sym('x',prod(system.states.size),1);
      algVars = casadi.SX.sym('z',prod(system.algVars.size),1);
      controls = casadi.SX.sym('u',prod(system.controls.size),1);
      h = casadi.SX.sym('h',1);
      parameters = casadi.SX.sym('p',prod(system.parameters.size),1);
      
      [ode,alg] = system.systemFun.evaluate(states,algVars,controls,parameters);
      
      
      
      dae = struct;
      dae.x = system.states.value;
      dae.z = system.algVars.value;
      dae.p = [h;system.controls.value;system.parameters.value];
      dae.ode = h*ode;
      dae.alg = alg;
      
      integratorOptions = struct;
%       integratorOptions.calc_ic	= false;
%       integratorOptions.abstol = 1e-3;
%       integratorOptions.reltol = 1e-3;
%       integratorOptions.rootfinder = 'kinsol';
%       integratorOptions.number_of_finite_elements = 10;
      self.systemIntegrator = casadi.integrator('integrator','idas',dae,integratorOptions);
    end
    
    function [statesNext,algVars] = evaluate(self,states,algVarsGuess,controls,timestep,parameters)
      
      x = states;
      u = controls;
      z = algVarsGuess;
      
      integrationStep = self.systemIntegrator('x0', x, ...
                                             'p', [timestep;u;parameters], ...
                                             'z0', z);
                                           
      statesNext = integrationStep.xf;
      algVars = integrationStep.zf;
      
    end
    
  end
  
end
