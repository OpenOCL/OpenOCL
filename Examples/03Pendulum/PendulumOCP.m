classdef PendulumOCP < OCP
  methods
    
    function self = PendulumOCP(system)
      self = self@OCP(system);
    end
    
    function pathCosts(self,states,algVars,controls,time,endTime,parameters)
      F  = controls.F;
      self.addPathCost( 1e-3 * F^2 );
    end
    function arrivalCosts(self,states,endTime,parameters)

    end
    function pathConstraints(self,states,algVars,controls,time,parameters)
    end    
    function boundaryConditions(self,states0,statesF,parameters)
      ic = self.system.getInitialCondition(states0,parameters);
      self.addBoundaryCondition(ic,'==',0);
    end
  end
end

