classdef CasadiVariable < Variable
  
  properties
    mx
  end
  
  methods (Static)
    
    function obj = Matrix(sizeIn)
      obj = CasadiVariable(OclMatrix(sizeIn),1:prod(sizeIn),false);
    end
    
  end
  
  methods
    
    function self = CasadiVariable(type,pos,mx,val)
      % CasadiVariable(type,pos,mx)
      narginchk(3,4);
      
      if isa(type,'OclTree')
        id = [fieldnames(type.children){:}];
      else
        id = class(type);
      end
      
      if nargin == 3 && mx
        val = Value(casadi.MX.sym(id,1,prod(type.size)));
      elseif nargin == 3
        val = Value(casadi.SX.sym(id,1,prod(type.size)));
      end
      
      
      self = self@Variable(type,pos,val);
      self.mx = mx;
    end
  end
end
