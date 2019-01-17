classdef OclTestOcpValid < OclOCP
  
  methods (Static)
    
    function pathCosts(self,x,z,u,t,tf,p)
      self.addPathCost(x.a); % 1
      self.addPathCost(x.c.'*x.c); % 7
      self.addPathCost(1e-3*sum(sum(u.m))+sum(sum(p.z))+sum(sum(z.t))+t+tf); % 1e-3*12+26
      self.addPathCost(0); % 0 ([]) or () ? invalid!
      self.addPathCost(-1); % -1
    end
    
    function arrivalCosts(self,xf,tf,p)
      self.addArrivalCost(xf.d);
      self.addArrivalCost(0);
      self.addArrivalCost(-1);
      self.addArrivalCost(-1*p.v*tf);
    end
    
    function pathConstraints(self,x,t,p)
      
      % scalar with constant
      self.addPathConstraint(x.a,'<=',1);
      self.addPathConstraint(x.a,'>=',1);
      self.addPathConstraint(x.a,'==',1);
      self.addPathConstraint(1,'==',x.a);
      self.addPathConstraint(1,'>=',x.a);
      self.addPathConstraint(1,'<=',t+p.aa(1,1,1));
      
      % vector with vector
      self.addPathConstraint(x.f,'>=',2+ones(5,1));
      
      % scalar with scalar
      self.addPathConstraint(x.d,'==',x.b);
      
      % matrix 3x4 with scalar
      self.addPathConstraint(x.g,'<=',4);
      
      % matrix with matrix 3x4
      self.addPathConstraint(x.g,'<=',p.aa);
    end
    
    function boundaryConditions(self,x0,xf,p)
      self.addBoundaryCondition(x0.a,'==',xf.a);
      self.addBoundaryCondition(x0.a,'>=',xf.a*p.x);
      self.addBoundaryCondition(x0.b,'<=',xf.a+xf.a);
    end
    
    function discreteCosts(self,vars)
      self.addDiscreteCost(sum(vars));
    end
    
  end
end