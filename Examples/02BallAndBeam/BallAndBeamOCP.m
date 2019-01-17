classdef BallAndBeamOCP < OclOCP
  methods (Static)
    function pathCosts(self,x,~,u,~,~,~)
      Q  = eye(4);
      R  = 1;
      self.addPathCost( x.'*Q*x );
      self.addPathCost( u.'*R*u );
    end
  end
end