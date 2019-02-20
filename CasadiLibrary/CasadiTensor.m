classdef CasadiTensor < OclTensor
  
  properties
    mx
  end
  
  methods (Static)
  
  
    function var = createFromValue(tr,value)
      vs = OclValueStorage(value);
      var = CasadiTensor(tr,isa(value,'casadi.MX'),vs);
      vs.set(value);
    end
    
    function var = create(tensorRoot,mx)
      if isa(tensorRoot.structure,'OclTreeTensor') && ~isempty(tensorRoot.structure.children)
        names = fieldnames(tensorRoot.children);
        id = [names{:}];
      else
        id = class(tensorRoot);
      end
      
      s = tensorRoot.shape;
      assert(length(s)==2 || s(3)==1);
      if prod(s)==0
        vv = [];
      elseif mx == true
        vv = casadi.MX.sym(id,s(1),s(2));
      else
        vv = casadi.SX.sym(id,s(1),s(2));
      end
      vs = OclValueStorage(vv);
      indizes = {1:prod(s)};
      shapes = {[s(1),s(2)],1};
      t = OclTensorRoot(tensorRoot,indizes,shapes);
      var = CasadiTensor(t,mx,vs);
    end
    
    function obj = Matrix(shape,mx)
      if nargin==1
        mx = false;
      end
      r = OclTensorRoot([],{1:prod(shape)},{shape,1});
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
    
    function r = disp(self)
      disp(self.str(self.value.str()));
    end
  end
end
