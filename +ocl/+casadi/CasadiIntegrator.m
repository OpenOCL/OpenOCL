% Copyright 2019 Jonas Koenemann, Moritz Diehl, University of Freiburg
% Redistribution is permitted under the 3-Clause BSD License terms. Please
% ensure the above copyright notice is visible in any derived work.
%
classdef CasadiIntegrator < handle
  %CASADIINTEGRATOR Casadi Integrator
  %   
  
  properties
    casadiIntegrator
  end
  
  methods
    function self = CasadiIntegrator(nx, nz, nu, np, daefun)
      
      states = casadi.SX.sym('x', nx);
      algVars = casadi.SX.sym('z', nz);
      controls = casadi.SX.sym('u', nu);
      h = casadi.SX.sym('h');
      parameters = casadi.SX.sym('p', np);
      
      [ode,alg] = daefun(states,algVars,controls,parameters);

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
