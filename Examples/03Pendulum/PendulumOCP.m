classdef PendulumOCP < OclOCP
  methods (Static)
    function pathCosts(ch,~,~,controls,~,~,~)
      F  = controls.F;
      ch.add( 1e-3 * F^2 );
    end
  end
end

