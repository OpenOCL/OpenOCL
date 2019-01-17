classdef PendulumOCP < OclOCP
  methods (Static)
    function pathCosts(self,~,~,controls,~,~,~)
      F  = controls.F;
      self.add( 1e-3 * F^2 );
    end
  end
end

