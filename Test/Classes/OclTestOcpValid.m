classdef OclTestOcpValid < OclOCP
  
  methods (Static)
    
    function pathCosts(self,x,z,u,p)
      self.add(x.a); % 1
      self.add(x.c.'*x.c); % 7
      self.add(1e-3*sum(sum(u.m))+sum(sum(p.z))+sum(sum(z.t))+x.ttt+p.T); % 1e-3*12+26
      self.add(0); % 0 ([]) or () ? invalid!
      self.add(-1); % -1
    end
    
    function arrivalCosts(self,xf,p)
      self.add(xf.d);
      self.add(0);
      self.add(-1);
      self.add(-1*p.v*p.T);
    end
    
    function pathConstraints(self,x,p)
      
      % scalar with constant
      self.add(x.a,'<=',1);
      self.add(x.a,'>=',1);
      self.add(x.a,'==',1);
      self.add(1,'==',x.a);
      self.add(1,'>=',x.a);
      self.add(1,'<=',x.ttt+p.aa(1,1,1));
      
      % vector with vector
      self.add(x.f,'>=',2+ones(5,1));
      
      % scalar with scalar
      self.add(x.d,'==',x.b);
      
      % matrix 3x4 with scalar
      self.add(x.g,'<=',4);
      
      % matrix with matrix 3x4
      self.add(x.g,'<=',p.aa);
    end
    
    function boundaryConditions(self,x0,xf,p)
      self.add(x0.a,'==',xf.a);
      self.add(x0.a,'>=',xf.a*p.x);
      self.add(x0.b,'<=',xf.a+xf.a);
    end
    
    function discreteCosts(self,vars)
      self.add(sum(vars));
    end
    
  end
end