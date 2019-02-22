classdef CasadiTensor < OclTensor
  
  properties
    mx
  end
  
  methods (Static)
  
  
%     function var = createFromValue(tr,value)
%       vs = OclValueStorage.allocate(value,numel(tr));
%       vs.set(tr,value);
%       var = CasadiTensor(tr,isa(value,'casadi.MX'),vs);
%     end
    
    function var = create(tr,mx)      
      s = tr.shape;
      assert(length(s)==2 || s(3)==1);
      
      if prod(s)==0
        vv = [];
      elseif mx == true
        vv = casadi.MX.sym('v',s(1),s(2));
      else
        vv = casadi.SX.sym('v',s(1),s(2));
      end
      vs = OclValueStorage(vv);
      var = CasadiTensor(tr,mx,vs);
    end
    
    function obj = Matrix(shape,mx)
      if nargin==1
        mx = false;
      end
      r = OclMatrix(shape);
      obj = CasadiTensor.create(r,mx);
    end
  end
  
  methods
    
    function self = CasadiTensor(structure,mx,val)
      % CasadiTensor(structure,mx,val)
      narginchk(3,3);      
      self = self@OclTensor(structure,val);
      self.mx = mx;      
    end
    
    function disp(self)
      disp(self.str(self.value.str()));
    end
  end
end
