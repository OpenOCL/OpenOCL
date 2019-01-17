classdef PendulumOCP < OclOCP
  methods (Static)
    function pathCosts(self,states,algVars,controls,time,endTime,parameters)
      F  = controls.F;
      self.add( 1e-3 * F^2 );
    end
    function boundaryConditions(self,states0,statesF,parameters)
      
      l = parameters.l;
      p = states0.p;
      v = states0.v;
      
      self.add(p(1)^2+p(2)^2-l^2,'==',0);
      self.add(dot(p,v),'==',0);
    end
  end
end

