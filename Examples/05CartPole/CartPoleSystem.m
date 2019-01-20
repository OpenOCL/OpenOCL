classdef CartPoleSystem < OclSystem
  methods (Static)
    function setupVariables(sh)    
      
      sh.addState('p', 'lb', -5, 'ub', 5);
      sh.addState('theta', 'lb', -2*pi, 'ub', 2*pi);
      sh.addState('v');
      sh.addState('omega');

      sh.addControl('F', 'lb', -20, 'ub', 20);
    end
    function setupEquations(sh,x,~,u,~)     
      
      g = 9.8;
      cm = 1.0;
      pm = 0.1;
      phl = 0.5; % pole half length
      
      m = cm+pm;
      pml = pm*phl; % pole mass length
      
      ctheta = cos(x.theta);
      stheta = sin(x.theta);

      domega = (g*stheta + ...
                ctheta * (-u.F-pml*x.omega^2*stheta) / m) / ...
                (phl * (4.0 / 3.0 - pm * ctheta^2 / m));

      a = (u.F + pml*(x.omega^2*stheta-domega*ctheta)) / m;
      
      sh.setODE('p',x.v); 
      sh.setODE('theta',x.omega); 
      sh.setODE('v',a);
      sh.setODE('omega',domega);
    end
  end
end

