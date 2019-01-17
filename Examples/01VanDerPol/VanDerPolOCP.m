classdef VanDerPolOCP < OclOCP
  % An OCP is defined by inheriting from the OCP class.
  
  methods
    function pathCosts(self,states,algVars,controls,time,endTime,parameters)
      % Define lagrange (intermediate) cost terms.
      self.addPathCost( states.x^2 );
      self.addPathCost( states.y^2 );
      self.addPathCost( controls.u^2 );
    end
    function arrivalCosts(self,states,endTime,parameters)
      % Define terminal cost terms.
    end
    function pathConstraints(self,states,time,parameters)
      % Define non-linear path constraints on variables.
    end    
    function boundaryConditions(self,states0,statesF,parameters)
      % Define non-linear terminal constraints.
    end
    function iterationCallback(self,variables)
      % callback for drawing intermediate solutions
      times = 0:10/30:10;
      hold off
      plot(times,variables.states.x.value,'-.')
      hold on
      plot(times,variables.states.y.value,'--k')
      stairs(times(1:end-1),variables.controls.u.value,'r')
      xlabel('time')
      legend({'x','y','u'})
      drawnow;
    end
    
  end
  
end

