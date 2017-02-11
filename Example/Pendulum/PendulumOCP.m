classdef PendulumOCP < OCP
  methods
    
    function self = PendulumOCP(system)
      self = self@OCP(system);
    end
    
    function pathCosts(self,state,algVars,controls,time,parameters)
      p  = state.get('p').value;
      l  = parameters.get('l').value;
      F  = controls.get('F').value;
      
      pe = p-[0;l];
      self.addPathCost( 1e-3 * (pe'*pe) );
      self.addPathCost( 1e-4 * F^2 );
    end
    function arrivalCosts(self,state,time,parameters)
      p  = state.get('p').value;
      l  = parameters.get('l').value;
      pe = p-[0;l];
      self.addArrivalCost(  (pe'*pe) + 1e-1*time.value );
    end
    function pathConstraints(self,state,algVars,controls,time,parameters)
    end    
    function boundaryConditions(self,state0,stateF,parameters)
      ic = self.system.getInitialCondition(state0,parameters);
      self.addBoundaryCondition(ic,'==',0);
    end
  end
end

