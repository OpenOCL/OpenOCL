classdef CasadiIntegrator < Integrator
  %CASADIINTEGRATOR Casadi Integrator
  %   
  
  properties
    systemIntegrator
  end
  
  methods
    function self = CasadiIntegrator(system)
      
      self = self@Integrator(system);
      
      state = casadi.SX.sym('x',prod(system.state.size),1);
      algVars = casadi.SX.sym('z',prod(system.algVars.size),1);
      controls = casadi.SX.sym('u',prod(system.controls.size),1);
      h = casadi.SX.sym('h',1);
      parameters = casadi.SX.sym('p',prod(system.parameters.size),1);
      
      [ode,alg] = system.systemFun.evaluate(state,algVars,controls,parameters);
      
      
      
      dae = struct;
      dae.x = system.state.value;
      dae.z = system.algVars.value;
      dae.p = [h;system.controls.value;system.parameters.value];
      dae.ode = h*ode;
      dae.alg = alg;
      
      integratorOptions = struct;
%       integratorOptions.calc_ic	= false;
%       integratorOptions.abstol = 1e-3;
%       integratorOptions.reltol = 1e-3;
      integratorOptions.rootfinder = 'kinsol';
%       integratorOptions.number_of_finite_elements = 10;
      self.systemIntegrator = casadi.integrator('integrator','collocation',dae,integratorOptions);
    end
    
    function [stateNext,algVars] = evaluate(self,state,algVarsGuess,controls,timestep,parameters)
      
      x = state;
      u = controls;
      z = algVarsGuess;
      
      integrationStep = self.systemIntegrator('x0', x, ...
                                             'p', [timestep;u;parameters], ...
                                             'z0', z);
                                           
      stateNext = integrationStep.xf;
      algVars = integrationStep.zf;
      
    end
    
  end
  
end
