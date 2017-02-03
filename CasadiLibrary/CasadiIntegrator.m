classdef CasadiIntegrator < Integrator
  %CASADIINTEGRATOR Casadi Integrator
  %   
  
  properties
    modelIntegrator
  end
  
  methods
    function self = CasadiIntegrator(model)
      
      self = self@Integrator(model);
      
      state = casadi.SX.sym('x',prod(model.state.size),1);
      algState = casadi.SX.sym('z',prod(model.algState.size),1);
      controls = casadi.SX.sym('u',prod(model.controls.size),1);
      h = casadi.SX.sym('h',1);
      parameters = casadi.SX.sym('p',prod(model.parameters.size),1);
      
      [ode,alg] = model.modelFun.evaluate(state,algState,controls,parameters);
      
      
      
      dae = struct;
      dae.x = model.state.value;
      dae.z = model.algState.value;
      dae.p = [h;model.controls.value;model.parameters.value];
      dae.ode = h*ode;
      dae.alg = alg;
      
      integratorOptions = struct;
%       integratorOptions.calc_ic	= false;
%       integratorOptions.abstol = 1e-3;
%       integratorOptions.reltol = 1e-3;
      integratorOptions.rootfinder = 'kinsol';
%       integratorOptions.number_of_finite_elements = 10;
      self.modelIntegrator = casadi.integrator('integrator','collocation',dae,integratorOptions);
    end
    
    function [stateNext,algState] = evaluate(self,state,algStateGuess,controls,timestep,parameters)
      
      x = state;
      u = controls;
      z = algStateGuess;
      
      integrationStep = self.modelIntegrator('x0', x, ...
                                             'p', [timestep;u;parameters], ...
                                             'z0', z);
                                           
      stateNext = integrationStep.xf;
      algState = integrationStep.zf;
      
    end
    
  end
  
end
