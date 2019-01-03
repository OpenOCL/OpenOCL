classdef SymVariable < Variable
  % SYMVARIABLE Variable arithmetic operations for Matlab symbolic 
  % toolbox variables
  
  properties
  end
  
  methods (Static)
    
    function var = create(t,value)
      vv = sym('v',t.size());
      vv = vv(:).';
      v = OclValue(vv);
      var = Variable(type,1:length(vv),v);
      if nargin == 2
        var.set(value);
      end
    end
    
    function var = Matrix(sizeIn)
      var = SymVariable.create(OclMatrix(sizeIn));
    end
  end
  
  methods
    function self = SymVariable(type,positions,val)
      self = self@Variable(type,positions,val);
    end
    
    function v = polyval(p,a)
      if isa(p,'Variable') 
        self = p;
        p = p.value;
      end  
      if isa(a,'Variable')
        self = a;
        a = a.value;
      end
      % Use Horner's method for general case where X is an array.
      nc = length(p);
      siz_a = size(a);
      y = zeros(siz_a);
      if nc>0, y(:) = p(1); end
      for i=2:nc
        y = a .* y + p(i);
      end
      v = Variable.createMatrixLike(self,y);
    end
  end
end

