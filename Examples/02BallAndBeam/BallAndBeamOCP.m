classdef BallAndBeamOCP < OclOCP
  methods (Static)
    function pathCosts(ch,x,~,u,~,~,~)
      Q  = eye(4);
      R  = 1;
      ch.add( x.'*Q*x );
      ch.add( u.'*R*u );
    end
  end
end