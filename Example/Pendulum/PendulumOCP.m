classdef PendulumOCP < OCP
  methods
    
    function self = PendulumOCP(model)
      self = self@OCP(model);
    end
    
    function lagrangeTerms(self,state,algState,controls,time,parameters)
      p  = state.get('p').value;
      l  = parameters.get('l').value;
      F  = controls.get('F').value;
      
      pe = p-[0;l];
      self.addLagrangeTerm( 1e-3 * (pe'*pe) );
      self.addLagrangeTerm( 1e-4 * F^2 );
    end
    function mayerTerms(self,state,time,parameters)
      p  = state.get('p').value;
      l  = parameters.get('l').value;
      pe = p-[0;l];
      self.addMayerTerm(  (pe'*pe) + 1e-1*time.value );
    end
    function pathConstraints(self,state,algVars,controls,time,parameters)
    end    
    function boundaryConditions(self,state0,stateF,parameters)
      ic = self.model.getInitialCondition(state0,parameters);
      self.addBoundaryCondition(ic,'==',[0;0]);
    end
  end
end

