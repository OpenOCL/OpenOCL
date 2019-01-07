classdef PendulumSystem < OclSystem
  methods
    function setupVariables(self)
      self.addState('p',[2,1]);
      self.addState('v',[2,1]);
      self.addControl('F',[1,1]);
      self.addAlgVar('lambda',[1,1]);
      
      self.addParameter('m',[1 1]);
      self.addParameter('l',[1 1]);
      
    end
    function setupEquation(self,state,algVars,controls,parameters)
      p       = state.p;
      v       = state.v;
      F       = controls.F;
      lambda  = algVars.lambda;
      m       = parameters.m;

      ddp     = - 1/m * lambda*p - [0;9.81] + [F;0];

      self.setODE('p',v); 
      self.setODE('v',ddp);

      % this constraints the pendulum mass to be on a circular path
      self.setAlgEquation(dot(ddp,p)+v(1)^2+v(2)^2);
    end
    function initialCondition(self,state,parameters)
      l = parameters.l;
      p = state.p;
      v = state.v;
      
      % this constraints the pendulum mass to be at distance l from the center
      % at the beginning of the simulation
      self.setInitialCondition(p(1)^2+p(2)^2-l^2);
      self.setInitialCondition(dot(p,v));
    end
    
    function simulationCallbackSetup(~)
      figure;
    end
    
    function simulationCallback(self,states,algVars,controls,t0,t1,parameters)
      p = states.p.value;
      l = parameters.l.value;
      dt = t1-t0;
      
      plot(0,0,'ob', 'MarkerSize', 22)
      hold on
      plot([0,p(1)],[0,p(2)],'-k', 'LineWidth', 4)
      plot(p(1),p(2),'ok', 'MarkerSize', 22, 'MarkerFaceColor','r')
      xlim([-l,l])
      ylim([-l,l])
      
      pause(dt);
      hold off
    end
  end
end

