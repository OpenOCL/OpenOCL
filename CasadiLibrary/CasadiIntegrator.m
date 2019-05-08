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
      
      states = casadi.SX.sym('x',system.nx,1);
      algVars = casadi.SX.sym('z',system.nz,1);
      controls = casadi.SX.sym('u',system.nu,1);
      h = casadi.SX.sym('h',1,1);
      parameters = casadi.SX.sym('p',system.np,1);
      
      [ode,alg] = system.daefun(states,algVars,controls,parameters);

      dae = struct;
      dae.x = states;
      dae.z = algVars;
      dae.p = [h;controls;parameters];
      dae.ode = h*ode;
      dae.alg = alg;
      
      integratorOptions = struct;
      self.casadiIntegrator = casadi.integrator('integrator','idas',dae,integratorOptions);
    end
    
    function [statesNext,algVars] = evaluate(self,states,algVarsGuess,controls,timestep,parameters)
      
      integrationStep = self.casadiIntegrator('x0', states, ...
                                             'p', [timestep;controls;parameters], ...
                                             'z0', algVarsGuess);
                                           
      statesNext = full(integrationStep.xf);
      algVars = full(integrationStep.zf);
      
    end
    
  end
  
end
