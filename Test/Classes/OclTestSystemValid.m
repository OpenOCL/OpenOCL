classdef OclTestSystemValid < OclSystem
  methods
    function setupVariables(self)
      self.addState('a');
      self.addState('b',1);
      self.addState('c',7);
      self.addState('d',[1,1]);
      self.addState('e',[1,4]);
      self.addState('f',[5,1]);
      self.addState('g',[3,4]);
      
      self.addControl('a'); % same as state!? (conflict bounds in Simultaneous)
      self.addControl('h',1);
      self.addControl('i',7);
      self.addControl('j',[1,1]);
      self.addControl('k',[1,4]);
      self.addControl('l',[5,1]);
      self.addControl('m',[3,4]);
      
      self.addAlgVar('n');
      self.addAlgVar('o',1);
      self.addAlgVar('p',7);
      self.addAlgVar('q',[1,1]);
      self.addAlgVar('r',[1,4]);
      self.addAlgVar('s',[5,1]);
      self.addAlgVar('t',[3,4]);
      
      self.addParameter('u');
      self.addParameter('v',1);
      self.addParameter('w',7);
      self.addParameter('x',[1,1]);
      self.addParameter('y',[1,4]);
      self.addParameter('z',[5,1]);
      self.addParameter('aa',[3,4]);
    end
    function setupEquation(self,x,z,u,p)
      
      self.setODE('g',p.aa+z.t);
      self.setODE('b',z.n);
      self.setODE('a',p.u);
      self.setODE('d',x.a+x.b*z.o+p.u*p.x);
      self.setODE('c',z.p);
      self.setODE('f',z.s);
      self.setODE('e',u.k);

      % 31x1
      self.setAlgEquation(reshape(p.y,4,1));
      self.setAlgEquation(reshape(z.t,12,1));
      self.setAlgEquation(reshape(x.g,12,1)+[u.a,u.h,u.j,4,5,6,z.n,z.q,p.u,10,11,12].');
      self.setAlgEquation(p.y(:,1:3,:));
    end
  end
end