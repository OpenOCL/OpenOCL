classdef CartPoleSystem < OclSystem
  methods
    function setupVariables(self)    
      
      self.addState('p',1,-5,5);
      self.addState('theta',1,-2*pi,2*pi);
      self.addState('v');
      self.addState('omega');

      self.addControl('F',1,-20,20);
    end
    function setupEquation(self,x,z,u,p)     
      
      g = 9.8;
      cm = 1.0;
      pm = 0.1;
      l = 1.0;
      phl = 0.5; % pole half length
      
      m = cm+pm;
      pml = pm*phl; % pole mass length
      
      ctheta = cos(x.theta);
      stheta = sin(x.theta);

      domega = (g*stheta + ...
                ctheta * (-u.F-pml*x.omega^2*stheta) / m) / ...
                (phl * (4.0 / 3.0 - pm * ctheta^2 / m));

      a = (u.F + pml*(x.omega^2*stheta-domega*ctheta)) / m;
      
      self.setODE('p',x.v); 
      self.setODE('theta',x.omega); 
      self.setODE('v',a);
      self.setODE('omega',domega);
    end
  end
end

