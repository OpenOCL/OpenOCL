classdef CasadiVariable < Variable
  
  properties
    mx
  end
  
  methods (Static)
  
  
    function var = createFromValue(type,value)
      oclValue = OclValue(value);
      [N,M,K] = size(type);
      p = reshape(1:N*M*K,N,M,K);
      var = CasadiVariable(type,p,isa(value,'casadi.MX'),oclValue);
    end
    
    function var = create(structure,mx)
      if isa(structure,'OclTensor') && ~isempty(structure.children)
        names = fieldnames(structure.children);
        id = [names{:}];
      else
        id = class(structure);
      end
      
      [N,M,K] = structure.size();
      assert(K==1,'Not supported.');
      if N*M*K==0
        vv = [];
      elseif mx == true
        vv = casadi.MX.sym(id,N,M);
      else
        vv = casadi.SX.sym(id,N,M);
      end
      val = OclValue(vv);
      indizes = {1:N*M*K};
      shapes = {[N,M,K]};
      t = OclTensorChild(structure,indizes,shapes);
      var = CasadiVariable(t,mx,val);
    end
    
    function obj = Matrix(shape,mx)
      if nargin==1
        mx = false;
      end
      structure = OclTensorTreeBuilder();
      structure.add('m',shape);
      obj = CasadiVariable.create(structure,mx);
    end
  end
  
  methods
    
    function self = CasadiVariable(type,mx,val)
      % CasadiVariable(type,positions,mx,val)
      narginchk(3,3);      
      self = self@Variable(type,val);
      self.mx = mx;      
    end
    
    function r = disp(self)
      disp(self.str(self.value.str()));
    end
  end
end
