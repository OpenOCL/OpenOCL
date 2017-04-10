classdef PendulumOCP < OCP
  methods
    
    function self = PendulumOCP(system)
      self = self@OCP(system);
    end
    
    function pathCosts(self,states,algVars,controls,time,parameters)
      p  = states.get('p').value;
      l  = parameters.get('l').value;
      F  = controls.get('F').value;
      
      pe = p-[0;l];
      self.addPathCost( 1e-3 * (pe'*pe) );
      self.addPathCost( 1e-4 * F^2 );
    end
    function arrivalCosts(self,states,time,parameters)
      p  = states.get('p').value;
      l  = parameters.get('l').value;
      pe = p-[0;l];
      self.addArrivalCost(  (pe'*pe) + 1e-1*time.value );
    end
    function pathConstraints(self,states,algVars,controls,time,parameters)
    end    
    function boundaryConditions(self,states0,statesF,parameters)
      ic = self.system.getInitialCondition(states0,parameters);
      self.addBoundaryCondition(ic,'==',0);
    end
  end
end

