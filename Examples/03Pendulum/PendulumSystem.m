classdef PendulumSystem < OclSystem
  methods (Static)
    function setupVariables(sys)
      sys.addState('p', 2);
      sys.addState('v', 2);
      sys.addControl('F');
      sys.addAlgVar('lambda');
      
      sys.addParameter('m');
      sys.addParameter('l');
      
    end
    function setupEquations(sys,x,z,u,p)
      
      ddp = - 1/p.m * z.lambda*x.p - [0;9.81] + [u.F;0];

      sys.setODE('p',x.v); 
      sys.setODE('v',ddp);

      % this constraints the pendulum mass to be on a circular path
      sys.setAlgEquation(dot(ddp,x.p)+x.v(1)^2+x.v(2)^2);
    end
    function initialConditions(sys,x,p)
      l = p.l;
      p = x.p;
      v = x.v;
      
      % this constraints the pendulum mass to be at distance l from the center
      % at the beginning of the simulation
      sys.add(p(1)^2+p(2)^2-l^2);
      sys.add(dot(p,v));
    end
    
    function simulationCallbackSetup(~)
      figure;
    end
    
    function simulationCallback(x,~,~,t0,t1,param)
      p = x.p.value;
      l = param.l.value;
      dt = t1-t0;
      
      plot(0,0,'ob', 'MarkerSize', 22)
      hold on
      plot([0,p(1)],[0,p(2)],'-k', 'LineWidth', 4)
      plot(p(1),p(2),'ok', 'MarkerSize', 22, 'MarkerFaceColor','r')
      xlim([-l,l])
      ylim([-l,l])
      
      pause(dt.value);
      hold off
    end
  end
end

